terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "admin_cidr" {
  type        = string
  description = "Administrator public IPv4 address in /32 format"

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && endswith(var.admin_cidr, "/32")
    error_message = "Enter one IPv4 address with /32, e.g. 203.0.113.10/32."
  }
}

locals {
  common_tags = {
    Project     = "tera-kube-ans"
    environment = "dev"
  }
}

# Existing AWS network
data "aws_vpc" "default" {
  id = "vpc-098a488fcca7d1dac"
}

data "aws_subnet" "qa" {
  id = "subnet-09012f8b6b8f07421"
}

# Current official Ubuntu 22.04 image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Internal traffic between Kubernetes nodes
resource "aws_security_group" "mutual" {
  name   = "petclinic-k8s-mutual-sec-group"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Internal Kubernetes cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-k8s-mutual-sec-group"
  }
}

# Kubernetes master security group
resource "aws_security_group" "master" {
  name   = "petclinic-k8s-master-sec-group"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Administrator SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Administrator Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Administrator NodePort access"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kube-master-secgroup"
  }
}

# Kubernetes worker security group
resource "aws_security_group" "worker" {
  name   = "petclinic-k8s-worker-sec-group"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Administrator SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Administrator NodePort access"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kube-worker-secgroup"
  }
}

# IAM role for Kubernetes master
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "master" {
  name               = "petclinic-master-server-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "master_s3" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "master" {
  name = "petclinic-master-server-profile"
  role = aws_iam_role.master.name
}

# Three Kubernetes EC2 instances
locals {
  nodes = {
    kube-master = "master"
    worker-1    = "worker"
    worker-2    = "worker"
  }
}

resource "aws_instance" "nodes" {
  for_each = local.nodes

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.medium"
  key_name                    = "Linux-key-pair"
  subnet_id                   = data.aws_subnet.qa.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.mutual.id,
    each.value == "master" ? aws_security_group.master.id : aws_security_group.worker.id
  ]

  iam_instance_profile = each.value == "master" ? aws_iam_instance_profile.master.name : null

  root_block_device {
    volume_type = "gp3"
    volume_size = 25
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = each.key
    Role = each.value
  })
}

output "kube-master-ip" {
  value = aws_instance.nodes["kube-master"].public_ip
}

output "worker-1-ip" {
  value = aws_instance.nodes["worker-1"].public_ip
}

output "worker-2-ip" {
  value = aws_instance.nodes["worker-2"].public_ip
}
