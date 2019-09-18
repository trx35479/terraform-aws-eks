# Expose the security group id

output "eks_cluster_security_group" {
  value = aws_security_group.eks-cluster-external.id
}

output "eks_node_security_group" {
  value = aws_security_group.eks-node-internal.id
}

