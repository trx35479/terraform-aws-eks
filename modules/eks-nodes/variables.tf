variable "CLUSTER_NAME" {}

variable "ROLE_NAME" {}

variable "AWS_KEYPAIR" {}

variable "WORKER_FLAVOR" {}

variable "IMAGE_ID" {}

variable "SUBNET_IDS" {
  type = "list"
}

variable "SECURITY_GROUPS" {
  type = "list"
}

variable "WORKER_USER_DATA" {}

variable "MIN_NUMBER_NODES" {}

variable "MAX_NUMBER_NODES" {}
