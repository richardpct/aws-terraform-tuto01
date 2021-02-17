variable "region" {
  type        = string
  description = "Region"
  default     = "eu-west-3"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC cidr block"
  default     = "10.0.0.0/16"
}

variable "subnet_public" {
  type        = string
  description = "Public subnet"
  default     = "10.0.0.0/24"
}
