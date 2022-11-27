# terraform-aws-module-aws-backup

- AWS Backup를 생성하는 공통 모듈

## Usage

### `terraform.tfvars`

- 모든 변수는 적절하게 변경하여 사용

```plaintext
account_id = "01234567" # 아이디 변경 필수
region     = "ap-northeast-2"
prefix     = "prod"

backup_name   = "kcl-gitlab" # backup_name 변수를 통해 vault, plan, rule 이름 생성, ${var.prefix}-${var.backup_name}-backup-(vault|plan|rule)
kms_key_name  = "kcl-gitlab-backup-vault-kms-key"

schedule  = "cron(0 18 * * ? *)" # 분 시 일 월 요 년, UTC이기 때문에 +9 해야 함

# 지속적 백업 활성화 (true 일경우 lifcycle 콜드 스토리지 전환 불가)
enable_continuous_backup = false

start_window      = 60   # Start within, 분 단위
completion_window = 1440 # Complete within, 분 단위

# 콜드 스토리지로 이동되는 시점(단위: 일), 0: NEVER
cold_storage_after = 0

# 백업 보관 기간(단위: 일)
# cold_storage_after 를 지정할 경우 최소 +90일 필요
delete_after = 30

# EC2 의 경우 Name tag 필요
ec2_backup_iam_role_name = "AWSBackupDefaultServiceRole"
ec2_resource_filters = {
  "Name" = [ 
    "kcl-2a-01-ec2",
  ]
}

rds_backup_iam_role_name = "AWSBackupDefaultServiceRole"
rds_resource_filters = [
  "kcl-common-postgres"
]

s3_backup_iam_role_name = "AWSBackupS3Role"
s3_resource_filters = [
  "kcl-gitlab-terraform-state-s3",
]

tags = {
  "CreatedByTerraform"     = "true"
  "TerraformModuleName"    = "terraform-aws-module-aws-backup"
  "TerraformModuleVersion" = "v1.0.0"
}

# Advanced Backup setting
backup_options  = {
  WindowsVSS = "disabled" #enabled/disabled
}

resource_type = "EC2"
```

------

### `main.tf`

```plaintext
module "aws_backup" {
  source = "git::https://github.com/aws-module-aws-backup.git?ref=v1.0.0"

  current_id     = data.aws_caller_identity.current.account_id
  current_region = data.aws_region.current.name
  
  account_id = var.account_id
  region     = var.region
  prefix     = var.prefix
  
  backup_name               = var.backup_name
  kms_key_arn               = data.aws_kms_key.this.arn
  schedule                  = var.schedule
  enable_continuous_backup  = var.enable_continuous_backup
  start_window              = var.start_window
  completion_window         = var.completion_window
  cold_storage_after        = var.cold_storage_after
  delete_after              = var.delete_after
  
  ec2_backup_iam_role_arn = data.aws_iam_role.ec2.arn
  ec2_resources           = data.aws_instances.this.ids
  
  rds_backup_iam_role_arn = data.aws_iam_role.rds.arn
  rds_resources           = data.aws_db_instance.this.*.db_instance_arn
  
  s3_backup_iam_role_arn = data.aws_iam_role.s3.arn
  s3_resources           = data.aws_s3_bucket.this.*.arn

  # Advanced Backup setting
  backup_options = var.backup_options
  resource_type  = var.resource_type

  tags = var.tags
}
```

------

### `provider.tf`

```plaintext
provider "aws" {
 region = var.region
}

```

------

### `terraform.tf`

```plaintext
terraform {
  required_version = ">= 1.1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.74"
    }
  }

  backend "s3" {
    bucket         = "kcl-terraform-state-backend"
    key            = "01234567/common/backup/terraform.state"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

------

### `data.tf`

```plaintext
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_kms_key" "this" {
  key_id = format("alias/%s", var.kms_key_name)
}

data "aws_iam_role" "ec2" {
  name = var.ec2_backup_iam_role_name
}

data "aws_iam_role" "rds" {
  name = var.rds_backup_iam_role_name
}

data "aws_iam_role" "s3" {
  name = var.s3_backup_iam_role_name
}

data "aws_instance" "this" {
  dynamic "filter" {
    for_each = var.ec2_resource_filters
    iterator = tag
    content {
      name = "tag:${tag.key}"
      values = "${tag.value}"
    }
  }
}

data "aws_db_instance" "this" {
  count                  = length(var.rds_resource_filters)
  db_instance_identifier = var.rds_resource_filters[count.index]
}

data "aws_s3_bucket" "this" {
  count  = length(var.s3_resource_filters)
  bucket = var.s3_resource_filters[count.index]
}
```

------

### `variables.tf`

```plaintext
variable "account_id" {
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

variable "kms_key_name" {
  type = string
}

variable "ec2_backup_iam_role_name" {
  type = string
}

variable "rds_backup_iam_role_name" {
  type = string
}

variable "s3_backup_iam_role_name" {
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
  type = number
}

variable "completion_window" {
  type = number
}

variable "cold_storage_after" {
  type = number
}

variable "delete_after" {
  type = number
}

variable "backup_options" {
  type    = map(string)
  default = {}
}

variable "resource_type" {
  type = string
}

variable "ec2_resource_filters" {
  type = map(any)
}

variable "rds_resource_filters" {
  type = list
}

variable "s3_resource_filters" {
  type = list
}

variable "tags" {
  type = map(string)
}
```

------

### `outputs.tf`

```plaintext
output "result" {
  value = module.aws_backup
}
```

## 실행방법

```plaintext
terraform init -get=true -upgrade -reconfigure
terraform validate (option)
terraform plan -var-file=terraform.tfvars -refresh=false -out=planfile
terraform apply planfile
```

- "Objects have changed outside of Terraform" 때문에 `-refresh=false`를 사용
- 실제 UI에서 리소스 변경이 없어보이는 것과 low-level Terraform에서 Object 변경을 감지하는 것에 차이가 있는 것 같음, 다음 링크 참고
  - https://github.com/hashicorp/terraform/issues/28776
- 위 이슈로 변경을 감지하고 리소스를 삭제하는 케이스가 발생 할 수 있음