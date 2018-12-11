# Purpose
The aim of this tutorial is to show you how to build a simple aws example using Terraform.
The example I choose is [the Getting Started with IPv4 for Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/getting-started-ipv4.html?shortFooter=true)

# Requirement
* You must have an aws account, if you don't have yet, you can subscribe the free tier.
* You must install terraform

# Usage
## Exporting the required variables in your terminal:
    $ export TF_VAR_region="eu-west-3"
    $ export TF_VAR_ssh_public_key="ssh-rsa ..."
    $ export TF_VAR_network_remote_state_bucket="mybucket-terraform-state"
    $ export TF_VAR_network_remote_state_key="terraform/terraform.tfstate"

## Creating the s3 backend to store the terraform state
    $ cd 00-bucket
    $ terraform init
    $ terraform apply

## Creating the VPC
    $ cd ../01-network
    $ ./terraform_init.sh (execute this command once)
    $ terraform apply

## Creating the webserver
    $ cd ../02-webserver
    $ ./terraform_init.sh (execute this command once)
    $ terraform apply

## Installing apache2
The last command displays the address IP of your webserver, wait a few seconds then connect to it via ssh:

    $ ssh admin@xx.xx.xx.xx
    $ sudo su -
    $ apt-get update
    $ apt-get upgrade
    $ apt-get install apache2

Then open your web browser with the webserver IP address.

## Destroying all resources you have just created
    $ cd ../02-webserver
    $ terraform destroy
    $ cd ../01-network
    $ terraform destroy
