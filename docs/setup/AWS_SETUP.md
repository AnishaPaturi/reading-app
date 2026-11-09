# Reading Sanctuary — AWS Cloud Infrastructure Setup

This document details the configuration required to deploy Reading Sanctuary to Amazon Web Services (AWS) using S3, RDS PostgreSQL, and ECS Fargate.

---

## 1. Amazon S3 Bucket Configuration

Reading Sanctuary uses a private S3 bucket to store uploaded ebooks (PDF, EPUB, DOCX) and audiobooks (MP3, M4B).

### 1.1 Bucket Creation
Create a private S3 bucket (e.g., `reading-sanctuary-production-assets`):
- **Region**: e.g., `us-east-1` (match with application configuration)
- **Block Public Access**: **Enabled (All 4 settings ON)**. No objects are public; access is mediated strictly via presigned URLs.
- **Default Encryption**: SSE-S3 (`AES256`) or AWS KMS.

### 1.2 CORS Policy
To allow direct upload and playback via browser and mobile clients, apply the following CORS rule to the S3 bucket:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedOrigins": [
      "https://readingsanctuary.com",
      "https://*.readingsanctuary.com",
      "http://localhost:*"
    ],
    "ExposeHeaders": ["ETag", "Content-Range", "Accept-Ranges", "Content-Length"],
    "MaxAgeSeconds": 3600
  }
]
```

### 1.3 IAM Role & Policy for Backend Service
The ECS task execution role requires the following IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::reading-sanctuary-production-assets",
        "arn:aws:s3:::reading-sanctuary-production-assets/*"
      ]
    }
  ]
}
```

---

## 2. Amazon RDS PostgreSQL Database

### 2.1 Database Instance Specifications
- **Engine**: PostgreSQL 16.x
- **Instance Type**: `db.t4g.micro` (dev/staging) or `db.t4g.medium` (production)
- **Multi-AZ**: Enabled for production high availability
- **Storage**: Minimum 20 GB gp3 with auto-scaling enabled (up to 200 GB)
- **Automated Backups**: 7-day retention with Point-In-Time-Recovery (PITR)

### 2.2 Security Group Rules
- **Inbound Rule**: PostgreSQL port `5432` accessible ONLY from the ECS Security Group (`sg-ecs-tasks`). Never expose port 5432 to `0.0.0.0/0`.

---

## 3. Amazon ECS Fargate Container Service

### 3.1 Task Definition
- **CPU**: 1024 (1 vCPU)
- **Memory**: 2048 MB (2 GB)
- **Container Port**: `8080`
- **Environment Variables**:
  - `SPRING_PROFILES_ACTIVE`: `prod`
  - `DATABASE_URL`: `jdbc:postgresql://<rds-endpoint>:5432/readingsanctuary`
  - `DATABASE_USERNAME`: `readingsanctuary_user`
  - `DATABASE_PASSWORD`: Secret fetched from AWS Secrets Manager
  - `AWS_REGION`: `us-east-1`
  - `AWS_S3_BUCKET`: `reading-sanctuary-production-assets`
  - `READING_SANCTUARY_JWT_SECRET`: 256-bit base64 secret from AWS Secrets Manager

### 3.2 Application Load Balancer (ALB)
- **Listener**: HTTPS Port 443 with ACM SSL Certificate
- **Target Group**: HTTP Port 8080
- **Health Check Path**: `/actuator/health`
- **Health Check Intervals**: 30 seconds interval, 5 seconds timeout, 2 healthy thresholds
