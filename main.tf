terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name        = "${var.name_prefix}-vpc-traffic-sampling-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  bucket_arn         = "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}"
  log_prefix_arn     = "${local.bucket_arn}/AWSLogs/*"
  flow_log_format    = join(" ", var.flow_log_format)
}

resource "aws_s3_bucket" "logs" {
  bucket = local.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration { days = var.s3_retention_days }
    filter {}
  }
}

# -----------------------------
# Bucket policy:
#  - Allow VPC Flow Logs service to write
#  - Allow Route 53 Resolver to write
#  - Note: source account condition bc flow logs is a cross-account resource
# -----------------------------
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowVPCAgentToPutFlowLogs",
        Effect : "Allow",
        Principal : {
          Service : "delivery.logs.amazonaws.com"
        },
        Action : ["s3:PutObject"],
        Resource : local.log_prefix_arn,
        Condition : {
          StringEquals : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid : "AllowVPCAgentToCheckACL",
        Effect : "Allow",
        Principal : {
          Service : "delivery.logs.amazonaws.com"
        },
        Action : ["s3:GetBucketAcl"],
        Resource : aws_s3_bucket.logs.arn,
        Condition : {
          StringEquals : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid : "AllowRoute53ResolverToPutDNSLogs",
        Effect : "Allow",
        Principal : {
          Service : "route53.amazonaws.com"
        },
        Action : ["s3:PutObject", "s3:AbortMultipartUpload"],
        Resource : local.log_prefix_arn
      }
    ]
  })
}

# -----------------------------
# VPC Flow Logs -> S3 (Parquet + hive prefixes + hourly)
# Flow logs are stored under /AWSLogs/aws-account-id={account-id}/aws-service=vpcflowlogs/aws-region={region}/
# -----------------------------
resource "aws_flow_log" "vpc" {
  for_each                 = var.enable_flow_sampling ? toset(var.vpc_ids) : toset([])
  log_destination_type     = "s3"
  log_destination          = aws_s3_bucket.logs.arn
  traffic_type             = "ALL"
  vpc_id                   = each.value
  log_format               = local.flow_log_format
  max_aggregation_interval = 600

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-flow-logs-${each.value}"
  })
}

# -----------------------------
# Route 53 Resolver DNS query logging -> S3
# Resolver logs are stored under /AWSLogs/{account-id}/{region}/vpcdnsquerylogs/{vpc-id}/
# -----------------------------
resource "aws_route53_resolver_query_log_config" "dns" {
  count           = var.enable_dns_sampling ? 1 : 0
  name            = "${var.name_prefix}-dns-query-logs"
  destination_arn = aws_s3_bucket.logs.arn
  tags            = var.tags
}

resource "aws_route53_resolver_query_log_config_association" "dns_assoc" {
  for_each                     = var.enable_dns_sampling ? toset(var.vpc_ids) : toset([])
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.dns[0].id
  resource_id                  = each.value
}

# -----------------------------
# IAM: attach an S3 read policy (scoped to this bucket) to an existing role
# -----------------------------
resource "aws_iam_policy" "bucket_read" {
  name = "${var.name_prefix}-traffic-analysis-read"
  path = "/"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "ListBucketScopedPrefixes",
        Effect : "Allow",
        Action : ["s3:ListBucket"],
        Resource : aws_s3_bucket.logs.arn,
        Condition : {
          StringLike : {
            "s3:prefix" : "AWSLogs/*"
          }
        }
      },
      {
        Sid : "ReadObjectsInPrefixes",
        Effect : "Allow",
        Action : ["s3:GetObject", "s3:GetObjectVersion"],
        Resource : local.log_prefix_arn
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_bucket_read" {
  role       = var.iam_role_name
  policy_arn = aws_iam_policy.bucket_read.arn
}
