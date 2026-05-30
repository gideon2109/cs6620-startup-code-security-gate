# Startup Code Security Gate

**CS6620 Cloud Computing | Group 9 | Spring 2026**

A serverless SAST scanner for JavaScript/Node.js applications.

## Team & Work Division

| Role | Owner | Components |
|------|-------|------------|
| Infrastructure + Backend | Gideon | DynamoDB, Terraform, Lambda, API Gateway |
| Frontend + UI | Rahul | S3 static website, upload form, result display |

## Architecture

User → API Gateway → Lambda → S3 (reports) + DynamoDB (metadata) → CloudWatch

## Deployment

```bash
./deploy.sh
```

## Cleanup

```bash
terraform destroy
```
