variable "mykey" {}
variable "ami" {
  description = "amazon linux 2023 ami"
}
variable "region" {}
variable "instance_type" {}
variable "nexus_server_secgr" {}
variable "nexus-server-tag" {}
variable "admin_cidr" {
  description = "Administrator public IPv4 CIDR"
  type        = string
}
