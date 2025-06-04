output "subnet_id" {
  value = aws_subnet.new_subnet.id
}

output "subnet_cidr_block" {
  value = aws_subnet.new_subnet.cidr_block
}

output "vpc_id" {
  value = aws_subnet.new_subnet.vpc_id
}