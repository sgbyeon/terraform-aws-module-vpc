output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block for VPC"
  value = aws_vpc.this.cidr_block
}

output "sn1_subnet_ids" {
  description = "Subnet ID List"
  value = [aws_subnet.sn1]
}

output "sn2_subnet_ids" {
  description = "Subnet ID List"
  value = [aws_subnet.sn2]
}

output "igw_id" {
  description = "Internet Gateway ID"
  value = aws_internet_gateway.this.id
}

output "sn1_natgw_id" {
  description = "Nat Gateway ID"
  value = [aws_nat_gateway.this[0].id]
}

output "sn2_natgw_id" {
  description = "Nat Gateway ID"
  value = [aws_nat_gateway.this[1].id]
}

output "sn1_public_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.public_sn1]
}

output "sn2_public_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.public_sn2]
}

output "sn1_private_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.private_sn1]
}

output "sn2_private_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.private_sn2]
}

output "default_security_group" {
  description = "Default Security Group"
  value = aws_default_security_group.default_sg.id
}