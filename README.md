# 🚀 Terraform Microservices on AWS ECS Fargate

This project contains a complete, modularized Terraform configuration to deploy a **microservices application** on AWS.  
The architecture consists of:

- 🟦 **NestJS backend service** running on ECS Fargate
- 🟧 **Angular frontend service** running on ECS Fargate
- 🍃 **Self-managed MongoDB server** running on a dedicated EC2 instance within a private subnet

The entire infrastructure is defined as code using **Terraform**, promoting **automation, reusability, and maintainability**.

---

## 🏗️ Architecture Diagram

The infrastructure is provisioned within a custom VPC, with public subnets for the load balancer and private subnets for the application containers and the database, ensuring a **secure and isolated environment**.

> *(Example Diagram)*  
> ALB in public subnets → ECS Fargate tasks in private subnets → MongoDB on EC2 (private subnet)  
> NAT Gateway in public subnet provides outbound internet access.

---

## ⚙️ Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Terraform** ≥ 1.0.0
- **AWS CLI** (configured with valid credentials)
- **Docker** (for building and pushing images)

---

## 📁 Project Structure

```plaintext
terraform-ecs-project/
├── modules/                # Contains reusable Terraform modules
│   ├── vpc/                # VPC, Subnets, IGW, NAT Gateway, Route Tables
│   ├── security_groups/    # Security Groups for ALB, ECS, and MongoDB
│   ├── ecs/                # ECS Cluster, Fargate Services, Task Definitions, ALB
│   └── ec2/                # EC2 instance for MongoDB
├── main.tf                 # Root module orchestrating all others
├── variables.tf            # Root variables definitions
├── outputs.tf              # Root outputs (e.g., application URL)
├── providers.tf            # Terraform and AWS provider configuration
├── terraform.tfvars        # Variable values (DO NOT commit sensitive data)
└── README.md               # This file
```

---

## 🧩 Module Breakdown

### 1️⃣ VPC Module
Responsible for setting up the network foundation.

- **aws_vpc** – Creates the isolated Virtual Private Cloud
- **aws_subnet** – Public/private subnets across AZs for HA
- **aws_internet_gateway** – Internet access for public subnets
- **aws_nat_gateway** – Outbound internet for private subnets
- **aws_route_table** – Routing for all subnets

### 2️⃣ Security Groups Module
Defines firewall rules for infrastructure components.

- **ALB SG:** Allows inbound HTTP(80)/HTTPS(443) from the internet
- **ECS Tasks SG:** Allows inbound only from ALB; outbound to DB/external APIs
- **MongoDB SG:** Allows inbound (27017) only from ECS Tasks SG

### 3️⃣ EC2 Module
Provisions the database server.

- **aws_instance** – Launches EC2 in private subnet
- **user_data** – Installs and configures MongoDB on startup

### 4️⃣ ECS Module
Runs containerized services.

- **aws_ecs_cluster** – Cluster definition
- **aws_lb** – Application Load Balancer for routing
- **aws_lb_target_group** – Separate targets for frontend/backend
- **aws_lb_listener & listener_rule** – Path-based routing (`/api/*` → backend, `/*` → frontend)
- **aws_ecs_task_definition** – Service blueprints (Docker images, env vars, ports)
- **aws_ecs_service** – Runs and maintains desired task count

---

## 🚀 Deployment Steps

### 1️⃣ Configure Variables
Rename or create your `terraform.tfvars` file:

```hcl
aws_region     = "us-east-1"
project_name   = "my-microservice-app"

backend_image_url  = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app/backend:latest"
frontend_image_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-microservice-app/frontend:latest"
```

---

### 2️⃣ Build & Push Docker Images

#### Initialize Terraform & Create ECR Repositories

```bash
terraform init
terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend
```

#### Authenticate Docker with ECR

```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com
```

#### Build, Tag, and Push Images

```bash
# Backend (NestJS)
docker build -t backend-app .
docker tag backend-app:latest <your-backend-ecr-url>:latest
docker push <your-backend-ecr-url>:latest

# Frontend (Angular)
docker build -t frontend-app .
docker tag frontend-app:latest <your-frontend-ecr-url>:latest
docker push <your-frontend-ecr-url>:latest
```

Update your `terraform.tfvars` with the new image URLs.

---

### 3️⃣ Deploy the Infrastructure

#### Initialize Terraform

```bash
terraform init
```

#### Plan Deployment

```bash
terraform plan
```

#### Apply Configuration

```bash
terraform apply
```

Confirm with `yes` when prompted.

---

### 4️⃣ Access the Application

Once complete, Terraform outputs your app’s URL:

```bash
Outputs:

application_url = "http://my-microservice-app-alb-123456789.us-east-1.elb.amazonaws.com"
```

Access your Angular frontend at this URL; it will communicate with your NestJS backend securely.

---

## 🧹 Cleaning Up

To destroy all resources and prevent charges:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

---

💡 **Tip:** Always version-control your Terraform configuration but **never commit credentials or `.tfstate` files**.