# 🚀 Terraform Microservices on AWS ECS Fargate

This project contains a complete, modularized Terraform configuration to deploy a **multi-environment microservices application** on AWS. The architecture consists of:

- 🟦 **NestJS backend service** running on ECS Fargate
- 🟧 **Angular frontend service** running on ECS Fargate
- 🍃 **Self-managed MongoDB server** running on a dedicated EC2 instance

This repository is structured to support **multiple environments (e.g., `testing`, `production`)**, promoting **automation, strong isolation, and maintainability**.

-----

## 🏗️ Architecture Diagram

The infrastructure *pattern* is deployed identically in each environment. Each environment gets its own completely separate set of resources (VPC, ECS Cluster, ALB, EC2 Instance) to ensure 100% isolation.

> *(Example Diagram)*
> ALB in public subnets → ECS Fargate tasks in private subnets → MongoDB on EC2 (private subnet)
> NAT Gateway in public subnet provides outbound internet access.

-----

## ⚙️ Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Terraform** ≥ 1.0.0
- **AWS CLI** (configured with valid credentials)
- **Docker** (for building and pushing images)

-----

## 📁 Project Structure

The project uses a directory-based structure to manage environments. The `modules/` directory contains all the reusable infrastructure blueprints. The `environments/` directory contains one subdirectory for each environment, which *consumes* those modules.

```plaintext
terraform-ecs-project/
├── modules/                # ✅ REUSABLE: Blueprints for our infra
│   ├── vpc/                # VPC, Subnets, IGW, NAT Gateway, Route Tables
│   ├── security_groups/    # Security Groups for ALB, ECS, and MongoDB
│   ├── ecs/                # ECS Cluster, Fargate Services, Task Definitions, ALB
│   └── ec2/                # EC2 instance for MongoDB
│
├── environments/           # ✅ NEW: Top-level for envs
│   ├── testing/            # <-- Testing Environment
│   │   ├── main.tf         # Calls modules for testing
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars  # Testing-specific values
│   │
│   └── production/         # <-- Production Environment
│       ├── main.tf         # Calls modules for production
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars  # Production-specific values
│
├── .gitignore
└── README.md
```

-----

## 🧩 Module Breakdown

### 1️⃣ VPC Module

Responsible for setting up the network foundation for *one environment*.

- **aws_vpc** – Creates the isolated Virtual Private Cloud
- **aws_subnet** – Public/private subnets across AZs for HA
- **aws_internet_gateway** – Internet access for public subnets
- **aws_nat_gateway** – Outbound internet for private subnets
- **aws_route_table** – Routing for all subnets

### 2️⃣ Security Groups Module

Defines firewall rules for *one environment*.

- **ALB SG:** Allows inbound HTTP(80)/HTTPS(443) from the internet
- **ECS Tasks SG:** Allows inbound only from ALB; outbound to DB/external APIs
- **MongoDB SG:** Allows inbound (27017) only from ECS Tasks SG

### 3️⃣ EC2 Module

Provisions the database server for *one environment*.

- **aws_instance** – Launches EC2 in private subnet
- **user_data** – Installs and configures MongoDB on startup

### 4️⃣ ECS Module

Runs containerized services for *one environment*.

- **aws_ecs_cluster** – Cluster definition
- **aws_lb** – Application Load Balancer for routing
- **aws_lb_target_group** – Separate targets for frontend/backend
- **aws_lb_listener & listener_rule** – Path-based routing (`/api/*` → backend, `/*` → frontend)
- **aws_ecs_task_definition** – Service blueprints (Docker images, env vars, ports)
- **aws_ecs_service** – Runs and maintains desired task count

-----

## 🚀 Deployment Steps

The deployment workflow is now performed *inside each environment's directory*.

### 1️⃣ Configure Environments

Create a `terraform.tfvars` file inside **each** environment directory.

**Example: `environments/testing/terraform.tfvars`**
(Focus on low cost)

```hcl
aws_region            = "us-east-1"
project_name          = "my-microservice-app"
mongodb_instance_type = "t3.micro"

# Testing Docker images (e.g., from a 'develop' branch build)
backend_image_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app-test/backend:latest-dev"
frontend_image_url    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app-test/frontend:latest-dev"
```

**Example: `environments/production/terraform.tfvars`**
(Focus on high availability and performance)

```hcl
aws_region            = "us-east-1"
project_name          = "my-microservice-app"
mongodb_instance_type = "t3.medium"

# Production Docker images (e.g., from a 'main' branch build)
backend_image_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app-prod/backend:v1.2.0"
frontend_image_url    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app-prod/frontend:v1.2.0"
```

-----

### 2️⃣ Deploy an Environment (e.g., Testing)

#### Navigate to the Environment Directory

```bash
cd environments/testing
```

#### Initialize Terraform

This initializes this environment and its unique state file.

```bash
terraform init
```

#### Create ECR Repositories

Run a targeted apply to create the ECR repositories first.

```bash
terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend
```

-----

### 3️⃣ Build & Push Docker Images

#### Authenticate Docker with ECR

```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com
```

#### Build, Tag, and Push Images

Push images to the **environment-specific** repository (e.g., `my-microservice-app-test/backend`).

```bash
# Backend (NestJS) for testing
docker build -t backend-app .
docker tag backend-app:latest <your-TESTING-backend-ecr-url>:latest-dev
docker push <your-TESTING-backend-ecr-url>:latest-dev
```

*(Repeat for the frontend)*

Update your `environments/testing/terraform.tfvars` with the new image URLs.

-----

### 4️⃣ Deploy the Full Environment

#### Plan Deployment

Review the resources that will be created for `testing`.

```bash
terraform plan
```

#### Apply Configuration

Build the entire `testing` infrastructure.

```bash
terraform apply
```

Confirm with `yes` when prompted.

-----

### 5️⃣ Promote to Production

To deploy to production, you follow the **exact same steps** but from within the `production` directory.

1.  `cd ../production`
2.  `terraform init` (to initialize the *production* state)
3.  `terraform apply -target=...` (to create *production* ECR repos)
4.  Build and push your **production-ready** images (e.g., `v1.2.0`)
5.  Update `environments/production/terraform.tfvars`
6.  `terraform plan`
7.  `terraform apply`

-----

## 🧹 Cleaning Up

To destroy resources, you must run the command **inside the specific environment folder** you wish to tear down.

```bash
# Navigate to the environment to destroy
cd environments/testing

# Destroy all resources for that environment
terraform destroy
```

Confirm with `yes`. This will **only** destroy `testing` resources; `production` will be safe.

-----

💡 **Tip:** Always use a **remote backend** (like S3) for your `production` environment state file. This is configured in `environments/production/main.tf`. Never commit `.tfstate` files to Git.