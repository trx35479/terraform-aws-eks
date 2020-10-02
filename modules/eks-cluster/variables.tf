variable "role_arn" {}

variable "cluster_name" {}

variable "security_groups" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "policy_arn" {
  type = list(string)
}
