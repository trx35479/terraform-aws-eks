# expose eks attributes for further use of other servcies

output "eks-endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

output "eks-ca" {
  value = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}

output "eks-version" {
  value = aws_eks_cluster.eks-cluster.version
}
