output "account_id" {
  description = "AWS Account Id"
  value = var.account_id
}

output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block for VPC"
  value = aws_vpc.this.cidr_block
}

output "igw_id" {
  description = "Internet Gateway ID"
  value = aws_internet_gateway.this.id
}

output "subnet_ids" {
  description = "Subnet ID List"
  value = [aws_subnet.this]
}

output "natgw_id" {
  description = "Nat Gateway ID"
  value = [aws_nat_gateway.this]
}

output "public_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.public]
}

output "private_route_table_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.private]
}

output "private_route_table_with_natgw_ids" {
  description = "Public Route Table ID List"
  value = [aws_route_table.private_with_natgw]
}

output "default_security_group" {
  description = "Default Security Group"
  value = aws_default_security_group.default_sg.id
}