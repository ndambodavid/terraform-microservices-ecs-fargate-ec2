variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "project_name" {
  description = "A unique name for the project"
  type        = string
}

variable "backend_image_url" {
  description = "Full URL of the backend Docker image in ECR (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-project/backend:latest)"
  type        = string
}

variable "frontend_image_url" {
  description = "Full URL of the frontend Docker image in ECR"
  type        = string
}
