---
title: "AWS with Terraform tutorial 01"
date: 2021-02-20T15:11:25Z
draft: false
---

## Purpose

I will show you how to build a simple AWS example using Terraform for your
first steps.<br />
The example that I have chosen is [the Getting Started with IPv6 for Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/get-started-ipv6.html),
you will able to create a EC2 instance in AWS which we will spin up a web service.

You will learn how to create:

* A S3 bucket
* A VPC
* A public subnet
* A EC2 using an Amazon Linux image
* A Internet Gateway
* A Elastic IP
* A route table
* Some security groups to define firewall rules
* A SSH key for connecting to the EC2

The following figure shows you an overview of what you will build:

<img src="https://raw.githubusercontent.com/richardpct/images/master/aws-tuto-01/image01.png">

The default route table contains:

| Destination | Target           |
|-------------|------------------|
| 10.0.0.0/16 | local            |
| 0.0.0.0     | Internet Gateway |

The source code is available on my [Github repository](https://github.com/richardpct/aws-terraform-tuto01).

## Requirements

* You must create a regular user in the IAM management console with some
permissions to avoid using the root account
* You must add your AWS credential on your local machine, for example by using
~/.aws/config and ~/.aws/credentials files so that Terraform is able to make
requests to the AWS API
* You must install the latest Terraform version (0.14.x)

## Create a S3 bucket

Terraform must store the state of our current infrastructure somewhere, you
could store the state on your local machine but in this case you are the only
one who can access it. By using a S3 bucket for storing your Terraform state,
your coworkers can also to access it.<br />
The first thing to do is to create a S3 bucket on AWS, you should never delete
it because you will need it as long as you use AWS with Terraform.<br />

You must create a working directory, let's say `~/terraform/tuto-01`, then
create a file named `00-bucket/main.tf` containing:

#### 00-bucket/main.tf

```
// Setting a provider and a region
provider "aws" {
  region = var.region
}

// Creating a S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket
  acl    = "private"

  versioning {
    enabled = true
  }

// Comment the following block if you want to destroy your S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}
```

The `var.region` and `var.bucket` variables hold values that will be defined in
the next section.

#### 00-bucket/vars.tf

Here is the definition of the variables that I mentionned in the previous
section:

```
variable "region" {
  type        = string
  description = "Region"
}

variable "bucket" {
  type        = string
  description = "Bucket"
}
```

I could set the variables now by using `default` attribute, but I prefer use
environment variables in order not to include them on my Github repository
because datas such as bucket name or SSH keys are sensible.

#### 00-bucket/versions.tf

I enforce the usage to a specific version of Terraform:

```
terraform {
  required_version = ">= 0.14"
}
```

#### Initialize the working directory

You shoud have 3 files in your working directory:

```
├── 00-bucket
│   ├── main.tf
│   ├── vars.tf
│   └── versions.tf
```

You must initialize your working directory in order to retrieve the AWS plugins:

    $ terraform init

You have now a new .terraform directory created:

```
├── 00-bucket
│   ├── .terraform/
│   ├── main.tf
│   ├── vars.tf
│   └── versions.tf
```

#### Deployment

In the `vars.tf` file we have declared 2 variables: `region` and `bucket`.<br />
Export the following environment variables in order to assign values to the
variables:

    $ export TF_VAR_region="eu-west-3"
    $ export TF_VAR_bucket="mybucket-terraform-state"

As you can see you must add the prefix `TF_VAR_` with the variable name so that
Terraform figures out which variables to use.

Let's create our S3 bucket:

    $ terraform apply

It will creates a `terraform.tfstate` file containing the state of our
infrastructure, you should never delete it!

```
├── 00-bucket
│   ├── main.tf
│   ├── terraform.tfstate
│   ├── vars.tf
│   └── versions.tf
```

Notice it is the only time that we store the Terraform state in our local
machine in order to create the bucket.<br />
From now on, we will store Terraform states of all our infrastructure stack in
this bucket.

## Create the network stack

Create a new repository, let's say `~/terraform/tuto-01/01-network`.

#### 01-network/backends.tf

We specify to Terraform that we use a remote backend in order to store our
states:

```
terraform {
  backend "s3" {
  }
}
```

#### 01-network/main.tf

Select our AWS region:

```
provider "aws" {
  region = var.region
}
```

Create our VPC:

```
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "my_vpc"
  }
}
```

Create a Internet Gateway assiociated to our VPC:

```
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}
```

Create a subnet in our VPC:

```
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_public

  tags = {
    Name = "subnet_public"
  }
}
```

Create a default route to the Internet Gateway:

```
resource "aws_default_route_table" "route" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "default route"
  }
}
```

Associate the default route table with our subnet:

```
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_default_route_table.route.id
}
```

Our subnet is public because its default route is the Internet Gateway, that is
this subnet is able to reach Internet, and outside is able to reach the
instance inside this subnet.

#### 01-network/vars.tf

Declare the variables and define the values:

```
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
```

#### 01-network/outputs.tf

We need to track some datas on our S3 bucket such as the VPC ID and the Public
Subnet ID so that they will be used later by the webserver stack, because for
building the webserver you will need to get the VPC ID and the public subnet ID
to be able to reference it:

```
output "vpc_id" {
  value       = aws_vpc.my_vpc.id
  description = "VPC ID"
}

output "subnet_public_id" {
  value       = aws_subnet.public.id
  description = "Subnet Public ID"
}
```

#### Deployment

You shoud have these files in your 01-network directory:

```
├── 01-network
│   ├── backends.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── vars.tf
│   └── versions.tf
```

Export the following variables:

    $ export TF_VAR_region="eu-west-3"
    $ export TF_VAR_bucket="yourbucket-terraform-state"
    $ export TF_VAR_key_network="terraform/dev/network/terraform.tfstate"

Initialize your working Terraform directory:

    $ terraform init \
          -backend-config="bucket=${TF_VAR_bucket}" \
          -backend-config="key=${TF_VAR_key_network}" \
          -backend-config="region=${TF_VAR_region}"

`bucket` is the name of the bucket that we have defined earlier, and `key` is
where our state will be stored.

Then build your network stack:

    $ terraform apply

## Create the WebServer stack

For this section I will show only the relevant snippet, to see the complete
code go to my [Github repository](https://github.com/richardpct/aws-terraform-tuto01).
<br />
Create a directory named `02-webserver` in your working directory.<br />

#### 02-webserver/backends.tf

I declare the remote backend which contains the datas that the network stack has
exported to our S3 bucket:

```
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.bucket
    key    = var.key_network
    region = var.region
  }
}
```

The following figure explains how some informations can be shared between 2
distinct stacks using a S3 bucket:

<img src="https://raw.githubusercontent.com/richardpct/images/master/aws-tuto-01/image02.png">

#### 02-webserver/main.tf

I define a public SSH key resource in order to copy it to the Linux server:

```
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}
```

I declare a Security Group associated with our VPC for the WebServer:

```
resource "aws_security_group" "webserver" {
  name   = "sg_webserver"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name = "webserver sg"
  }
}
```

I specify a firewall rule that allows the world to connect to our server via
SSH (in the real world we should only allow our own IP to connect to our
instance):

```
resource "aws_security_group_rule" "inbound_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webserver.id
}
```

The following rule allows the world to make HTTP requests to our server:

```
resource "aws_security_group_rule" "inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webserver.id
}
```

The following rule allows our server to reach Internet, for example to be
able to update the Linux system:

```
resource "aws_security_group_rule" "outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webserver.id
}
```

We build a server using a Amazon Linux image:

```
resource "aws_instance" "web" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = data.terraform_remote_state.network.outputs.subnet_public_id
  vpc_security_group_ids = [aws_security_group.webserver.id]

  tags = {
    Name = "Web Server"
  }
}
```

We create a Elastic IP which is attached to our server so that it can
communicate with Internet:

```
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  vpc      = true
}
```

#### 02-webserver/vars.tf

Define the following variables with the values:

```
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
```

#### 02-webserver/outputs.tf

Display the Elastic IP associated to our server so that we can connect to it:

```
output "public_ip" {
  description = "Public IP"
  value       = aws_eip.web.public_ip
}
```

#### Deployment

You should have these files in your working directory:

```
├── 00-bucket
│   ├── main.tf
│   ├── terraform.tfstate
│   ├── vars.tf
│   └── versions.tf
├── 01-network
│   ├── backends.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── vars.tf
│   └── versions.tf
├── 02-webserver
│   ├── backends.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── vars.tf
│   └── versions.tf
```

Export the required environment variable containing your public SSH key:

    $ export TF_VAR_ssh_public_key="ssh-rsa XYZ..."

Initialize your working Terraform directory:

    $ terraform init \
        -backend-config="bucket=${TF_VAR_bucket}" \
        -backend-config="key=${TF_VAR_key_webserver}" \
        -backend-config="region=${TF_VAR_region}"

Then build the server:

    $ terraform apply

## Install a Web Server with Nginx

The previous command displays on the output the public IP address of our
webserver, wait a few seconds then connect into it via SSH:

    $ ssh ec2-user@xx.xx.xx.xx
    # sudo su -
    # yum update
    # yum install nginx

Afterwards open your web browser using the IP address of your webserver.

## Clean up

When you have finished to build your infrastructure, you can destroy it:

    $ cd ../02-webserver
    $ terraform destroy
    $ cd ../01-network
    $ terraform destroy

You don't need to clean up our bucket because we will need it in the next
tutorials for storing our Terraform states.<br />
<br />
You may be wondering why I have decided to split the Terraform code in 3
sections as I could have written it in the same directory?<br />
In the case that you have written all your code in the same directory, if you
want for example modify the type of your instance, you should destroy all your
infrastructure then rebuild it. In the case when we split the stacks, we only
destroy then rebuild the webserver stack, the network stack remains unchanged,
hence we save more times.

## Summary

Congratulation to you if you have succeeded to follow this tutorial!<br />
As you can see it is not so hard to build a infrastructure using Terraform, in
the next tutorial I will show you how to organize better your code using the
modules.
