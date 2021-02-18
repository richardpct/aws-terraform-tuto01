terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.bucket
    key    = var.key_network
    region = var.region
  }
}
