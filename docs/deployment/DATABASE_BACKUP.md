# Reading Sanctuary — Database Backup & Disaster Recovery Runbook

## 1. Overview & Service Level Objectives

The database contains the canonical user library, reading positions, annotations, and sync audit logs. The backup strategy ensures high availability and business continuity:

- **Recovery Point Objective (RPO)**: < 5 minutes (via automated WAL log streaming).
- **Recovery Time Objective (RTO)**: < 30 minutes (time to spin up restored instance and redirect traffic).

---

## 2. Amazon RDS Automated Backups & PITR

### 2.1 Automated Snapshots & Transaction Logs
- **Automated Backup Window**: Daily at 03:00 UTC during low-traffic periods.
- **Retention Period**: 7 days (standard) or 30 days (production compliance).
- **Point-In-Time-Recovery (PITR)**: Amazon RDS continuously uploads PostgreSQL Write-Ahead Logs (WAL) to Amazon S3. This allows restoring the database to any specific second within the retention window.

### 2.2 Pre-Deployment Manual Snapshot
Always create a manual snapshot prior to deploying database schema migrations:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier reading-sanctuary-prod-db \
  --db-snapshot-identifier pre-deployment-v1-0-0-$(date +%Y%m%d%H%M%S)
```

---

## 3. Disaster Recovery Restoration Procedure

### 3.1 Restoring to a Point In Time (PITR)
To recover from an accidental data corruption or botched migration:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier reading-sanctuary-prod-db \
  --target-db-instance-identifier reading-sanctuary-restored-db \
  --restore-time 2026-11-09T08:30:00Z \
  --db-subnet-group-name reading-sanctuary-db-subnet-group \
  --vpc-security-group-ids sg-0123456789abcdef0
```

### 3.2 Updating ECS Connection Strings
Once the restored instance is available:
1. Update the `DATABASE_URL` parameter in AWS Systems Manager Parameter Store or AWS Secrets Manager to point to `reading-sanctuary-restored-db.xxx.rds.amazonaws.com`.
2. Trigger an ECS rolling restart:
   ```bash
   aws ecs update-service \
     --cluster reading-sanctuary-prod \
     --service api-service \
     --force-new-deployment
   ```

---

## 4. Local / Self-Hosted Backup & Restore

### 4.1 Manual Logical Backup (`pg_dump`)
```bash
pg_dump -h localhost -p 5432 -U postgres -F c -b -v -f reading_sanctuary_backup.dump readingsanctuary
```

### 4.2 Logical Restore (`pg_restore`)
```bash
# Create target database if needed
createdb -h localhost -p 5432 -U postgres readingsanctuary_restored

# Restore database schema and data
pg_restore -h localhost -p 5432 -U postgres -d readingsanctuary_restored -v reading_sanctuary_backup.dump
```
