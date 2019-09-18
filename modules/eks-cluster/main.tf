# eks cluster config
resource "null_resource" "check-dependency-iam-role" {
  count = "${length(var.policy_arn)}"

  triggers {
    dependency_id = "${element(var.policy_arn, count.index)}"
  }
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${var.role_arn}"

  vpc_config {
    security_group_ids = ["${var.security_groups}"]
    subnet_ids         = ["${var.subnet_ids}"]
  }

  depends_on = ["null_resource.check-dependency-iam-role"]
}
