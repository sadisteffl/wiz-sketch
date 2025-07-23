1. About the CI: 
9. Trivy

Trivy detects vulnerabilities, misconfigurations, and security issues across the software development lifecycle. It also makes IaC scanning simple by identifying configuration file types like Terraform, Kubernetes manifests, and Dockerfiles. With it, you can apply security policies to catch issues like overly permissive access controls or insecure default settings, which helps developers shift left and tackle security problems early in the development process. 

This tool scans filesystems and container images for known vulnerabilities in OS packages and app dependencies and includes secret scanning to detect hardcoded secrets like API keys and tokens in code or container images. 

With its versatility and ease of use, Trivy is great for DevSecOps since it keeps security a priority throughout development.

Supported languages: AWS, Terraform, Kubernetes, and more
Trivy detects vulnerabilities, misconfigurations, and security issues across the software development lifecycle. It also makes IaC scanning simple by identifying configuration file types like Terraform, Kubernetes manifests, and Dockerfiles. With it, you can apply security policies to catch issues like overly permissive access controls or insecure default settings, which helps developers shift left and tackle security problems early in the development process. 

This tool scans filesystems and container images for known vulnerabilities in OS packages and app dependencies and includes secret scanning to detect hardcoded secrets like API keys and tokens in code or container images. 

With its versatility and ease of use, Trivy is great for DevSecOps since it keeps security a priority throughout development.

Supported languages: AWS, Terraform, Kubernetes, and more

Pros:

Wide vulnerability database coverage

Fast scanning speed

Excellent container and IaC security

Highly accurate results

Cons:

Limited application code scanning features

Fewer custom rule options

Higher dependency focus than code logic

Lack of optimization for IDE integration


✅ Dependency vulnerability (SCA) – CVEs in your third‑party libraries.

✅ License & SBOM generation (where supported).

✅ Secret‑leak detection in source.

✅ The same checks inside the container image after it’s built (so JARs or Python wheels baked into the image are still scanned).

⚠️ No deep static‑code analysis (e.g., Bandit rules for Python or SpotBugs for Java). Trivy focuses on what you pull in, not line‑by‑line insecure code you write. If you also want SAST, bolt on tools like Semgrep/Bandit/SpotBugs as extra jobs.



data "aws_organizations_organization" "org" {}

resource "aws_organizations_policy" "deny_wildcard_permissions" {
  name        = "DenyWildcardPermissions"
  description = "Prevents attaching policies that grant '*' permissions to any IAM entity."
  content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyPolicyWithStarActionOrResource",
        "Effect" : "Deny",
        "Action" : [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:PutRolePolicy",
          "iam:PutUserPolicy",
          "iam:PutGroupPolicy",
          "iam:AttachUserPolicy",
          "iam:AttachGroupPolicy",
          "iam:AttachRolePolicy"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLikeIfExists" : {
            "iam:PolicyDocument" : "*\"Action\":\"*\"*"
          }
        }
      }
    ]
  })
  type = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "boundary_policy_attachment" {
  policy_id = aws_organizations_policy.deny_wildcard_permissions.id
  target_id = "r-bybs"
}

# Dont for get to add value of Wiz products into pres 

4. "Ensure Instance Metadata Service Version 1 is not enabled"
5. "Ensure IAM policies does not allow permissions management / resource exposure without constraints"

Push 

Automation: 
1. "Ensure Amazon EKS public endpoint disabled" 
6. "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions" 
  Tried to build but dont have permissions 
  


    8. Ensure S3 bucket has 'restrict_public_buckets' enabled"
    - already have this just need to add 


    9. "Ensure S3 bucket has ignore public ACLs enabled"
    "Ensure S3 bucket has block public policy enabled"
    1-. 
    "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
    10. "Ensure VPC subnets do not assign public IP by default"
    11. "Ensure that Secrets Manager secret is encrypted using KMS CMK"
    12. Ensure that Secrets Manager secret is encrypted using KMS CMK"
    13. Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" 