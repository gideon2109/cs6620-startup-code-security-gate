#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$DIR/terraform"

cd "$TERRAFORM_DIR"
LAMBDA_URL=$(terraform output -raw lambda_function_url 2>/dev/null || echo "")

if [ -z "$LAMBDA_URL" ]; then
  echo "Error: Could not retrieve lambda_function_url. Run deploy.sh first."
  exit 1
fi

echo "==> Target Endpoint (Lambda URL): $LAMBDA_URL"
echo "==> Sending test payload with vulnerabilities:"
echo "    1. Hardcoded Stripe secret key"
echo "    2. SQL injection query concatenation"
echo "    3. Insecure eval() function usage"
echo "--------------------------------------------------------"

PAYLOAD='{
  "filename": "demo-vulnerable.js",
  "code": "const stripe_key = \"sk_live_51NzABC1234567890abcdef1234567890\";\nconst sql = \"SELECT * FROM users WHERE id = \" + req.query.id;\neval(sql);"
}'

RESPONSE=$(curl -s -X POST "$LAMBDA_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "==> Response from Lambda URL (JSON):"
echo "$RESPONSE" | python -m json.tool 2>/dev/null || echo "$RESPONSE"
echo "--------------------------------------------------------"
