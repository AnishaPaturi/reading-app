# Reading Sanctuary — Production Deployment Guide

## 1. Production Architecture Overview

The production deployment of Reading Sanctuary on AWS utilizes managed serverless and container infrastructure:

```mermaid
graph LR
    subgraph "Clients"
        WebClient[Web Browser]
        MobileClient[Android / iOS App]
    end

    subgraph "CDN & Edge"
        CF[CloudFront CDN]
        ALB[Application Load Balancer]
    end

    subgraph "Compute & Storage"
        ECS[ECS Fargate Tasks (Spring Boot API)]
        RDS[(Amazon RDS PostgreSQL)]
        S3Files[(Private S3 Asset Bucket)]
        S3Web[(S3 Web Hosting)]
    end

    WebClient --> CF --> S3Web
    WebClient --> ALB
    MobileClient --> ALB
    ALB --> ECS
    ECS --> RDS
    ECS -. Presigned URLs .-> S3Files
    MobileClient -. Direct Download/Upload .-> S3Files
```

---

## 2. Infrastructure Deployment Steps

### 2.1 Backend Deployment to Amazon ECS Fargate

#### Step 1: Push Container to Amazon ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com

docker build -t reading-sanctuary-api:latest backend/reading-sanctuary-api
docker tag reading-sanctuary-api:latest <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/reading-sanctuary-api:v1.0.0
docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/reading-sanctuary-api:v1.0.0
```

#### Step 2: Register ECS Task Definition
Define container with:
- Image: `<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/reading-sanctuary-api:v1.0.0`
- Essential: true
- Port mapping: 8080 (HTTP)
- Log configuration: `awslogs` directing to CloudWatch `/ecs/reading-sanctuary-api`
- Environment variables: Set from AWS Secrets Manager and Parameter Store.

#### Step 3: Update ECS Service
```bash
aws ecs update-service \
  --cluster reading-sanctuary-prod \
  --service api-service \
  --force-new-deployment
```

---

### 2.2 Frontend Web Deployment to CloudFront & S3

#### Step 1: Build Production Web Bundle
```bash
cd frontend/reading_sanctuary_app
flutter build web \
  --release \
  --pwa-strategy=offline-first \
  --dart-define=API_BASE_URL=https://api.readingsanctuary.com/api
```

#### Step 2: Sync to S3 Hosting Bucket
```bash
aws s3 sync build/web/ s3://reading-sanctuary-web-hosting/ --delete
```

#### Step 3: Invalidate CloudFront Edge Caches
```bash
aws cloudfront create-invalidation \
  --distribution-id <CLOUDFRONT_DIST_ID> \
  --paths "/*"
```

---

## 3. Automated CI/CD Deployments

Deployments to production are automated via GitHub Actions:
- Pipeline file: `.github/workflows/production-deploy.yml`
- Triggered on git release tag push (`v*.*.*`) or manual workflow dispatch.
- Executes:
  1. Full backend and frontend test suites.
  2. Docker build and ECR push.
  3. ECS Fargate service update with rolling deployment (zero-downtime).
  4. Flutter web build and S3 sync with CloudFront cache invalidation.
