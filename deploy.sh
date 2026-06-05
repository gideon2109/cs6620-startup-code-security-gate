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
# Step 2: Deploy ECR Repository first (image must exist before Lambda)
# ==============================================================================
echo "==> Step 2: Deploying ECR Repository..."
terraform apply -target=module.ecr -auto-approve

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
# Step 5: Build the Docker image (from project root where Dockerfile lives)
# ==============================================================================
echo "==> Step 5: Building Docker image..."
cd "$DIR"
docker build --provenance=false --platform linux/amd64 -t "$ECR_URL:latest" .

# ==============================================================================
# Step 6: Push the Docker image to ECR
# ==============================================================================
echo "==> Step 6: Pushing Docker image to ECR..."
docker push "$ECR_URL:latest"

# ==============================================================================
# Step 7: Deploy all remaining resources (S3, DynamoDB, Lambda, Monitoring)
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
