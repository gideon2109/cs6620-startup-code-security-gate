#!/bin/bash

echo "🔄 Updating frontend with latest API Gateway URL..."

# Get API URL from Terraform
cd terraform
API_URL=$(terraform output -raw api_gateway_url)
echo "📡 API Gateway URL: $API_URL"

# Update frontend .env
cd ../frontend
echo "REACT_APP_API_URL=$API_URL" > .env
echo "✅ .env file updated"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    npm install
fi

# Rebuild frontend
echo "🏗️ Building frontend..."
npm run build

# Deploy to S3
echo "🚀 Deploying frontend to S3..."
aws s3 sync build/ s3://group9-sast-frontend/ --region us-east-1 --delete

# Fix S3 routing
aws s3 website s3://group9-sast-frontend --index-document index.html --error-document index.html

echo "✅ Frontend updated successfully!"
echo "🌐 Frontend URL: http://group9-sast-frontend.s3-website-us-east-1.amazonaws.com"
