# eks cluster config
resource "null_resource" "check-dependency-iam-role" {
  count = length(var.policy_arn)

  triggers = {
    dependency_id = element(var.policy_arn, count.index)
  }
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  role_arn = var.role_arn

  vpc_config {
    security_group_ids = tolist(var.security_groups)
    subnet_ids         = tolist(var.subnet_ids)
  }

  depends_on = [null_resource.check-dependency-iam-role]
}
