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
  
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ]}))
  cidr_block = each.value.item
  availability_zone = var.azs[index(var.subnets[each.value].cidr, each.value.item)]

  tags = merge(var.tags, tomap({ Name = format("%s-%s-%s-%s-%s-sn", 
                                                var.prefix,
                                                var.vpc_name,
                                                var.azs[index(var.subnets[each.value].cidr, each.value.item)],
                                                var.subnets[each.value].ipv4_type,
                                                each.value.name
                                              )}))
}

# dynamic subnet 1 (sn1)
#resource "aws_subnet" "sn1" {
#  vpc_id = aws_vpc.this.id
#  
#  for_each = toset(keys({ for k, v in var.subnets : k => v }))
#  cidr_block = var.subnets[each.value].cidr[0]
#  availability_zone = var.azs[0]
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-sn", var.prefix, var.vpc_name, var.azs[0], var.subnets[each.value].ipv4_type, each.value)}))
#}

# dynamic subnet 2 (sn2)
#resource "aws_subnet" "sn2" {
#  vpc_id = aws_vpc.this.id
#  
#  for_each = toset(keys({ for k, v in var.subnets : k => v }))
#  cidr_block = var.subnets[each.value].cidr[1]
#  availability_zone = var.azs[1]#
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-sn", var.prefix, var.vpc_name, var.azs[1], var.subnets[each.value].ipv4_type, each.value)}))
#}

# nat gateway
resource "aws_nat_gateway" "this" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "public" }))
  allocation_id = aws_eip.nat[index(var.subnets[each.value].cidr, each.value.cidr)].id
  subnet_id = aws_subnet.this[each.value.name].id
  
  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-natgw",
                                               var.prefix,
                                               var.vpc_name,
                                               var.azs[index(var.subnets[each.value].cidr,
                                               each.value.name
                                              )])}))
}

# nat gateway for sn1
#resource "aws_nat_gateway" "sn1" {
#  allocation_id = aws_eip.nat[0].id
#  subnet_id = aws_subnet.sn1["bastion"].id
#  
#  depends_on = [
#    aws_internet_gateway.this
#  ]
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-natgw", var.prefix, var.vpc_name, var.azs[0])}))
#}

# nat gateway for sn2
#resource "aws_nat_gateway" "sn2" {
#  allocation_id = aws_eip.nat[1].id
#  subnet_id = aws_subnet.sn2["bastion"].id
#  
#  depends_on = [
#    aws_internet_gateway.this
#  ]
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-natgw", var.prefix, var.vpc_name, var.azs[1])}))
#}

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

# dynamic public route table for sn1
#resource "aws_route_table" "public_sn1" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "public" }))
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.this.id
#  }
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[0], var.subnets[each.value].ipv4_type, each.value)}))
#}

# dynamic public route table for sn2
#resource "aws_route_table" "public_sn2" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "public" }))
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.this.id
#  }
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[1], var.subnets[each.value].ipv4_type, each.value)}))
#}

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

# dynamic private route table for sn1
#resource "aws_route_table" "private_sn1" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "no" }))
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[0], var.subnets[each.value].ipv4_type, each.value)}))
#}

# dynamic private route table for sn2
#resource "aws_route_table" "private_sn2" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "no" }))
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[1], var.subnets[each.value].ipv4_type, each.value)}))
#}

# dynamic route table for private with nat gateway
resource "aws_route_table" "private" {
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

# dynamic private route table with natgw
#resource "aws_route_table" "natgw_attach_sn1" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "yes" }))
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_nat_gateway.sn1.id
#  }
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[0], var.subnets[each.value].ipv4_type, each.value)}))
#}

# dynamic private route table with natgw
#resource "aws_route_table" "natgw_attach_sn2" {
#  vpc_id = aws_vpc.this.id
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "yes" }))
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_nat_gateway.sn2.id
#  }
#
#  tags = merge(var.tags, tomap({Name = format("%s-%s-%s-%s-%s-rt", var.prefix, var.vpc_name, var.azs[1], var.subnets[each.value].ipv4_type, each.value)}))
#}

# public route table association
resource "aws_route_table_association" "public" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "public" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.public[each.value.item].id
}

# public route table association for sn1
#resource "aws_route_table_association" "public_sn1" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "public" }))
#
#  subnet_id = aws_subnet.sn1[each.value].id
#  route_table_id = aws_route_table.public_sn1[each.value].id
#}

# public route table association for sn2
#resource "aws_route_table_association" "public_sn2" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "public" }))
#
#  subnet_id = aws_subnet.sn2[each.value].id
#  route_table_id = aws_route_table.public_sn2[each.value].id
#}

# private route table association
resource "aws_route_table_association" "public" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "no" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.public[each.value.item].id
}

# private route table association for sn1
#resource "aws_route_table_association" "private_sn1" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "no" }))
#
#  subnet_id = aws_subnet.sn1[each.value].id
#  route_table_id = aws_route_table.private_sn1[each.value].id
#}

# private route table association for sn2
#resource "aws_route_table_association" "private_sn2" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "no" }))
#
#  subnet_id = aws_subnet.sn2[each.value].id
#  route_table_id = aws_route_table.private_sn2[each.value].id
#}

# private route table association with nat gateway
resource "aws_route_table_association" "public" {
  for_each = toset(keys({ for k, v in var.subnets : k => [ for i in v.cidr : { name = k, item = i } ] if v.ipv4_type == "private" && v.natgw == "yes" }))

  subnet_id = aws_subnet.this[each.value.item].id
  route_table_id = aws_route_table.public[each.value.item].id
}

# private route table association for sn1 with natgw
#resource "aws_route_table_association" "natgw_attach_sn1" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "yes" }))
#
#  subnet_id = aws_subnet.sn1[each.value].id
#  route_table_id = aws_route_table.natgw_attach_sn1[each.value].id
#}

# private route table association for sn2 with natgw
#resource "aws_route_table_association" "natgw_attach_sn2" {
#  for_each = toset(keys({ for k, v in var.subnets : k => v if v.ipv4_type == "private" && v.natgw == "yes" }))
#
#  subnet_id = aws_subnet.sn2[each.value].id
#  route_table_id = aws_route_table.natgw_attach_sn2[each.value].id
#}