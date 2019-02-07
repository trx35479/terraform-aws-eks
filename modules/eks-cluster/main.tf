# eks cluster config
resource "null_resource" "check-dependency-iam-role" {
  count = "${length(var.POLICY_ARN)}"

  triggers {
    dependency_id = "${element(var.POLICY_ARN, count.index)}"
  }
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.CLUSTER_NAME}"
  role_arn = "${var.ROLE_ARN}"

  vpc_config {
    security_group_ids = ["${var.SECURITY_GROUPS}"]
    subnet_ids         = ["${var.SUBNET_IDS}"]
  }

  depends_on = ["null_resource.check-dependency-iam-role"]
}
