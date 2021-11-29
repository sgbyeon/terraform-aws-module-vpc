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
  description = "VPC name tag"
  type = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for VPC"
  type = string
}

variable "azs" {
  description = "Availability Zone List"
  type = list
}

variable "enable_internet_gateway" {
  description = "internet gateway whether or not use"
  type = string
  default = "false"
}

variable "enable_nat_gateway" {
  description = "nat gateway whether or not use"
  type = string
  default = "false"
}

variable "tags" {
  description = "tag map"
  type = map(string)
}

variable "subnets" {
  type = map(any)
}