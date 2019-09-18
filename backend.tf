# Define the backend of terraform state (bucket has to be pre-created)
# this is important as the terraform will rely on the state file
# that been generated the last time the terraform apply was commited
terraform {
  backend "s3" {
    bucket  = "terraform-aws-statefile"
    key     = "infra/eks/terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}

