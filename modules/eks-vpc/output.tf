# output the subnet's

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.main-public.*.id
}

output "private_subnets" {
  value = aws_subnet.main-private.*.id
}
