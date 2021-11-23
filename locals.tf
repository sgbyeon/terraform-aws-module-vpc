locals {
  all_subnets = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        name = key
        cidr = item
      }
    ]
  ])
}

locals {
  public_subnets = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        name = key
        cidr = item
      }
    ] if value.ipv4_type == "public"
  ])
}

locals {
  private_subnets = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        name = key
        cidr = item
      }
    ] if value.ipv4_type == "private" && value.natgw == "no"
  ])
}

locals {
  private_subnets_with_natgw = flatten([
    for key, value in var.subnets : [
      for item in value.cidr : {
        name = key
        cidr = item
      }
    ] if value.ipv4_type == "private" && value.rt2natgw == "yes"
  ])
}