# Security group that eks-cluster will use

resource "aws_security_group" "eks-cluster-external" {
  name   = "${var.CLUSTER_NAME}-external"
  vpc_id = "${var.VPC_ID}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.CLUSTER_NAME}"
  }
}

resource "aws_security_group_rule" "eks-cluster-external-rule" {
  count             = "${length(var.EXTERNAL_PORT)}"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "${element(var.EXTERNAL_PORT, count.index)}"
  to_port           = "${element(var.EXTERNAL_PORT, count.index)}"
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = "${aws_security_group.eks-cluster-external.id}"
}

resource "aws_security_group" "eks-node-internal" {
  name   = "${var.CLUSTER_NAME}-internal"
  vpc_id = "${var.VPC_ID}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.CLUSTER_NAME}",
     "kubernetes.io/cluster/${var.CLUSTER_NAME}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-node-internal-rule-self" {
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-node-internal.id}"
  source_security_group_id = "${aws_security_group.eks-node-internal.id}"
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-internal-to-eks-cluster" {
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-node-internal.id}"
  source_security_group_id = "${aws_security_group.eks-cluster-external.id}"
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-internal-ingress" {
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = "${aws_security_group.eks-cluster-external.id}"
  source_security_group_id = "${aws_security_group.eks-node-internal.id}"
}
