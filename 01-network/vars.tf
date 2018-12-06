variable "region" {
  description = "region"
  default     = "eu-west-3"
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
  default     = "10.0.0.0/16"
}

variable "subnet_public" {
  description = "public subnet"
  default     = "10.0.0.0/24"
}
