# Instantiate the modules
provider "aws" {
  region = "${var.AWS_REGION}"
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "${var.CLUSTER_NAME}-mykeypair"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

module "eks-vpc" {
  source = "modules/eks-vpc"

  AWS_REGION     = "${var.AWS_REGION}"
  CLUSTER_NAME   = "${var.CLUSTER_NAME}"
  VPC_CIDR_BLOCK = "10.212.0.0/16"
  PUBLIC_SUBNET  = ["10.212.10.0/24", "10.212.30.0/24", "10.212.50.0/24"]
  PRIVATE_SUBNET = ["10.212.20.0/24", "10.212.40.0/24", "10.212.60.0/24"]
  AWS_AZ         = ["${data.aws_availability_zones.az.names}"]
}

module "eks-secgroup" {
  source = "modules/eks-secgroups"

  CLUSTER_NAME  = "${var.CLUSTER_NAME}"
  VPC_ID        = "${module.eks-vpc.vpc_id}"
  EXTERNAL_PORT = ["443"]
}

module "eks-master-iam" {
  source = "modules/iam-roles"

  CLUSTER_ROLE       = "${var.CLUSTER_NAME}-master"
  SERVICE_ROLE       = "eks.amazonaws.com"
  EKS_CLUSTER_POLICY = ["AmazonEKSClusterPolicy", "AmazonEKSServicePolicy"]
}

module "eks-node-iam" {
  source = "modules/iam-roles"

  CLUSTER_ROLE       = "${var.CLUSTER_NAME}-node"
  SERVICE_ROLE       = "ec2.amazonaws.com"
  EKS_CLUSTER_POLICY = ["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"]
}

module "eks-cluster" {
  source = "modules/eks-cluster"

  CLUSTER_NAME    = "${var.CLUSTER_NAME}"
  ROLE_ARN        = "${module.eks-master-iam.arn}"
  POLICY_ARN      = "${module.eks-master-iam.policy_arn}"
  SUBNET_IDS      = "${module.eks-vpc.public_subnets}"
  SECURITY_GROUPS = ["${module.eks-secgroup.eks_cluster_security_group}"]
}

module "eks-nodes" {
  source = "modules/eks-nodes"

  CLUSTER_NAME     = "${var.CLUSTER_NAME}"
  AWS_KEYPAIR      = "${aws_key_pair.mykeypair.key_name}"
  ROLE_NAME        = "${module.eks-node-iam.role_name}"
  IMAGE_ID         = "${data.aws_ami.eks-node-ami.id}"
  WORKER_FLAVOR    = "t2.small"
  SUBNET_IDS       = "${module.eks-vpc.private_subnets}"
  SECURITY_GROUPS  = ["${module.eks-secgroup.eks_node_security_group}"]
  MIN_NUMBER_NODES = 3
  MAX_NUMBER_NODES = 5
  WORKER_USER_DATA = "${base64encode(data.template_file.bootstrap-node.rendered)}"
}
