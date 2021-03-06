variable "cluster_name" {}

variable "role_name" {}

variable "aws_keypair" {}

variable "worker_flavor" {}

variable "image_id" {}

variable "subnet_ids" {
  type = "list"
}

variable "security_groups" {
  type = "list"
}

variable "worker_user_data" {}

variable "min_number_nodes" {}

variable "max_number_nodes" {}
