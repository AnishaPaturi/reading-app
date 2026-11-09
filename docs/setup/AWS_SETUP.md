# Reading Sanctuary — AWS Cloud Infrastructure Setup

## 1. AWS S3 Bucket Setup (Private Document Storage)

1. Open AWS S3 Console.
2. Click **Create bucket**.
   - Bucket name: `reading-sanctuary-storage-production` (globally unique).
   - Region: Same region as your database/compute (e.g., `us-east-1`).
   - Block *all* public access: **Enabled** (all checkmarks checked).
   - Bucket Versioning: **Enabled**.
   - Default encryption: **SSE-S3** (AES-256).
   - Object Ownership: **Bucket owner enforced**.
3. CORS Configuration for Direct Presigned Uploads/Downloads:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedOrigins": ["https://readingsanctuary.com", "http://localhost:*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

---

## 2. IAM Policy for Backend API

Attach this least-privilege policy to your backend's IAM Role / User:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ObjectOperations",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:HeadObject"
      ],
      "Resource": "arn:aws:s3:::reading-sanctuary-storage-production/*"
    },
    {
      "Sid": "S3BucketListing",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::reading-sanctuary-storage-production"
    }
  ]
}
```

---

## 3. Amazon RDS PostgreSQL Database

- **Engine**: PostgreSQL 16+
- **Instance**: `db.t4g.micro` (or larger for production).
- **Storage**: 20 GB gp3 with storage autoscaling enabled.
- **Networking**: Private VPC subnets, Inbound Port 5432 restricted strictly to the ECS/Backend Security Group.
- **Backups**: Automated daily snapshots with 7-day retention and Point-In-Time-Recovery (PITR).
