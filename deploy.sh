#!/bin/bash
set -e

# Navigate to the script's directory (project root)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

TERRAFORM_DIR="$DIR/terraform"

# ==============================================================================
# Step 1: Initialize Terraform
# ==============================================================================
echo "==> Step 1: Initializing Terraform..."
cd "$TERRAFORM_DIR"
terraform init

# ==============================================================================
# Step 2: Deploy ECR + VPC first (image must exist before Lambda; VPC must exist too)
# ==============================================================================
echo "==> Step 2: Deploying ECR Repository and VPC..."
terraform apply -target=module.ecr -target=module.vpc -auto-approve

# ==============================================================================
# Step 3: Get ECR Repository URL from Terraform output
# ==============================================================================
ECR_URL=$(terraform output -raw ecr_repository_url)
echo "==> ECR Repository URL: $ECR_URL"

# Extract AWS region from ECR URL
AWS_REGION=$(echo "$ECR_URL" | cut -d'.' -f4)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
fi
echo "==> Detected AWS Region: $AWS_REGION"

# ==============================================================================
# Step 4: Authenticate Docker to AWS ECR
# ==============================================================================
echo "==> Step 4: Authenticating Docker to AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# ==============================================================================
# Step 5: Build the Docker image
# IMPORTANT: Use DOCKER_BUILDKIT=0 to avoid OCI Image Index format that
# Lambda rejects. Lambda requires Docker V2 Schema 2 manifest.
# ==============================================================================
echo "==> Step 5: Building Docker image (Docker V2 format for Lambda)..."
cd "$DIR"

# Force legacy Docker build (no Buildx) to guarantee Docker V2 Schema 2 manifest
DOCKER_BUILDKIT=0 docker build --platform linux/amd64 -t sast-scanner-local .

# Tag for ECR
docker tag sast-scanner-local:latest "$ECR_URL:latest"

# ==============================================================================
# Step 6: Push the Docker image to ECR
# ==============================================================================
echo "==> Step 6: Pushing Docker image to ECR..."
docker push "$ECR_URL:latest"

# Verify the pushed manifest format
echo "==> Verifying image manifest format..."
aws ecr batch-get-image \
    --repository-name startup-code-security-gate-repo \
    --image-ids imageTag=latest \
    --region "$AWS_REGION" \
    --query 'images[0].imageManifest' \
    --output text | head -c 200
echo ""

# ==============================================================================
# Step 7: Deploy all remaining resources (S3, DynamoDB, Lambda, Monitoring, API GW)
# ==============================================================================
echo "==> Step 7: Deploying complete serverless stack..."
cd "$TERRAFORM_DIR"
terraform apply -auto-approve

echo ""
echo "=========================================================="
echo "       DEPLOYMENT COMPLETED SUCCESSFULLY                  "
echo "=========================================================="
echo ""
terraform output
echo ""

# ==============================================================================
# Step 8: Update Frontend with latest API Gateway URL
# ==============================================================================
echo "==> Step 8: Updating frontend with latest API Gateway URL..."

# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)
echo "==> API Gateway URL: $API_URL"

# Update frontend .env
cd "$DIR/frontend"
echo "REACT_APP_API_URL=$API_URL" > .env
echo "==> .env file updated"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "==> Installing frontend dependencies..."
    npm install
fi

# Rebuild frontend
echo "==> Building frontend..."
npm run build

# Deploy to S3
echo "==> Deploying frontend to S3..."
aws s3 sync build/ s3://gideon-sast-frontend/ --region us-east-1 --delete

echo ""
echo "=========================================================="
echo "       FRONTEND UPDATED SUCCESSFULLY                     "
echo "=========================================================="
echo "🌐 Frontend URL: http://gideon-sast-frontend.s3-website-us-east-1.amazonaws.com"
echo "=========================================================="

# ==============================================================================
# Step 8: Auto-update frontend
# ==============================================================================
echo ""
echo "==> Step 8: Updating frontend automatically..."

cd "$DIR/terraform"
LAMBDA_URL=$(terraform output -raw lambda_function_url)
echo "==> Lambda URL: $LAMBDA_URL"

cd "$DIR/frontend"
echo "REACT_APP_API_URL=$LAMBDA_URL" > .env
echo "==> .env file updated"

npm run build
echo "==> Frontend built"

# Create bucket if needed
aws s3 mb s3://group9-sast-frontend --region us-east-1 2>/dev/null || true
aws s3 website s3://group9-sast-frontend --index-document index.html --error-document index.html

# Deploy frontend
aws s3 sync build/ s3://group9-sast-frontend/ --region us-east-1 --delete

echo "==> Frontend deployed"
echo "🌐 Frontend URL: http://group9-sast-frontend.s3-website-us-east-1.amazonaws.com"
