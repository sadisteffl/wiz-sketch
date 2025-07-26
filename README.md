# Sketchy-AI #test 
Welcome to the "Sketchy-AI" repository, the home of a project that's as fun as it is intentionally flawed.

The "Sketchy" Concept
At its core, this repository builds Sketchy-AI, a cloud-native AI Pictionary game. A user sketches a drawing, and the AI backend does its best to guess what it is. The entire application is built on a modern tech stack, fully automated and deployed on AWS using Terraform and GitHub Actions CI/CD pipelines.

The "sketchy" name is a pun. It refers not only to the sketching in the game but also to the infrastructure's security posture, which was built to be "sketchy" by design for this exercise.

A Tour of the Codebase
This repository is a comprehensive example of a three-tier web application, complete with all the necessary automation and security considerations for a modern cloud environment. Here’s a quick overview:

Infrastructure as Code (/infra/terraform): The entire AWS environment—from the VPC and EKS cluster to the WAF and S3 buckets—is defined with Terraform. This includes the deliberate misconfigurations requested in the exercise, such as an EC2 instance with an outdated OS, an old version of MongoDB, and an overly permissive IAM role granting it administrator access.

Kubernetes Configuration (/infra/k8s): All application components are deployed to the EKS cluster using standard Kubernetes manifests. This includes a ClusterRoleBinding that grants a service account powerful cluster-admin privileges, another intentional risk.

Application Code (/src):

A Python Flask backend serves the AI model and API endpoints.

A React-based frontend provides the user interface for the Pictionary game.

CI/CD Automation (/.github/workflows):

An infrastructure pipeline validates and applies Terraform changes.

An application pipeline automatically builds and pushes the frontend and backend Docker images to Amazon ECR upon code changes.

Security Controls (security.tf):

Preventative: The application is shielded by an AWS WAF using managed rule sets for common threats like SQL injection and bad inputs. All container images are stored in ECR repositories encrypted with a customer-managed KMS key.

Detective: Comprehensive monitoring is established through AWS GuardDuty, Security Hub, and CloudTrail. I've configured custom CloudWatch alarms to send email notifications for high-severity GuardDuty findings or unusual API activity detected by CloudTrail Insights. I even set up a specific alarm to detect the planned NVIDIAScape exploit by searching for its unique log signature.



## About the CI: 

### Terraform Cloud 

This repository uses a GitHub Actions workflow to automate our Terraform deployments. On every push and pull request, the workflow initializes Terraform, checks code formatting, and generates an execution plan. Changes are automatically applied to the production environment only when a push is made to the main branch, ensuring a consistent and validated deployment process.

### Trivvy 

This repository includes a CI for a Trivy security workflow that runs on every push and pull request to main. It automatically scans container images, Terraform code, and application dependencies for vulnerabilities, hardcoded secrets, and license issues. All findings are integrated into the GitHub Security tab, and a Software Bill of Materials (SBOM) is generated as a downloadable artifact.

## EKS CI 

# Preventative Measures 



## SCP 
This project intentionally includes vulnerabilities like wildcard IAM permissions for demonstration purposes. In a mature DevSecOps pipeline, such risks would be blocked by preventative guardrails. An attempt was made to implement these controls using AWS Service Control Policies (SCPs), such as "Block Overpermissive Policies," which act as a foundational security layer for the entire organization. However, this was not possible due to insufficient permissions to apply SCPs in the target AWS account.

Failing to block these permissions introduces severe risks. A compromised resource with wildcard permissions could lead to a full account takeover, allowing an attacker to exfiltrate sensitive data, destroy infrastructure, or incur massive costs. Even less-permissive roles, if over-privileged, enable lateral movement across the cloud environment, dramatically increasing the blast radius of a single breach. Implementing SCPs is therefore a critical "shift-left" strategy to enforce least privilege and prevent entire classes of security vulnerabilities before they are ever deployed.

# Automations 
# Compliance 
## Incident Response 



# Penetration Testing 


A core component of my plan for this technical exercise was to recreate the recently disclosed NVIDIAScape container escape vulnerability (CVE-2025-23266). My intention was to build the specified three-tier architecture with this specific, critical vulnerability in place. This would have allowed me to demonstrate a full-cycle security scenario: actively exploiting the vulnerability to gain host access, detecting the attack with the security controls I had prepared, and showcasing an automated remediation workflow.


Unfortunately, my initial plan to use a pre-existing vulnerable container image was unsuccessful, as all official public images have already been patched by their maintainers.

In an effort to proceed, I began creating my own custom container image that was intentionally vulnerable to CVE-2025-23266. However, deploying the required GPU-enabled Kubernetes node group in AWS EKS led to an infrastructure provisioning failure. The build was halted by a vCPU quota limitation on my AWS account. As this issue requires a formal limit increase request with AWS support, a process that can take several days, I was unable to proceed with this part of the demonstration within the allotted time.

I have included the exact Terraform error message below:
``` 
Error: waiting for EKS Node Group (wiz-exercise-cluster:gpu-nodes) create: unexpected state 'CREATE_FAILED', wanted target 'ACTIVE'. last error: eks-gpu-nodes-e8cc1adb-650b-a13e-6c92-cb90e6981e7b: AsgInstanceLaunchFailures: Could not launch On-Demand Instances. VcpuLimitExceeded - You have requested more vCPU capacity than your current vCPU limit of 0 allows for the instance bucket that the specified instance type belongs to. Please visit http://aws.amazon.com/contact-us/ec2-request to request an adjustment to this limit. Launching EC2 instance failed.
│ 
│   with aws_eks_node_group.gpu_nodes,
│   on eks.tf line 57, in resource "aws_eks_node_group" "gpu_nodes":
│   57: resource "aws_eks_node_group" "gpu_nodes" { 
```
This roadblock prevented me from demonstrating the planned attack simulation. I had prepared logging alerts and Helm automation to detect and respond to the exploit, directly addressing the exercise's requirements to implement and demonstrate detective and responsive security controls. While I couldn't execute the full scenario, I have included samples of my planned work.

# Dont for get to add value of Wiz products into pres 






    Hurtles: 

    - NVIDA wanted to do pen test 