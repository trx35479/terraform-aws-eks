variable "ROLE_ARN" {}

variable "CLUSTER_NAME" {}

variable "SECURITY_GROUPS" {
  type = "list"
}

variable "SUBNET_IDS" {
  type = "list"
}

variable "POLICY_ARN" {
  type = "list"
}
