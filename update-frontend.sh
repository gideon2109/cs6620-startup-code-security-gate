#!/bin/bash
set -e

echo "🔄 Updating frontend with latest API Gateway URL..."

# Get API URL from Terraform
cd terraform
API_URL=$(terraform output -raw api_gateway_url)
echo "📡 API Gateway URL: $API_URL"

# Update frontend .env
cd ../frontend
echo "REACT_APP_API_URL=$API_URL" > .env
echo "✅ .env file updated"

# Rebuild frontend
echo "📦 Building frontend..."
npm run build

# Deploy to S3
echo "🚀 Deploying to S3..."
aws s3 sync build/ s3://gideon-sast-frontend/ --region us-east-1 --delete

echo "✅ Frontend updated successfully!"
echo "🌐 Test at: http://gideon-sast-frontend.s3-website-us-east-1.amazonaws.com"
