variable "prefix" {
  description = "prefix for aws resources and tags"
  type = string
}

variable "region" {
  description = "AWS Region"
  type = string
  default = ""
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