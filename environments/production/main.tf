# ECR Repositories
resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}/backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.project_name}/frontend"
}

# VPC Module
module "vpc" {
  source                = "../../modules/vpc"
  project_name          = var.project_name
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones    = ["${var.aws_region}a", "${var.aws_region}b"]
}

# Security Groups Module
module "security_groups" {
  source       = "../../modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# EC2 Module for MongoDB
module "ec2_mongodb" {
  source            = "../../modules/ec2"
  project_name      = var.project_name
  subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id = module.security_groups.mongodb_sg_id
}

# ECS Module
module "ecs" {
  source                  = "../../modules/ecs"
  project_name            = var.project_name
  aws_region              = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  alb_sg_id               = module.security_groups.alb_sg_id
  ecs_tasks_sg_id         = module.security_groups.ecs_tasks_sg_id

  backend_image_url       = var.backend_image_url
  frontend_image_url      = var.frontend_image_url

  # Construct the database URL using the private IP of the EC2 instance
  database_url            = "mongodb://${module.ec2_mongodb.private_ip}:27017/"
}
