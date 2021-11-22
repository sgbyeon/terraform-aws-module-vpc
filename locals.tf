locals {
  subnets = flatten([
    for key, value in var.subnets : [
      for item in value : {
        name = key
        cidr = item[cidr]
        ipv4_type = item[ipv4_type]
        natgw = item[natgw]
      }
    ]
  ])
}