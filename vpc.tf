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
  count = length(var.azs)

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-eip", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway for sn1
resource "aws_nat_gateway" "sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v == "natgw" }))
  allocation_id = aws_eip.nat[0]
  subnet_id = aws_subnet.sn1[each.value].id
  
  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-natgw", var.prefix, var.vpc_name, var.azs[0])}))
}

# nat gateway for sn2
resource "aws_nat_gateway" "sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v == "natgw" }))
  allocation_id = aws_eip.nat[1]
  subnet_id = aws_subnet.sn1[each.value].id
  
  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-natgw", var.prefix, var.vpc_name, var.azs[1])}))
}

# nat gateway public route table
resource "aws_route_table" "natgw" {
  vpc_id = aws_vpc.this.id
  count = length(var.azs)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-public-%s-natgw-rt", var.prefix, var.vpc_name, var.azs[count.index])}))
}

# nat gateway route table association for sn1
resource "aws_route_table_association" "natgw_sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v == "natgw" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.natgw[0]
}

# nat gateway route table association for sn2
resource "aws_route_table_association" "natgw_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v == "natgw" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.natgw[1]
}

# dynamic subnet 1 (sn1)
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

# dynamic subnet 2 (sn2)
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
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "no" }))

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic private route table for sn2
resource "aws_route_table" "private_sn2" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "no" }))

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[1], each.value)}))
}

# dynamic private route table with natgw
resource "aws_route_table" "natgw_attach_sn1" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "yes" }))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.subnets[each.value].ipv4_type[0], var.azs[0], each.value)}))
}

# dynamic private route table with natgw
resource "aws_route_table" "natgw_attach_sn2" {
  vpc_id = aws_vpc.this.id
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "yes" }))

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
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "no" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.private_sn1[each.value].id
}

# private route table association for sn2
resource "aws_route_table_association" "private_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "no" }))

  subnet_id = aws_subnet.sn2[each.value].id
  route_table_id = aws_route_table.private_sn2[each.value].id
}

# private route table association for sn1 with natgw
resource "aws_route_table_association" "natgw_attach_sn1" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "yes" }))

  subnet_id = aws_subnet.sn1[each.value].id
  route_table_id = aws_route_table.natgw_attach_sn1[each.value].id
}

# private route table association for sn2 with natgw
resource "aws_route_table_association" "natgw_attach_sn2" {
  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type[0] == "private" && v.natgw_enable[0] == "yes" }))

  subnet_id = aws_subnet.sn2[each.value].id
  route_table_id = aws_route_table.natgw_attach_sn2[each.value].id
}