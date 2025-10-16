output "logs_bucket_name" {
  value       = aws_s3_bucket.logs.bucket
  description = "Name of the S3 bucket that holds VPC Flow Logs and DNS query logs"
}

output "logs_bucket_arn" {
  value       = aws_s3_bucket.logs.arn
  description = "ARN of the logs bucket"
}

output "flow_log_ids" {
  value       = { for k, v in aws_flow_log.vpc : k => v.id }
  description = "Map of VPC IDs to their corresponding Flow Log resource IDs"
}

output "resolver_query_log_config_id" {
  value       = var.enable_traffic_sampling ? aws_route53_resolver_query_log_config.dns[0].id : null
  description = "Resolver query logging configuration id (null when logging is disabled)"
}

output "resolver_query_log_config_association_ids" {
  value       = var.enable_traffic_sampling ? { for k, v in aws_route53_resolver_query_log_config_association.dns_assoc : k => v.id } : {}
  description = "Map of VPC IDs to their corresponding Resolver query log config association IDs (empty when logging is disabled)"
}
