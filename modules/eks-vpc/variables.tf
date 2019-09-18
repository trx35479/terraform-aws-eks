variable "aws_region" {}
variable "cluster_name" {}
variable "vpc_cidr_block" {}

variable "public_subnet" {
  type = "list"
}

variable "private_subnet" {
  type = "list"
}

variable "aws_az" {
  type = "list"
}
