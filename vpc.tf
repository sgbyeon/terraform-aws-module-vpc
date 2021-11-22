# vpc
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"

  tags = merge(var.tags, tomap({"Name" = format("%s-%s", var.prefix, var.vpc_name)}))
}

# internet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, tomap({Name = format("%s-%s-igw", var.prefix, var.vpc_name)}))
}

# eip for nat gateway
resource "aws_eip" "nat" {
  vpc = true
  count = "${var.enable_nat_gateway == "true" ? length(var.azs) : 0 }"

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-eip", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# dynamic subnet
resource "aws_subnet" "this" {
  vpc_id = aws_vpc.this.id
  for_each = { for i in local.subnets : i.cidr => i }
  cidr_block = each.key
  availability_zone = var.azs[index(var.subnets[each.value.name].cidr, each.key)]

  tags = merge(var.tags, 
    tomap({ Name = format("%s-%s-%s-%s-%s-sn", 
    var.prefix,
    var.vpc_name,
    var.azs[index(var.subnets[each.value.name].cidr, each.key)],
    var.subnets[each.value.name].ipv4_type,
    each.value.name
  )}))
}

# nat gateway
resource "aws_nat_gateway" "this" {
  for_each = { for i in local.nat_gateway : i.cidr => i }
  allocation_id = aws_eip.nat[index(var.subnets[each.value.name].cidr, each.key)].id
  subnet_id = aws_subnet.this[each.key].id
  
  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(var.tags,
    tomap({Name = format("%s-%s-%s-%s-natgw",
    var.prefix,
    var.vpc_name,
    var.azs[index(var.subnets[each.value.name].cidr, each.key)]
  )}))
}

# dynamic route table for public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "public" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt",
                                               var.prefix,
                                               var.vpc_name,
                                               var.azs[index(var.subnets[each.value].cidr, each.value.cidr)],
                                               var.subnets[each.value].ipv4_type,
                                               each.value.name
                                              )}))
}

# dynamic route table for private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "no" }))

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt",
                                               var.prefix,
                                               var.vpc_name,
                                               var.azs[index(var.subnets[each.value].cidr, each.value.cidr)],
                                               var.subnets[each.value].ipv4_type,
                                               each.value.name
                                              )}))
}

# dynamic route table for private with nat gateway
resource "aws_route_table" "private_with_natgw" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "yes" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[index(var.subnets[each.value].cidr, each.value.cidr)].id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt",
                                               var.prefix,
                                               var.vpc_name,
                                               var.azs[index(var.subnets[each.value].cidr, each.value.cidr)],
                                               var.subnets[each.value].ipv4_type,
                                               each.value.name
                                              )}))
}

# public route table association
resource "aws_route_table_association" "public" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "public" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.public[each.value.item].id
}

# private route table association
resource "aws_route_table_association" "private" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "no" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.private[each.value.item].id
}

# private route table association with nat gateway
resource "aws_route_table_association" "private_with_natgw" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "yes" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.private_with_natgw[each.value.item].id
}