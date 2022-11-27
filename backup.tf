resource "null_resource" "validate_account" {
  count = var.current_id == var.account_id ? 0 : "Please check that you are using the AWS account"
}

resource "null_resource" "validate_module_name" {
  count = local.module_name == var.tags["TerraformModuleName"] ? 0 : "Please check that you are using the Terraform module"
}

resource "null_resource" "validate_module_version" {
  count = local.module_version == var.tags["TerraformModuleVersion"] ? 0 : "Please check that you are using the Terraform module"
}

resource "aws_backup_vault" "this" {
  name        = "${var.prefix}-${var.backup_name}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(var.tags, tomap({Name = format("%s-%s-backup-vault", var.prefix, var.backup_name)}))
}

resource "aws_backup_plan" "this" {

  name = "${var.prefix}-${var.backup_name}-backup-plan"

  rule {
    rule_name = "${var.prefix}-${var.backup_name}-backup-rule"

    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule

    enable_continuous_backup = var.enable_continuous_backup

    start_window      = var.start_window
    completion_window = var.completion_window

    lifecycle {
      cold_storage_after = var.cold_storage_after
      delete_after       = var.delete_after
    }
  }

  advanced_backup_setting {
    backup_options = var.backup_options
    resource_type  = var.resource_type
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-backup-plan", var.prefix, var.backup_name)}))
}

resource "aws_backup_selection" "ec2" {
  count        = length(var.ec2_resources) > 0 ? 1 : 0
  iam_role_arn = var.ec2_backup_iam_role_arn
  name         = "${var.prefix}-${var.backup_name}-backup-ec2-selection"
  plan_id      = aws_backup_plan.this.id
  resources    = formatlist("arn:aws:ec2:${var.region}:${var.account_id}:instance/%s", var.ec2_resources)
}

resource "aws_backup_selection" "rds" {
  count        = length(var.rds_resources) > 0 ? 1 : 0
  iam_role_arn = var.rds_backup_iam_role_arn
  name         = "${var.prefix}-${var.backup_name}-backup-rds-selection"
  plan_id      = aws_backup_plan.this.id
  resources    = var.rds_resources
}

resource "aws_backup_selection" "s3" {
  count        = length(var.s3_resources) > 0 ? 1 : 0
  iam_role_arn = var.s3_backup_iam_role_arn
  name         = "${var.prefix}-${var.backup_name}-backup-s3-selection"
  plan_id      = aws_backup_plan.this.id
  resources    = var.s3_resources
}