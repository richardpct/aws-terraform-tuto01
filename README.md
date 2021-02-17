# Purpose
The aim of this tutorial is to show you how to build a simple AWS example using
Terraform.
The example I choose is [the Getting Started with IPv4 for Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/getting-started-ipv4.html?shortFooter=true)

# Requirements
* You must have an AWS account, if you don't already have it, you can subscribe
to the free tier
* You must install terraform

# Usage
## Export the required variables in your terminal:
    $ export TF_VAR_region="eu-west-3"
    $ export TF_VAR_bucket="mybucket-terraform-state"
    $ export TF_VAR_network_remote_state_bucket="mybucket-terraform-state"
    $ export TF_VAR_network_remote_state_key="terraform/terraform.tfstate"
    $ export TF_VAR_ssh_public_key="ssh-rsa ..."

## Create the S3 backend to store the terraform state
    $ cd 00-bucket
    $ terraform init
    $ terraform apply

## Create the VPC
    $ cd ../01-network
    $ ./terraform_init.sh (execute this command once)
    $ terraform apply

## Create the webserver
    $ cd ../02-webserver
    $ ./terraform_init.sh (execute this command once)
    $ terraform apply

## Install apache2
The last command displays on the output the IP address of your webserver,
wait a few seconds then connect into it through SSH:

    $ ssh admin@xx.xx.xx.xx
    $ sudo su -
    $ apt-get update
    $ apt-get upgrade
    $ apt-get install apache2

Afterwards open your web browser using the IP address of your webserver

## Clean up
    $ cd ../02-webserver
    $ terraform destroy
    $ cd ../01-network
    $ terraform destroy

It isn't needed to clean up 00-bucket, because we will use it in the following
tutorials
