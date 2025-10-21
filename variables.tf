variable "enable_dns_sampling" {
  description = "Enable Route 53 Resolver query logging. Turn this on first."
  type        = bool
}

variable "enable_flow_sampling" {
  description = "Enable VPC Flow Logs. Can be turned on along with dns logging, but to mimimize costs, turn this on after DNS sampling has run for at least a day."
  type        = bool
}

variable "vpc_ids" {
  description = "List of VPC IDs to collect Flow Logs from and to associate DNS query logging with"
  type        = list(string)
}

variable "s3_retention_days" {
  description = "Retention on the logs bucket"
  type        = number
  default     = 14
}

variable "flow_log_format" {
  description = "Custom VPC Flow Log record format fields"
  type        = list(string)
  default = [
    "$${account-id}",
    "$${region}",
    "$${vpc-id}",
    "$${az-id}",
    "$${subnet-id}",
    "$${instance-id}",
    "$${interface-id}",
    "$${srcaddr}",
    "$${dstaddr}",
    "$${srcport}",
    "$${dstport}",
    "$${pkt-srcaddr}",
    "$${pkt-dstaddr}",
    "$${action}",
    "$${bytes}",
    "$${start}",
    "$${end}",
    "$${traffic-path}",
    "$${flow-direction}"
  ]
}

variable "iam_role_name" {
  description = "Existing IAM role to which we attach an S3 read policy (scoped to this bucket/prefixes) for cross-account Athena"
  type        = string
  default     = "Stackadilly"
}

variable "name_prefix" {
  description = "Prefix for all created resources"
  type        = string
  default     = "stackadilly"
}

variable "tags" {
  type    = map(string)
  default = {}
}
