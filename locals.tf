locals {
  subnet = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        cidr = item
        name = key
      }
    ]
  ])
  cidrs = {
    for item in local.subnet :
    uuid() => item
  }
}