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

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-igw", var.prefix, var.vpc_name)}))
}

# eip for nat gateway
resource "aws_eip" "nat" {
  vpc = true
  count = length(var.nat_gateway_subnets)

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-eip", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway subnets
resource "aws_subnet" "natgw" {
  count = length(var.nat_gateway_subnets)

  vpc_id = aws_vpc.this.id
  cidr_block = var.nat_gateway_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, tomap({Name = format("%s-%s-public-%s-natgw-sn", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway
resource "aws_nat_gateway" "this" {
  count = length(var.nat_gateway_subnets)
  allocation_id = aws_eip.nat.*.id[count.index]
  subnet_id = aws_subnet.natgw.*.id[count.index]
  
  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-natgw", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway public route table
resource "aws_route_table" "natgw" {
  vpc_id = aws_vpc.this.id
  count = length(var.nat_gateway_subnets)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-public-%s-natgw-rt", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway route table association
resource "aws_route_table_association" "natgw" {
  count = length(var.nat_gateway_subnets)

  subnet_id = aws_subnet.natgw.*.id[count.index]
  route_table_id = aws_route_table.natgw.*.id[count.index]
}

# dynamic subnet 1
resource "aws_subnet" "sn1" {
  vpc_id = aws_vpc.this.id
  
  for_each = toset(keys({ for k, v in var.subnets : k => v }))
  cidr_block = var.subnets[each.value].cidr[0]
  availability_zone = var.azs[0]

  depends_on = [
    aws_nat_gateway.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-sn", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic subnet 2
resource "aws_subnet" "sn2" {
  vpc_id = aws_vpc.this.id
  
  for_each = toset(keys({ for k, v in var.subnets : k => v }))
  cidr_block = var.subnets[each.value].cidr[1]
  availability_zone = var.azs[1]

  depends_on = [
    aws_nat_gateway.this
  ]

  tags = merge(var.tags,tomap({Name = format("%s-%s-%s-%s-%s-sn", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[1], each.value)}))
}

# dynamic public route table for sn1
resource "aws_route_table" "public_sn1" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "public" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic public route table for sn2
resource "aws_route_table" "public_sn2" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "public" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[1], each.value)}))
}

# dynamic private route table for sn1
resource "aws_route_table" "private_sn1" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "disable" }))

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic private route table for sn2
resource "aws_route_table" "private_sn2" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "disable" }))

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[1], each.value)}))
}

# dynamic private route table with natgw
resource "aws_route_table" "natgw_attach_sn1" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "enable" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic private route table with natgw
resource "aws_route_table" "natgw_attach_sn2" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "enable" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[1].id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[1], each.value)}))
}

# public route table association for sn1
resource "aws_route_table_association" "public_sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "public" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.public_sn1[each.value].id
}

# public route table association for sn2
resource "aws_route_table_association" "public_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "public" }))

  subnet_id = aws_subnet.sn2[each.value].id
  route_table_id = aws_route_table.public_sn2[each.value].id
}

# private route table association for sn1
resource "aws_route_table_association" "private_sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "disable" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.private_sn1[each.value].id
}

# private route table association for sn2
resource "aws_route_table_association" "private_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "disable" }))

  subnet_id = aws_subnet.sn2[each.value].id
  route_table_id = aws_route_table.private_sn2[each.value].id
}

# private route table association for sn1 with natgw
resource "aws_route_table_association" "natgw_attach_sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "enable" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.natgw_attach_sn1[each.value].id
}

# private route table association for sn2 with natgw
resource "aws_route_table_association" "natgw_attach_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.ngw_attach[0] == "enable" }))

  subnet_id = aws_subnet.sn2[each.value].id
  route_table_id = aws_route_table.natgw_attach_sn2[each.value].id
}