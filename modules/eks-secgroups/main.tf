# Security group that eks-cluster will use

resource "aws_security_group" "eks-cluster-external" {
  name   = "${var.cluster_name}-external"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_security_group_rule" "eks-cluster-external-rule" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.external_port, 0)
  to_port           = element(var.external_port, 0)
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.eks-cluster-external.id
}

resource "aws_security_group" "eks-node-internal" {
  name   = "${var.cluster_name}-internal"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "eks-node-internal-rule-self" {
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-node-internal.id
  source_security_group_id = aws_security_group.eks-node-internal.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-internal-to-eks-cluster" {
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node-internal.id
  source_security_group_id = aws_security_group.eks-cluster-external.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-internal-ingress" {
  from_port                = element(var.external_port, 0)
  to_port                  = element(var.external_port, 0)
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.eks-cluster-external.id
  source_security_group_id = aws_security_group.eks-node-internal.id
}

resource "aws_security_group_rule" "eks-cluster-external-ingress" {
  from_port                = element(var.external_port, 0)
  to_port                  = element(var.external_port, 0)
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.eks-node-internal.id
  source_security_group_id = aws_security_group.eks-cluster-external.id
}

resource "aws_security_group_rule" "eks-node-allow-ssh" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = element(var.external_port, 1)
  to_port           = element(var.external_port, 1)
  protocol          = "tcp"
  type              = "ingress"
  security_group_id = aws_security_group.eks-node-internal.id
}

