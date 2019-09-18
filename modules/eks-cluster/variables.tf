variable "role_arn" {}

variable "cluster_name" {}

variable "security_groups" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

variable "policy_arn" {
  type = "list"
}
