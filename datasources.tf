# Extract custom amis, vpc-id, security groups and subnet-ids
# ami version will be based on the version of the aws eks cluster

data "aws_availability_zones" "az" {
}

#data "aws_ami" "eks-node-ami" {
#  most_recent = true
#  owners      = ["602401143452"]
#
#  filter {
#    name   = "name"
#    values = ["amazon-eks-node-${module.eks-cluster.eks-version}-v*"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#}
#
#