locals {
  subnets = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        name = key
        cidr = item
      }
    ]
  ])
}