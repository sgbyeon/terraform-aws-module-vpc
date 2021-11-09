# AWS VPC Terraform custom module
* AWS 에서 VPC 리소스를 생성하는 커스텀 모듈
* subnet을 생성 시 map of map 방식을 사용

## Usage

### `terraform.tfvars`
* 모든 변수는 적절하게 변경하여 사용
```
account_id = "123456789012" # 아이디 변경 필수
region = "ap-northeast-2"
prefix = "bsg"
vpc_name = "test-vpc" # 최종 VPC 이름: bsg-test-vpc
vpc_cidr = "10.10.0.0/16" # 적절하게 변경
vpc_secondary_cidr = "" # 필요 시 입력
azs = ["ap-northeast-2a", "ap-northeast-2c"]

tags = {
    "CreatedByTerraform" = "true"
}

nat_gateway_subnets = ["10.10.0.0/24", "10.10.10.0/24"]

subnets = {
  "bastion" = {
    "cidr" = ["10.10.0.0/24", "10.10.10.0/24"]
    "ipv4_type" = ["public"]
    "ngw_attach" = ["disable"]
  },
  "web" = {
    "cidr" = ["10.10.20.0/24", "10.10.30.0/24"]
    "ipv4_type" = ["private"]
    "ngw_attach" = ["disable"]
  },
  "was" = {
    "cidr" = ["10.10.40.0/24", "10.10.50.0/24"]
    "ipv4_type" = ["private"]
    "ngw_attach" = ["disable"]
  },
  "rds" = {
    "cidr" = ["10.10.60.0/24", "10.10.60.0/24"]
    "ipv4_type" = ["private"]
    "ngw_attach" = ["disable"]
  }
}
```
---

### `main.tf`
```
module "vpc" {
  source = "git::https://github.com/sgbyeon/terraform-aws-module-vpc.git"
  prefix = var.prefix
  region = var.region
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  vpc_secondary_cidr = var.vpc_secondary_cidr
  azs = var.azs
  nat_gateway_subnets = var.nat_gateway_subnets
  subnets = var.subnets
  tags = var.tags
}
```
---

### `provider.tf`
```
provider  "aws" {
  region  =  var.region
}
```
---

### `terraform.tf`
```
terraform {
  required_version = ">= 0.15.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.39"
    }
  }
}
```
---

### `variables.tf`
```
variable "region" {
  description = "AWS Region"
  type = string
  default = ""
}

variable "account_id" {
  description = "List of Allowed AWS account IDs"
  type = list(string)
  default = [""]
}

variable "prefix" {
  description = "prefix for aws resources and tags"
  type = string
}

variable "vpc_name" {
  description = "VPC name"
  type = string
  default = ""
}

variable "vpc_cidr" {
  description = "VPC default cidr"
  type = string
  default = ""
}

variable "vpc_secondary_cidr" {
  description = "VPC secondary cidr"
  type = string
  default = ""
}

variable "azs" {
  description = "Availability Zone List"
  type = list
}

variable "tags" {
  description = "tag map"
  type = map(string)
}

variable "nat_gateway_subnets" {
  description = " NAT Gateway Subnets List"
  type = list
}

variable "subnets" {
  type = map(map(any))
}
```
---

### `outputs.tf`
```
output "vpc_id" {
  description = "VPC ID"
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block for VPC"
  value = module.vpc.vpc_cidr_block
}

output "vpc_secondary_cidr_block" {
  description = "CIDR block for VPC"
  value = module.vpc.vpc_secondary_cidr_block
}

output "sn1_subnet_ids" {
  description = "Subnet ID List"
  value = module.vpc.sn1_subnet_ids
}

output "sn2_subnet_ids" {
  description = "Subnet ID List"
  value = module.vpc.sn2_subnet_ids
}

output "igw_id" {
  description = "Internet Gateway ID"
  value = module.vpc.igw_id
}

output "sn1_natgw_id" {
  description = "Nat Gateway ID"
  value = module.vpc.sn1_natgw_id
}

output "sn2_natgw_id" {
  description = "Nat Gateway ID"
  value = module.vpc.sn2_natgw_id
}

output "sn1_public_route_table_ids" {
  description = "Public Route Table ID List"
  value = module.vpc.sn1_public_route_table_ids
}

output "sn2_public_route_table_ids" {
  description = "Public Route Table ID List"
  value = module.vpc.sn2_public_route_table_ids
}

output "sn1_private_route_table_ids" {
  description = "Private Route Table ID List"
  value = module.vpc.sn1_private_route_table_ids
}

output "sn2_private_route_table_ids" {
  description = "Private Route Table ID List"
  value = module.vpc.sn2_private_route_table_ids
}

output "default_security_group" {
  description = "Default Security Group"
  value = module.vpc.default_security_group
}
```