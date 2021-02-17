output "public_ip" {
  description = "Public IP"
  value       = aws_eip.web.public_ip
}
