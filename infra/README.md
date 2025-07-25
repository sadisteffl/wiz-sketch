graph TD
    subgraph "CI/CD"
        direction LR
        github_actions[GitHub Actions]
        github_actions -- "Build & Push" --> ecr[Amazon ECR]
        github_actions -- "Terraform Apply" --> aws[AWS Cloud]
    end

    subgraph "AWS Cloud"
        direction LR
        subgraph "User Facing"
            user[User]
            user -- "HTTPS" --> waf[AWS WAF]
            waf -- "Forwards Traffic" --> alb[Application Load Balancer]
        end

        subgraph "Amazon EKS Cluster (VPC)"
            alb -- "Routes to /" --> frontend_svc[Frontend Service]
            alb -- "Routes to /api" --> backend_svc[Backend Service]
            
            frontend_svc --> fe_pods[Frontend Pods (React + Nginx)]
            backend_svc --> be_pods[Backend Pods (Python/Flask)]
            
            fe_pods -- "Pulls Image" --> ecr
            be_pods -- "Pulls Image" --> ecr

            be_pods -- "Reads Secrets" --> secrets_manager[AWS Secrets Manager]
            secrets_manager -- "Via CSI Driver" --> be_pods
        end

        subgraph "Data & Storage"
            be_pods -- "TCP/27017" --> mongo_vm[EC2: MongoDB]
            mongo_vm -- "Backup Script (Cron)" --> s3_backup[S3 Bucket (Public)]
        end

        subgraph "Security & Monitoring"
            aws[AWS Cloud] -- "Monitors" --> guardduty[GuardDuty]
            aws[AWS Cloud] -- "Logs API Calls" --> cloudtrail[CloudTrail]
            aws[AWS_Cloud] -- "Aggregates Findings" --> security_hub[Security Hub]
            cloudtrail -- "Sends Insights & Logs" --> cw[CloudWatch]
            guardduty -- "Sends Findings" --> cw
            cw -- "Triggers Alarms" --> sns[SNS Topics]
            sns -- "Email Notifications" --> admin[Admin]
        end
    end
    
    classDef C_CD fill:#f9f,stroke:#333,stroke-width:2px;
    classDef C_AWS fill:#FF9900,stroke:#333,stroke-width:2px;
    classDef C_USER fill:#9CF,stroke:#333,stroke-width:2px;
    classDef C_EKS fill:#396,stroke:#333,stroke-width:2px;
    classDef C_DATA fill:#C9F,stroke:#333,stroke-width:2px;
    classDef C_SEC fill:#F66,stroke:#333,stroke-width:2px;

    class github_actions,ecr C_CD;
    class user,waf,alb C_USER;
    class frontend_svc,backend_svc,fe_pods,be_pods,secrets_manager C_EKS;
    class mongo_vm,s3_backup C_DATA;
    class guardduty,cloudtrail,cw,sns,admin,security_hub C_SEC;
    class aws C_AWS;