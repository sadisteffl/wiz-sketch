output "db_vm_public_ip" {
  description = "Public IP address of the Database VM."
  value       = aws_instance.db_server.public_ip
}

output "s3_bucket_public_url" {
  description = "Publicly accessible URL for the S3 bucket."
  value       = "http://${aws_s3_bucket.mongodb-backup.bucket}.s3.amazonaws.com/"
}
output "k8s_security_group_id" {
  description = "The ID of the security group created for the K8s cluster. Attach this to your K8s worker nodes."
  value       = aws_security_group.k8s_cluster.id
}

output "eks_cluster_name" {
  # Updated to reference the new cluster name
  value = aws_eks_cluster.sketch-ai-cluster.name
}
output "kubeconfig_command" {
  # Updated to reference the new cluster name
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.sketch-ai-cluster.name}"
  description = "Run this to update your kubeconfig after EKS is created"
}

output "frontend_ecr_repository_arn" {
  description = "The ARN of the frontend ECR repository."
  value       = aws_ecr_repository.sketchy_frontend_app.arn
}

output "backend_ecr_repository_arn" {
  description = "The ARN of the backend ECR repository."
  value       = aws_ecr_repository.sketchy_backend_app.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS Customer Managed Key used for ECR encryption."
  value       = aws_kms_key.ecr_eks_repository_cmk.arn
}

output "waf_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.sketchy_waf.arn
}
