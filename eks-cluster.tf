# Instantiate the modules
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "${var.cluster_name}-mykeypair"
  public_key = "${file("${var.path_to_public_key}")}"
}

module "eks-vpc" {
  source = "modules/eks-vpc"

  aws_region     = "${var.aws_region}"
  cluster_name   = "${var.cluster_name}"
  vpc_cidr_block = "10.212.0.0/16"
  public_subnet  = ["10.212.10.0/24", "10.212.30.0/24", "10.212.50.0/24"]
  private_subnet = ["10.212.20.0/24", "10.212.40.0/24", "10.212.60.0/24"]
  aws_az         = ["${data.aws_availability_zones.az.names}"]
}

module "eks-secgroup" {
  source = "modules/eks-secgroups"

  cluster_name  = "${var.cluster_name}"
  vpc_id        = "${module.eks-vpc.vpc_id}"
  external_port = ["443", "22"]
}

module "eks-master-iam" {
  source = "modules/iam-roles"

  cluster_role       = "${var.cluster_name}-master"
  service_role       = "eks.amazonaws.com"
  eks_policy_cluster = ["AmazonEKSClusterPolicy", "AmazonEKSServicePolicy"]
}

module "eks-node-iam" {
  source = "modules/iam-roles"

  cluster_role       = "${var.cluster_name}-node"
  service_role       = "ec2.amazonaws.com"
  eks_policy_cluster = ["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"]
}

module "eks-cluster" {
  source = "modules/eks-cluster"

  cluster_name    = "${var.cluster_name}"
  role_arn        = "${module.eks-master-iam.arn}"
  policy_arn      = "${module.eks-master-iam.policy_arn}"
  subnet_ids      = "${module.eks-vpc.public_subnets}"
  security_groups = ["${module.eks-secgroup.eks_cluster_security_group}"]
}

module "eks-nodes" {
  source = "modules/eks-nodes"

  cluster_name     = "${var.cluster_name}"
  aws_keypair      = "${aws_key_pair.mykeypair.key_name}"
  role_name        = "${module.eks-node-iam.role_name}"
  image_id         = "${data.aws_ami.eks-node-ami.id}"
  worker_flavor    = "t2.small"
  subnet_ids       = "${module.eks-vpc.private_subnets}"
  security_groups  = ["${module.eks-secgroup.eks_node_security_group}"]
  min_number_nodes = 3
  max_number_nodes = 5
  worker_user_data = "${base64encode(data.template_file.bootstrap-node.rendered)}"
}
