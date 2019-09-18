variable "aws_region" {
}

variable "cluster_name" {
}

variable "vpc_cidr_block" {
}

variable "public_subnet" {
  type = list(string)
}

variable "private_subnet" {
  type = list(string)
}

variable "aws_az" {
  type = list(string)
}

