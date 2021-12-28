# default security group
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, tomap({Name = format("%s.%s.default.security-groups", var.prefix, var.vpc_name)}))
}