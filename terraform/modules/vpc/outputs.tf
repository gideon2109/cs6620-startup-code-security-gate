output "vpc_id" {
  description = "ID of the SAST VPC"
  value       = aws_vpc.sast_vpc.id
}

output "private_subnet_id" {
  description = "ID of the private subnet where Lambda runs"
  value       = aws_subnet.private.id
}

output "public_subnet_id" {
  description = "ID of the public subnet where NAT Gateway sits"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda_sg.id
}
