# send the arn to the output

output "arn" {
  value = aws_iam_role.eks-cluster-role.arn
}

output "policy_arn" {
  value = aws_iam_role_policy_attachment.eks-cluster-policy.*.policy_arn
}

output "role_name" {
  value = aws_iam_role.eks-cluster-role.name
}

