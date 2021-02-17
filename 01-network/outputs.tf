output "vpc_id" {
  value       = aws_vpc.my_vpc.id
  description = "VPC ID"
}

output "subnet_public_id" {
  value       = aws_subnet.public.id
  description = "Subnet Public ID"
}
