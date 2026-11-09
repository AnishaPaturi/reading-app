# Reading Sanctuary — Environment Variables Reference

This document serves as the master catalog of all configuration parameters and environment variables utilized across the Reading Sanctuary platform.

---

## 1. Backend Environment Variables (Spring Boot)

| Variable Name | Required | Default (Dev) | Production Recommendation | Description |
|---|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | Yes | `default` | `prod` | Activates production configuration profile (`application-prod.properties`). |
| `DATABASE_URL` | Yes | `jdbc:postgresql://localhost:5432/readingsanctuary` | `jdbc:postgresql://<rds-host>:5432/readingsanctuary` | JDBC connection string for PostgreSQL database. |
| `DATABASE_USERNAME` | Yes | `postgres` | `readingsanctuary_user` | Database user name. |
| `DATABASE_PASSWORD` | Yes | `postgres` | *Secure password from Secrets Manager* | Database user password. |
| `READING_SANCTUARY_JWT_SECRET` | Yes | *Dev HMAC secret* | *256-bit cryptographically random base64 string* | Secret key for signing and verifying JWT tokens. |
| `READING_SANCTUARY_JWT_EXPIRATION_MS` | No | `86400000` (24h) | `86400000` | JWT expiration duration in milliseconds. |
| `AWS_REGION` | Yes | `us-east-1` | `us-east-1` | AWS region hosting S3 bucket and ECS services. |
| `AWS_S3_BUCKET` | Yes | `reading-sanctuary-dev` | `reading-sanctuary-production-assets` | Target S3 bucket for ebooks, audiobooks, and documents. |
| `AWS_ACCESS_KEY_ID` | Dev only | *None (uses IAM role)* | *Omitted (uses ECS Task Execution Role)* | Optional AWS access key for local development. |
| `AWS_SECRET_ACCESS_KEY` | Dev only | *None (uses IAM role)* | *Omitted (uses ECS Task Execution Role)* | Optional AWS secret key for local development. |
| `CORS_ALLOWED_ORIGINS` | No | `*` | `https://readingsanctuary.com,https://app.readingsanctuary.com` | Comma-separated list of permitted browser origins. |
| `SERVER_PORT` | No | `8080` | `8080` | HTTP port on which the Spring Boot server listens. |

---

## 2. Frontend Configuration (`--dart-define`)

| Build Flag | Required | Default | Example | Description |
|---|---|---|---|---|
| `API_BASE_URL` | No | Platform auto-detect (`http://localhost:8080/api` or `10.0.2.2`) | `https://api.readingsanctuary.com/api` | Base URL for REST API calls. Injected during `flutter run` or `flutter build`. |

---

## 3. GitHub Actions CI/CD Secrets

Configured under GitHub Repository Settings -> Secrets and Variables -> Actions:

| Secret Name | Required | Description |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Yes (for deployment) | AWS IAM credentials with permissions to push to ECR and update ECS. |
| `AWS_SECRET_ACCESS_KEY` | Yes (for deployment) | Matching AWS secret key for deployment IAM user. |
| `AWS_ACCOUNT_ID` | Yes (for deployment) | AWS 12-digit account number for ECR repository URL. |
| `AWS_REGION` | Yes (for deployment) | Target deployment region (e.g. `us-east-1`). |
| `CLOUDFRONT_DISTRIBUTION_ID` | Yes (for deployment) | CloudFront CDN distribution ID for web cache invalidations. |
| `S3_WEB_BUCKET` | Yes (for deployment) | Target S3 bucket name for hosting Flutter web static assets. |
