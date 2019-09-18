variable "aws_region" {
  default = "ap-southeast-2"
}

variable "cluster_name" {
  default = "my-eks"
}

variable "path_to_public_key" {
  default = "~/.ssh/id_rsa.pub"
}
