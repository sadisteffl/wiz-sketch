# Automated S3 Bucket Public Access Remediation
This is a sample of my portfolio and contains an automated security response mechanism designed to detect and remediate publicly exposed AWS S3 buckets in near real-time. This serverless solution uses EventBridge, Lambda, and an SSM Automation document to enforce security policies and align with key compliance frameworks.

## Overview
In a cloud environment, misconfigurations can happen. A resource may get past CI/CD checks, an edge case might not be covered by Service Control Policies (SCPs), or a new compliance control may require remediating existing resources across the fleet. This automation acts as a critical detective and corrective control to address such scenarios.

The primary goal is to ensure that S3 buckets do not remain publicly accessible, thereby protecting sensitive data from unauthorized exposure. This serves as an automated way to enforce compliance controls without requiring manual overhead, inspired by the principle of "paved road" security used by companies like Netflix.

This type of automation is something Netflix uses: Snaring the Bad Folks https://netflixtechblog.com/snaring-the-bad-folks-66726a1f4c80

## Architecture
The solution is provisioned via Terraform and follows a simple, serverless, and event-driven architecture.

Detect: An EventBridge rule listens for PutBucketAcl API calls via CloudTrail, which indicate a change in an S3 bucket's Access Control List.

Trigger: Upon detecting an event that makes a bucket public, EventBridge triggers an AWS Lambda function.

Remediate: The Lambda function invokes an SSM Automation document, passing the name of the public bucket as a parameter. The runbook then applies a strict Public Access Block and sets the bucket ACL to private.

While this implementation uses an SSM Automation runbook for its simplicity and effectiveness, a more complex workflow could be orchestrated using AWS Step Functions. This would allow for more granular control, including sending notifications, creating service tickets, or handling more complex remediation logic.

For more information on similar AWS solutions, see the Automated Security Response on AWS implementation guide. https://aws.amazon.com/solutions/implementations/automated-security-response-on-aws/

## Compliance Alignment
This automation directly supports adherence to several critical controls within the ISO 27001 and SOC 2 compliance frameworks.