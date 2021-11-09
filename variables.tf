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

variable "vpc_secondary_cidr" {
  description = "IPv4 CIDR block"
  type = string
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