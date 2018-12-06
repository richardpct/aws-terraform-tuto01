variable "region" {
  description = "region"
  default     = "eu-west-3"
}

variable "network_remote_state_bucket" {
  description = "bucket"
}

variable "network_remote_state_key" {
  description = "network key"
}

variable "image_id" {
  description = "image id"
  default     = "ami-00000f9d1b75a36f8"
}

variable "instance_type" {
  description = "instance type"
  default     = "t2.micro"
}

variable "ssh_public_key" {
  description = "ssh public key"
}
