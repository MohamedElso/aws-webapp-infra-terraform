# Terraform AWS ECS Fargate Web Application Infrastructure

This repository contains a Terraform configuration for deploying a **production-ready containerized web application** on AWS. It provisions the necessary AWS infrastructure for a web application running on **Amazon ECS** (Elastic Container Service) with either **Fargate** (serverless containers) or EC2 launch types, fronted by an **Application Load Balancer (ALB)** for routing HTTP/HTTPS traffic. The setup supports **auto-scaling**, end-to-end **HTTPS** using AWS Certificate Manager (ACM), as well as centralized **logging and monitoring** with AWS services. All resources are created in the **`us-east-1`** region by default (this can be adjusted as needed).

## Purpose

The purpose of this project is to provide a reusable, **Infrastructure-as-Code (IaC)** template for a robust AWS hosting environment for containerized apps. Using Terraform ensures that the entire infrastructure is defined as code, making deployments consistent and repeatable. This setup follows AWS best practices for high availability and security, such as deploying across multiple Availability Zones and using a load balancer to prevent direct internet access to containers. It is ideal for learning, personal projects, or as a starting point for production deployments.

## Features

* **Amazon ECS Cluster** – Deploys a container cluster using AWS ECS. By default it uses **AWS Fargate** for serverless container execution (no EC2 management), but it can be configured for EC2 launch type if needed. ECS handles container orchestration and integrates with other AWS services for scalability and security.
* **Application Load Balancer (ALB)** – An ALB is set up to distribute incoming HTTP/HTTPS requests across the ECS tasks (containers). It runs in multiple Availability Zones for high availability, with health checks to detect unhealthy tasks and reroute traffic as needed. The ALB terminates SSL/TLS using an ACM certificate for your domain, providing secure HTTPS access.
* **Auto Scaling** – Supports auto-scaling of the ECS service based on load. A target tracking policy (e.g., based on CPU utilization or request count) automatically adjusts the number of running task instances to handle increases or decreases in traffic. This ensures the application can handle traffic spikes without manual intervention.
* **Secure Networking** – All components are deployed in a custom **VPC** with both public and private subnets across at least two AZs for resilience. ECS tasks run in **private subnets** (not directly accessible from the internet), and the ALB resides in **public subnets** to handle external traffic. Security groups and network ACLs enforce access controls (for example, only allow web traffic to the ALB, and allow the ALB to reach the tasks on the needed port).
* **HTTPS with ACM** – Uses **AWS Certificate Manager** to provision an SSL/TLS certificate for the application’s domain. The certificate is attached to the ALB’s HTTPS listener for secure encryption in transit. (You will need to provide a domain name and complete the ACM domain validation process. Terraform can optionally automate certificate creation if you have a Route 53 hosted zone for DNS validation.)
* **Logging** – Application container logs are sent to **Amazon CloudWatch Logs** (via the ECS task’s awslogs log driver), providing centralized log storage and easy retrieval. The ALB can be configured to send access logs to an S3 bucket for analysis (this is optional and can be enabled via Terraform variables).
* **Monitoring and Metrics** – The infrastructure integrates with **Amazon CloudWatch** for monitoring. ECS **Container Insights** is enabled on the cluster to collect detailed metrics on CPU, memory, and other container statistics. CloudWatch will aggregate metrics from ECS and ALB, and you can set up **CloudWatch Alarms** on key metrics (e.g., high CPU utilization) to get alerted or to trigger scaling. This provides observability into the health and performance of the system.
* **High Availability** – The design is highly available: resources are spread across multiple AZs, the ECS service can run tasks in each AZ, and the ALB balances traffic to healthy tasks only. If an entire AZ goes down, the application can continue serving from the other AZ. If a task or container fails health checks, ECS will replace it, and the ALB will stop sending traffic to it.
* **Cost Efficiency** – Using Fargate means you pay only for container runtime resources, eliminating the cost of running idle EC2 instances. Auto-scaling ensures you run just the needed number of tasks. You can also leverage Fargate Spot capacity for lower costs if desired (configurable in Terraform).

## Architecture Overview

*Figure: High-level architecture of the ECS Fargate web application deployment on AWS.* The diagram illustrates the key components and their interactions in this infrastructure:

* A **VPC** spans two Availability Zones, each with a **public subnet** (for ALB) and a **private subnet** (for ECS tasks). An **Internet Gateway** allows public subnets to reach the internet, and a **NAT Gateway** enables outbound internet access from private subnets (so containers can download updates, etc., without being publicly reachable).
* An **Application Load Balancer** is deployed in the public subnets. It listens on port 80 (HTTP) and port 443 (HTTPS). The ALB has an **HTTPS listener** with an ACM certificate for SSL, and it can optionally redirect HTTP to HTTPS. The ALB routes requests to the ECS service’s **target group** (attached to the ECS tasks) on the appropriate port.
* The **Amazon ECS cluster** (Fargate) is configured with a service that runs the containerized application. Tasks (containers) are launched in the private subnets and are registered behind the ALB via the target group. The ECS service is associated with an **Auto Scaling policy** (through AWS Application Auto Scaling) that will increase or decrease the number of task instances based on demand (for example, scale out when CPU usage is high, and scale in when it drops).
* **AWS Certificate Manager** provides an X.509 certificate for the ALB’s domain, enabling HTTPS. The certificate is either imported or requested (Terraform can request a free public certificate via ACM for a specified domain name).
* **Amazon CloudWatch** collects logs and metrics from the ECS tasks and the ALB. Each ECS task is configured to use the **CloudWatch Logs** log driver, so application logs stream to a log group. CloudWatch also monitors resource utilization and application load metrics; for instance, it can track average CPU across tasks, which feeds into the auto-scaling policy. Container Insights (if enabled) provides additional metrics at the cluster and service level.
* **Amazon ECR** (Elastic Container Registry) can be used to store the Docker container images for your application. (Alternatively, you can use Docker Hub or another registry.) If using ECR, an ECR repository can be provisioned for your app, and the ECS task execution role will have permissions to pull the image. You would build and push your application’s Docker image to ECR before deploying the infrastructure.
* **IAM Roles** are used to grant least-privilege access to AWS services. For example, the ECS task execution role allows the ECS tasks to pull images from ECR and write logs to CloudWatch. The ECS service also uses a service-linked role to register targets with the ALB on your behalf. All necessary roles/policies are created by Terraform.

Overall, the architecture is designed to be **scalable, secure, and highly available**. By using a load balancer and private subnets, it ensures that containers are not exposed directly to the internet. By spanning multiple AZs and using health checks, it can tolerate failures and continue running. And by leveraging AWS managed services (ECS, Fargate, ALB, etc.), it minimizes the operational overhead required to run a production-ready web application.

## Prerequisites

Before you begin, make sure you have the following:

* **AWS Account** – You will be deploying resources into your AWS account. Ensure you have an account with permissions to create the necessary resources (ECS, ALB, IAM, etc.). It’s recommended to use an IAM user or role with administrator privileges (or specific IAM policies for the services used).
* **Terraform** – Install Terraform (version 1.0 or higher). You can download Terraform from the [official site](https://developer.hashicorp.com/terraform/downloads) and follow their installation instructions.
* **AWS CLI** (optional but recommended) – Install and configure the AWS Command Line Interface. This helps in setting up your AWS credentials. Ensure your AWS credentials (Access Key ID and Secret) are configured either via the AWS CLI or environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or via Terraform Cloud/enterprise if using that.
* **AWS Credentials** – The Terraform configuration will need AWS credentials to create resources. Configure your credentials (in `~/.aws/credentials` or environment) for the target AWS account and the region `us-east-1`.
* **Domain Name** – *(For HTTPS)* You should have a domain name for which you can obtain an SSL certificate. The domain can be managed in Route 53 or another DNS provider. If using Route 53, Terraform can automatically request and validate an ACM certificate. Otherwise, you may need to manually validate the certificate (for example, via DNS records or email, depending on ACM options).
* **Docker & Container Image** – You should have a Docker image for your web application. For testing, you could use a publicly available sample image, but for your own app you’ll want to build it and push to a registry. If using Amazon ECR, ensure you have the Docker image pushed to an ECR repository in us-east-1 (Terraform can create the ECR repo for you, but you’ll build and push the image yourself, or integrate CI/CD). If using another registry (like Docker Hub), make sure the ECS task definition is configured with the correct image name and credentials if needed.
* **Terraform State Backend** (optional) – By default, Terraform will store state locally. If this is a team project or you prefer remote state, you should configure a backend (e.g., S3 + DynamoDB for state locking) in the Terraform files. The provided config can be adapted to use a remote backend.

## Usage / Deployment

Follow these steps to deploy the infrastructure:

1. **Clone the Repository** – Clone this GitHub repository to your local machine. Review the directory structure; key Terraform files (main configuration, variables, etc.) are typically in the root or a `terraform` directory.
2. **Review and Adjust Variables** – Open the `variables.tf` (or sample terraform.tfvars) file. Customize any default values:

   * VPC CIDR ranges or subnet CIDRs if the defaults conflict with your network.
   * ECS settings such as desired task count, CPU/memory for the task, container image name, etc.
   * Domain name for the ALB/ACM certificate (and Route 53 zone ID if using Route 53 for DNS).
   * Auto Scaling thresholds (e.g., target CPU utilization) and min/max task counts.
   * AWS profile or region if needed (defaults to `us-east-1`).
3. **Initialize Terraform** – In the project directory, run `terraform init`. This will download the necessary provider (AWS) and any Terraform modules used. For example, it will fetch the AWS provider and modules for VPC, ALB, ECS, etc., as defined in the configuration.
4. **Review Plan** – (Optional but recommended) Run `terraform plan` to see the list of resources that will be created and verify the configurations. Check that the plan matches your expectations.
5. **Apply Configuration** – Run `terraform apply` and confirm. Terraform will create all the AWS resources. The provisioning can take a few minutes (for example, creating the ALB, ECS cluster, etc.). If everything succeeds, Terraform will finish by outputting some values (like the ALB DNS name, etc.).
6. **Post-Deploy Steps** – After a successful apply:

   * **ACM Certificate Validation**: If Terraform requested a new ACM certificate for your domain, you need to validate it. Check the AWS Certificate Manager console for the certificate status. If using Route 53 and the zone was specified, DNS validation records might be created automatically. Otherwise, create the required CNAME records in your DNS provider as instructed by ACM. Wait for the certificate to be issued (Terraform will have created the ALB listener, but it might not serve HTTPS until the cert is issued).
   * **DNS Setup**: Update your DNS to point your domain (or subdomain) to the ALB. If using Route 53, you can create an Alias record to the ALB’s DNS name (Terraform can do this if configured). If using another DNS provider, use a CNAME to the ALB DNS name (which is output by Terraform, and looks like `*.elb.amazonaws.com`). This step is required for your custom domain to work. In the meantime, you can also test using the ALB’s default DNS name.
7. **Testing the Deployment** – Once the ALB is up and the ECS service is running tasks (check the ECS console to ensure the tasks are running and healthy), you can test the application:

   * Navigate to the ALB’s DNS name in a browser (or the custom domain you set up). You should see your web application responding. If you configured health check path for the ALB, ensure your application responds on that path so the ALB marks the targets healthy.
   * Test both **HTTP and HTTPS**. HTTP should redirect to HTTPS (if you enabled that configuration). HTTPS should show a secure lock icon in the browser with your domain’s certificate.
   * If you have issues, use the AWS console to check **CloudWatch Logs** for your ECS task (look at the Log Group for any error messages in the application), and check the **ALB Target Group** in the EC2 console for the health status of targets.
8. **Updating the Service** – To deploy a new version of your application, you would typically:

   * Build and push a new Docker image (e.g., to ECR).
   * Update the Terraform variable or task definition with the new image tag.
   * Run `terraform apply` again. ECS will perform a rolling update (if the service is configured with the ECS rolling deployment controller) to replace tasks one by one with the new image.
   * Alternatively, you can use CI/CD or ECS blue/green deployments, but that is outside the scope of this Terraform setup.
9. **Destroy (Cleanup)** – If you want to tear down the infrastructure, run `terraform destroy`. This will delete all the resources Terraform created. (Be cautious with this in a production environment.) Make sure to cleanup external resources as well (like the DNS records or any manually provisioned items).

## AWS Services Used

This project makes use of several AWS services to compose the application infrastructure:

* **Amazon ECS (Elastic Container Service)** – Orchestrates the deployment of Docker containers. We use ECS with Fargate launch type by default, so AWS manages the compute instances for us. ECS handles running the defined number of tasks, restarting failed tasks, and provides integration with load balancers and auto scaling.
* **AWS Fargate** – A serverless compute engine for containers. Fargate allows running containers without managing EC2 servers. The Terraform config defines an ECS cluster with Fargate capacity providers, meaning tasks run on Fargate by default (with optional Fargate Spot for cost savings). You can switch to EC2 launch type if more control is needed.
* **Amazon EC2** – (Optional) If using ECS with EC2 launch type, EC2 instances would be used to host the containers. In this configuration, an Auto Scaling Group of EC2 instances (with the ECS agent) would provide capacity for the cluster. (The default setup does **not** include EC2 instances since Fargate is used.)
* **Amazon VPC** – The networking foundation for the infrastructure. A new Virtual Private Cloud is created, with isolated subnets:

  * Public Subnets (one per AZ) for resources that need direct internet access (the ALB, NAT Gateway, etc.).
  * Private Subnets (one per AZ) for ECS tasks (no direct internet ingress). Outgoing internet traffic from tasks is routed through the NAT Gateway in a public subnet.
  * Routing tables, Internet Gateway, and NAT Gateway are set up to enable proper network flow.
* **Amazon Application Load Balancer (ALB)** – Distributes incoming traffic to the ECS tasks. It operates at layer 7 (HTTP/HTTPS) and supports features like path-based routing and health checks. The ALB in this project listens on HTTP (port 80) and HTTPS (port 443) and forwards requests to the ECS service’s tasks (target type is IP since tasks use awsvpc networking). Health checks are configured on the target group to monitor task health.
* **AWS Certificate Manager (ACM)** – Provides the SSL certificate for the ALB. Terraform can request a certificate for your domain through ACM. ACM handles renewal of certificates automatically. The certificate is attached to the ALB’s HTTPS listener so that SSL is terminated at the load balancer.
* **Amazon CloudWatch** – Used for both **logs** and **metrics/monitoring**. Each ECS task’s stdout/stderr logs are sent to CloudWatch Logs (in a log group named after the ECS service). CloudWatch also stores ALB access logs if enabled (alternatively, ALB can send access logs to S3). CloudWatch **metrics** collect data on CPU, memory, request count, latency, etc. for the ECS tasks and ALB. We can view these metrics in the CloudWatch console and have set up alarms or auto scaling triggers based on them. ECS Cluster **Container Insights** (if enabled) provides additional monitoring data.
* **Amazon ECR (Elastic Container Registry)** – (Optional) Used to store the Docker container image for the application. If enabled, Terraform will create an ECR repository for the app. You can push your Docker image to this repository, and the ECS task definition will refer to this image. The ECS task execution role includes permissions to pull from ECR. (If you prefer, you can use Docker Hub or another registry by adjusting the task definition image reference and providing credentials.)
* **AWS IAM** – Identity and Access Management is used to create roles and policies that grant permissions to resources:

  * ECS Task Execution Role (allows ECS tasks to call AWS APIs like CloudWatch Logs, ECR pull, etc.).
  * ECS Service linked role (grants ECS service ability to register with load balancer).
  * IAM roles for any other AWS integrations (for example, if your app needs to access S3 or Secrets Manager, you could attach a policy to the task role).
* **AWS Auto Scaling (Application Auto Scaling)** – Manages the scaling of the ECS service. Terraform defines an `aws_appautoscaling_target` and scaling policy for the ECS service (this is how we achieve the target tracking scaling). This AWS service monitors the CloudWatch metric (e.g., average CPU) and adjusts the desired count of tasks within the min/max bounds. It creates the necessary CloudWatch alarms under the hood to trigger scale-out and scale-in actions.
* **Route 53** – (Optional) If you use Route 53 for DNS, it can be used to simplify ACM validation and to create a friendly DNS record for the ALB. For example, Terraform can automatically add a CNAME in Route 53 to verify the ACM certificate, and create an **Alias record** pointing your domain to the ALB. If you use an external DNS provider, you’ll handle those steps manually.

## Terraform Modules Used

The Terraform configuration is organized using both direct AWS provider resources and re-usable modules from the Terraform Registry to simplify certain components:

* **Terraform AWS Provider** – The AWS provider is used to interact with AWS resources. Make sure your version of the provider is compatible (specified in `versions.tf`).
* **VPC Module** – Uses the official AWS VPC Terraform module (`terraform-aws-modules/vpc/aws`) to create the VPC, subnets, routing, IGW, NAT Gateway, etc. This module greatly simplifies network setup by providing sane defaults and high-level options.
* **ALB Module** – Uses the AWS ALB Terraform module (`terraform-aws-modules/alb/aws`) to provision the Application Load Balancer, target group, and listeners. This module helps manage the ALB and its associated security groups and listener rules. It is configured to set up an ALB in the public subnets, open port 80/443, and attach the target group for the ECS service.
* **ECS Module** – Uses the AWS ECS Terraform module (`terraform-aws-modules/ecs/aws`) for setting up the ECS cluster and (optionally) the ECS service/task definitions. This module can create the ECS cluster with the desired capacity providers (for Fargate and Fargate Spot) and can also create services. In our configuration, we employ the module to create the cluster and any capacity provider strategy, but the service and task definition are defined via separate Terraform resources for flexibility. (Alternatively, one could use this module’s service definition features).
* **ACM Module** – (Optional) While not a separate module, Terraform includes resources for ACM. If DNS validation is used with Route 53, the process can be streamlined using the `aws_route53_record` resource to create the validation record. No external module is needed for ACM, but our config ensures ACM certificate resource is created and validated via DNS.
* **Other Modules** – The configuration might also use minor modules or scripts:

  * e.g., **Terraform AWS ECR Module** (`terraform-aws-modules/ecr/aws`) to create an ECR repository.
  * **Security Group Module** (`terraform-aws-modules/security-group/aws`) for any complex security group rules (though basic security groups can also be defined with simple Terraform resources; the ALB module already handles some security group rules as seen in its configuration).
  * **CloudWatch Dashboard/Alarms** – No specific module is used; we directly use AWS resources for alarms if configured. However, a Terraform module could be introduced to create a CloudWatch Dashboard summarizing ECS/ALB metrics (as seen in the Turnerlabs example, they had an optional dashboard).
* **Outputs** – Terraform outputs are configured to provide important information after deployment, such as the ALB DNS name, the ECS service name/ARN, and so on. These outputs are useful for quick access to the deployed resources (for example, to quickly navigate to the ALB or to use the ALB DNS in testing or in creating DNS records).

All the Terraform modules and resources are orchestrated in the correct order by Terraform’s dependency graph. Variables and outputs are used to pass values between modules (for instance, the VPC module outputs subnet IDs which are inputs to the ALB and ECS configurations). By leveraging battle-tested Terraform modules (for VPC, ALB, etc.), the configuration is both easier to understand and aligned with community best practices.

---

Feel free to explore and modify this project to suit your needs. The README sections above give an overview of the setup. For detailed configurations, refer to the Terraform files in this repo. Contributions or suggestions are welcome. Happy deploying! 🚀
