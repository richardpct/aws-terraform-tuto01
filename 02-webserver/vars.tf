variable "region" {
  type        = string
  description = "Region"
  default     = "eu-west-3"
}

variable "bucket" {
  type        = string
  description = "Bucket"
}

variable "key_network" {
  type        = string
  description = "Network key"
}

variable "image_id" {
  type        = string
  description = "image id"
  default     = "ami-0ebc281c20e89ba4b" // Amazon Linux 2018
}

variable "instance_type" {
  type        = string
  description = "instance type"
  default     = "t2.micro"
}

variable "ssh_public_key" {
  type        = string
  description = "ssh public key"
}
