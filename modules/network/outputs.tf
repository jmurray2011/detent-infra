output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Delegate these NS records in your parent zone or registrar."
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  value = aws_acm_certificate.wildcard.arn
}
