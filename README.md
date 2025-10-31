# VPC Traffic Sampling Module

## Purpose

This module **allows Stackadilly to analyze your VPC traffic**. It will:

- Create a new S3 bucket
- Collect VPC Flow Logs from all specified VPCs to bucket
- Collect Route53 DNS resolver queries from all specified VPCs to bucket
- Provide Stackadilly read access to bucket

## Usage

1. Obtain a role ARN from Stackadilly and set as `cross_account_role_arn`.
2. Set all VPC IDs that you wish to sample traffic for.
3. Turn on `enable_dns_sampling` to start logging from the DNS query resolver. Due to DNS caching, this should be on for a minimum of 24h before flow IPs will accurately map to domain names.
4. After sampling DNS for at least a day, additionally turn on `enable_flow_sampling` for a window that will gather a representative sample of traffic. For most teams, 24 hours is enough, but if you have traffic-heavy jobs that run weekly or monthly, consider capturing during those windows as well.
5. **Be sure to turn both flags off once done sampling to save money.**

### Basic Example

```hcl
module "vpc_traffic_sampling" {
  source                 = "Stackadilly/vpc-traffic-sampling/aws"
  version                = "2.1.0"
  cross_account_role_arn = "arn:aws:iam::1111222233334444:role/stackadilly-AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" # provided by Stackadilly
  enable_dns_sampling    = true
  enable_flow_sampling   = true
  vpc_ids                = ["vpc-12345678"]
}
```

### Notes

- Cross-account access for reading logs is granted to the specified `cross_account_role_arn` using an S3 bucket policy. Stackadilly will assume this role in their own account to run Athena and read from your bucket
