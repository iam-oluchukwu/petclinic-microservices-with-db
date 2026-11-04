#!/bin/bash
set -euo pipefail
# update os
dnf update -y
# set server hostname as jenkins-server
hostnamectl set-hostname jenkins-server
# install git
dnf install git wget unzip -y
# install java 21
dnf install fontconfig java-21-amazon-corretto -y

# install jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key
dnf upgrade -y
dnf install jenkins -y

# install docker
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
usermod -a -G docker jenkins
systemctl enable jenkins
systemctl start jenkins
# install docker compose
curl -SL https://github.com/docker/compose/releases/download/v2.36.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# install AWS CLI version 2
if ! command -v aws >/dev/null 2>&1 ||
   ! aws --version 2>&1 | grep -q "aws-cli/2"; then
    mkdir -p /tmp/aws-cli-v2
    curl -fSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/aws-cli-v2/awscliv2.zip
    unzip -q -o /tmp/aws-cli-v2/awscliv2.zip -d /tmp/aws-cli-v2
    /tmp/aws-cli-v2/aws/install
fi

# install python 3
dnf install -y python3-pip python3-devel
# install ansible
pip3 install ansible
# install boto3
pip3 install boto3 botocore
# install terraform
wget https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_linux_amd64.zip
unzip terraform_1.11.4_linux_amd64.zip -d /usr/local/bin
