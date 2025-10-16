variable "enable_traffic_sampling" {
  description = "Master switch for both VPC Flow Logs and DNS Resolver query logging. If false, logging is disabled."
  type        = bool
}

variable "vpc_ids" {
  description = "List of VPC IDs to collect Flow Logs from (and to associate DNS query logging with)"
  type        = list(string)
}

variable "s3_retention_days" {
  description = "Retention on the logs bucket"
  type        = number
  default     = 14
}

variable "flow_log_format" {
  description = "Lean custom VPC Flow Log record format"
  type        = string
  default     = "$${account-id} $${vpc-id} $${instance-id} $${interface-id} $${srcaddr} $${dstaddr} $${pkt-srcaddr} $${pkt-dstaddr} $${dstport} $${action} $${bytes} $${start} $${end}"
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
