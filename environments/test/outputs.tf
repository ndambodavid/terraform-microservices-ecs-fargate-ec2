output "application_url" {
  description = "The URL to access the deployed application"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "backend_ecr_repository_url" {
  description = "The URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "The URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}
