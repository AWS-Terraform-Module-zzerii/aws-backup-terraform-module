variable "account_id" {
  description = "Allowed AWS account IDs"
  type        = string
}

variable "current_region" {
  type = string
}

variable "current_id" {
  type = string
}

variable "region" {
  type = string
}

variable "prefix" {
  type = string
}

variable "backup_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "ec2_backup_iam_role_arn" {
  type = string
}

variable "rds_backup_iam_role_arn" {
  type = string
}

variable "s3_backup_iam_role_arn" {
  type = string
}

variable "schedule" {
  type = string
}

variable "enable_continuous_backup" {
  type    = bool
  default = false
}

variable "start_window" {
  type    = number
  default = null
}

variable "completion_window" {
  type    = number
  default = null
}

variable "cold_storage_after" {
  type = number
}

variable "delete_after" {
  type = number
}

variable "backup_options" {
  type = map(string)
}

variable "resource_type" {
  type = string
}

variable "ec2_resources" {
  type = list
}

variable "rds_resources" {
  type = list
}

variable "s3_resources" {
  type = list
}

variable "tags" {
  type = map(string)
}