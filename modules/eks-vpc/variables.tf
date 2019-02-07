variable "AWS_REGION" {}
variable "CLUSTER_NAME" {}
variable "VPC_CIDR_BLOCK" {}

variable "PUBLIC_SUBNET" {
  type = "list"
}

variable "PRIVATE_SUBNET" {
  type = "list"
}

variable "AWS_AZ" {
  type = "list"
}
