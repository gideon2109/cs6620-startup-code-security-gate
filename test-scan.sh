#!/bin/bash

# Navigate to the terraform directory to read outputs
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$DIR/terraform"

# Get Lambda Function URL from Terraform
cd "$TERRAFORM_DIR"
API_URL=$(terraform output -raw lambda_function_url 2>/dev/null || echo "")

if [ -z "$API_URL" ] || [[ "$API_URL" == *"No outputs"* ]]; then
  echo "Error: Could not retrieve lambda_function_url. Please run deploy.sh first."
  exit 1
fi

echo "==> Target Endpoint: $API_URL"
echo "==> Sending test payload with three vulnerabilities:"
echo "    1. Hardcoded Stripe secret key"
: "    2. SQL injection query concatenation"
: "    3. Insecure eval() function usage"
echo "--------------------------------------------------------"

PAYLOAD='{
  "filename": "demo-vulnerable.js",
  "code": "const stripe_key = \"sk_live_51NzABC1234567890abcdef1234567890\";\nconst sql = \"SELECT * FROM users WHERE id = \" + req.query.id;\neval(sql);"
}'

# Execute request
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "==> Response from AWS Lambda Function URL:"
echo "$RESPONSE" | python -m json.tool 2>/dev/null || echo "$RESPONSE"
echo "--------------------------------------------------------"
