
variable "project_name" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}
variable "alb_sg_id" {}
variable "ecs_tasks_sg_id" {}

variable "backend_image_url" {}
variable "frontend_image_url" {}
variable "database_url" {}

variable "backend_container_port" { default = 3000 }
variable "frontend_container_port" { default = 80 }

variable "backend_cpu" { default = 256 }
variable "backend_memory" { default = 512 }
variable "frontend_cpu" { default = 256 }
variable "frontend_memory" { default = 512 }