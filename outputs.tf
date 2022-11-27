output "region" {
  value = var.region
}

output "account_id" {
  value = var.account_id
}

output "aws_backup_vault" {
  value = aws_backup_vault.this
}

output "aws_backup_plan" {
  value = aws_backup_plan.this
}

output "aws_backup_selection_ec2" {
  value = length(aws_backup_selection.ec2) > 0 ? aws_backup_selection.ec2 : null
}

output "aws_backup_selection_rds" {
  value = length(aws_backup_selection.rds) > 0 ? aws_backup_selection.rds : null
}

output "aws_backup_selection_s3" {
  value = length(aws_backup_selection.s3) > 0 ? aws_backup_selection.s3 : null
}