# Terraform AWS ECS Fargate Web Application Infrastructure

Infrastructure-as-Code project to deploy a production-ready containerized web application using:
- AWS ECS Fargate
- Application Load Balancer (ALB)
- HTTPS with ACM
- Auto-scaling
- Logging & monitoring with CloudWatch
- Private networking in VPC

See the architecture diagram:

![Architecture Diagram](docs/architecture-diagram.svg)

## Usage

1. Pick your environment (e.g. `environments/dev`)
2. Edit variables in `terraform.tfvars`
3. Run:
    -  terraform init
    -  terraform plan
    -  terraform apply

Outputs include ALB DNS name and ECS cluster info.

## Full Repo Layout

```text
terraform-ecs-fargate/
├── README.md
├── docs/
│   └── architecture-diagram.svg
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acm/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs_cluster/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs_task_definition/
│   │   ├── main.tf
```


