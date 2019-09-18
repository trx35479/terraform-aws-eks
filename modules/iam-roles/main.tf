# IAM role to be used by the eks cluster manager
data "template_file" "policy" {
  template = file("templates/policy.tpl")

  vars = {
    service_role = var.service_role
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name               = var.cluster_role
  assume_role_policy = data.template_file.policy.rendered
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  count      = length(var.eks_policy_cluster)
  policy_arn = "arn:aws:iam::aws:policy/${element(var.eks_policy_cluster, count.index)}"
  role       = aws_iam_role.eks-cluster-role.name
}

