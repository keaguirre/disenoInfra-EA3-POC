output "alb_dns_name" {
  description = "URL pública del microservicio"
  value       = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.pagos.repository_url
}