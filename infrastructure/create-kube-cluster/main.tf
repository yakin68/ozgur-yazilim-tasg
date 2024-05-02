provider "aws" {
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # change here, optional
  name = "ozguryazilim"
  keyname = "yaksonkey"
  instancetype = "t3a.medium"
  ami = "ami-0e001c9271cf7f3b9"
}

resource "aws_instance" "master" {
  ami                  = local.ami
  instance_type        = local.instancetype
  key_name             = local.keyname
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  user_data            = file("master.sh")
  vpc_security_group_ids = [aws_security_group.tf-k8s-master-sec-gr.id]
  availability_zone = "us-east-1a"
  tags = {
    Name = "kube-master"
  }
}


resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2profile-${local.name}"
  role = aws_iam_role.ec2connect.name
}

resource "aws_iam_role" "ec2connect" {
  name = "ec2connect-${local.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess", "arn:aws:iam::aws:policy/IAMFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess", "arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output kube-master-ip {
  value       = aws_instance.master.public_ip
  sensitive   = false
  description = "public ip of the kube-master"
}
