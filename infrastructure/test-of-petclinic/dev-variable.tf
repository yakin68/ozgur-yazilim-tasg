variable "mykey" {}
variable "ami" {
  description = "amazon ubuntu 22.04 ami"
}
variable "region" {}
variable "instance_type" {}
variable "devops_server_secgr" {}
variable "dev-server-ports" {
  type = list(number)
  description = "dev-server-sec-gr-inbound-rules"
}
variable "devservertag" {}