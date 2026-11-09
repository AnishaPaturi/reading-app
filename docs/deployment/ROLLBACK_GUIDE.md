# Reading Sanctuary — Production Rollback Guide

This runbook describes the procedure to safely roll back the Reading Sanctuary production environment in the event of a critical regression, deployment failure, or service degradation.

---

## 1. Quick Decision Matrix

| Incident Type | Recommended Rollback Action | Estimated Recovery Time |
|---|---|---|
| Backend bug / 500 errors / Crash loop | Roll back ECS Task Definition to previous revision | 2–5 minutes |
| Frontend UI regression / broken navigation | Revert S3 Web build & invalidate CloudFront cache | 2–3 minutes |
| Database migration failure | Restore from pre-deployment RDS snapshot | 10–25 minutes |
| S3 upload permission failure | Roll back IAM policy / S3 CORS configuration | 1–2 minutes |

---

## 2. Backend ECS Rollback

If a newly deployed container image introduces errors:

### Step 1: Identify Previous Task Definition Revision
```bash
aws ecs list-task-definitions --family-prefix reading-sanctuary-api --sort DESC
```
*(e.g., current is `reading-sanctuary-api:42`, previous stable is `reading-sanctuary-api:41`)*

### Step 2: Update ECS Service to Previous Revision
```bash
aws ecs update-service \
  --cluster reading-sanctuary-prod \
  --service api-service \
  --task-definition reading-sanctuary-api:41 \
  --force-new-deployment
```

### Step 3: Monitor Rollback
```bash
aws ecs wait services-stable \
  --cluster reading-sanctuary-prod \
  --services api-service
```
Verify service health:
```bash
curl -I https://api.readingsanctuary.com/actuator/health
```

---

## 3. Frontend Web Rollback

If a newly deployed Flutter web bundle contains critical rendering or routing defects:

### Step 1: Redeploy Previous Stable Web Artifact
```bash
# If using S3 versioning:
aws s3 sync previous_build/web/ s3://reading-sanctuary-web-hosting/ --delete
```

### Step 2: Create Immediate CloudFront Invalidation
```bash
aws cloudfront create-invalidation \
  --distribution-id <CLOUDFRONT_DIST_ID> \
  --paths "/*"
```

---

## 4. Database Migration Safety Rules

1. **Non-Destructive Migrations (Expand/Contract)**:
   - Migrations must never drop active columns or tables in the same release that deprecates them.
   - All migrations must remain backward-compatible with the immediately preceding application version.
2. **Flyway Repair**:
   - If a migration script failed midway, resolve the error in PostgreSQL and run `./mvnw flyway:repair` to synchronize schema history metadata.
3. **Catastrophic Failure**:
   - If a migration corrupted persistent data, refer to [Database Backup & Recovery Runbook](file:///C:/Users/anish/OneDrive/College/Projects/reading-app/docs/deployment/DATABASE_BACKUP.md) to restore from the pre-deployment snapshot.
