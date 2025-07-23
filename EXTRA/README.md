SCPs: 

Ran with Checkov 

Didnt have access 
Only have 5 - keep saying limit is going to come up 

1. "Ensure Amazon EKS public endpoint disabled" 
Description: This policy prevents users from creating or updating an Amazon EKS cluster with its public endpoint enabled. All communication with the Kubernetes API server must originate from within the cluster's VPC or a connected network, significantly reducing the cluster's attack surface.
2. "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions" 
Description: This policy prevents IAM principals from using certain high-privilege actions on a wildcard (*) resource. While SCPs cannot inspect the full content of a policy document during creation, this SCP restricts the use of overly permissive policies, forcing developers to specify the exact resources for sensitive operations.

Note: This list of actions is a sample. You should customize it based on the most critical operations in your environment.

3. Ensure S3 bucket has 'restrict_public_buckets' enabled"
Description: This single policy enforces all three of the recommended S3 account-level Block Public Access settings. It prevents anyone from modifying the account configuration to allow public buckets, public ACLs, or public policies. This is a foundational control for data protection in S3.

6. Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
7. "Ensure VPC subnets do not assign public IP by default"
Description: This policy prevents the creation of new subnets or the modification of existing ones to automatically assign public IPv4 addresses to instances launched within them. This encourages a more secure network design where public IPs are assigned deliberately, not by default.
10. Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy" 
Description: This policy prevents any IAM user, group, or role from having the AWS-managed AdministratorAccess policy attached. This is a critical preventative control that forces the use of more granular, least-privilege permissions instead of granting full administrative access.



SSM - Lambda Automation: 

