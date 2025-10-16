# VPC Traffic Sampling Module

## Purpose

This module **allows Stackadilly to analyze your VPC traffic** by:

- Creating a new S3 bucket
- Collecting VPC Flow Logs from all specified VPCs to bucket
- Enabling Route 53 Resolver DNS query logging to bucket
- Providing Stackadilly read access to bucket

## Usage

This module is intended to be turned on for e.g. 24 hours at a time to sample traffic. Use `enable_traffic_sampling` to toggle logging on/off. **Be sure to turn off to save money.**

### Basic Example

```hcl
module "vpc_traffic_sampling" {
  source  = "stackadilly/vpc-traffic-sampling/aws"
  version = "1.0.0"
  enable_traffic_sampling = true
  vpc_ids = ["vpc-12345678"]
}
```
