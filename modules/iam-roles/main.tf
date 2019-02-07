# IAM role to be used by the eks cluster manager
data "template_file" "policy" {
  template = "${file("templates/policy.tpl")}"

  vars {
    service_role = "${var.SERVICE_ROLE}"
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name               = "${var.CLUSTER_ROLE}"
  assume_role_policy = "${data.template_file.policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  count      = "${length(var.EKS_CLUSTER_POLICY)}"
  policy_arn = "arn:aws:iam::aws:policy/${element(var.EKS_CLUSTER_POLICY, count.index)}"
  role       = "${aws_iam_role.eks-cluster-role.name}"
}
