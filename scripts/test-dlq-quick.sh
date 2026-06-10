#!/bin/bash

echo "=========================================="
echo "   QUICK DLQ TEST"
echo "=========================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd ~/go-rest-api/cloud/cs6620/sast/backend/terraform

API_URL=$(terraform output -raw api_gateway_url)
echo -e "${GREEN}[OK] API URL: $API_URL${NC}"

DLQ_URL=$(aws sqs get-queue-url \
  --queue-name sast-scan-dlq \
  --region us-east-1 \
  --query 'QueueUrl' \
  --output text)

echo -e "${YELLOW}Clearing DLQ...${NC}"
aws sqs purge-queue --queue-url "$DLQ_URL" --region us-east-1 2>/dev/null || true
sleep 20

echo -e "${YELLOW}Sending invalid requests...${NC}"
for i in 1 2 3; do
  curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"invalid": "payload"}' > /dev/null
  echo "  Request $i sent"
  sleep 1
done

echo -e "${YELLOW}Waiting for failed messages to reach DLQ...${NC}"

COUNT=0
for i in 1 2 3 4 5 6 7 8 9; do
  COUNT=$(aws sqs get-queue-attributes \
    --queue-url "$DLQ_URL" \
    --attribute-names ApproximateNumberOfMessages \
    --region us-east-1 \
    --query 'Attributes.ApproximateNumberOfMessages' \
    --output text)

  echo "  Check $i: DLQ messages = $COUNT"

  if [ "$COUNT" != "None" ] && [ "$COUNT" -gt 0 ]; then
    break
  fi

  sleep 10
done

echo ""
if [ "$COUNT" != "None" ] && [ "$COUNT" -gt 0 ]; then
  echo -e "${GREEN}[PASS] DLQ has $COUNT message(s)${NC}"
else
  echo -e "${RED}[FAIL] No messages in DLQ yet${NC}"
  echo "Try waiting another 30-60 seconds, then check again."
fi

echo ""
echo "Alarm check:"
aws cloudwatch describe-alarms \
  --alarm-names sast-dlq-messages-alarm \
  --region us-east-1 \
  --query 'MetricAlarms[0].{State:StateValue,Reason:StateReason}' \
  --output table

echo ""
echo -e "${GREEN}Test complete.${NC}"
