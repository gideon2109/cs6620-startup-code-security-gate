#!/bin/bash

# DLQ Simulation Script for Startup Code Security Gate
# Tests: API Gateway -> SQS -> Lambda Failure -> Retry -> DLQ -> CloudWatch Alarm -> SNS

set -e

echo "=========================================="
echo "   DLQ SIMULATION TEST"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="us-east-1"
QUEUE_NAME="sast-scan-dlq"
ALARM_NAME="sast-dlq-messages-alarm"
REQUEST_COUNT=5

cd ~/go-rest-api/cloud/cs6620/sast/backend/terraform

API_URL=$(terraform output -raw api_gateway_url)
echo -e "${GREEN}[OK] API Gateway URL: $API_URL${NC}"

DLQ_URL=$(aws sqs get-queue-url \
  --queue-name "$QUEUE_NAME" \
  --region "$REGION" \
  --query 'QueueUrl' \
  --output text)
echo -e "${GREEN}[OK] DLQ URL: $DLQ_URL${NC}"

echo ""
echo -e "${YELLOW}Step 1: Purging DLQ before test...${NC}"
aws sqs purge-queue --queue-url "$DLQ_URL" --region "$REGION" || true
echo -e "${GREEN}[OK] Purge requested${NC}"
echo "Waiting 60 seconds because SQS purge can take time..."
sleep 60

echo ""
echo -e "${YELLOW}Step 2: Initial CloudWatch Alarm state...${NC}"
INITIAL_STATE=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --region "$REGION" \
  --query 'MetricAlarms[0].StateValue' \
  --output text)
echo "Initial state: $INITIAL_STATE"

echo ""
echo -e "${YELLOW}Step 3: Sending invalid requests...${NC}"
for i in $(seq 1 "$REQUEST_COUNT"); do
  echo -n "Request $i... "
  RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"invalid": "payload"}')

  if echo "$RESPONSE" | grep -q "MessageId"; then
    echo -e "${GREEN}queued${NC}"
  else
    echo -e "${RED}failed${NC}"
    echo "$RESPONSE"
  fi
  sleep 1
done

echo ""
echo -e "${YELLOW}Step 4: Waiting for Lambda failures and SQS redrive...${NC}"
echo "Waiting 2 minutes..."
sleep 120

echo ""
echo -e "${YELLOW}Step 5: Checking DLQ message count...${NC}"
DLQ_COUNT=$(aws sqs get-queue-attributes \
  --queue-url "$DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages \
  --region "$REGION" \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text)

echo "Messages visible in DLQ: $DLQ_COUNT"

echo ""
echo -e "${YELLOW}Step 6: Showing one DLQ message body...${NC}"
aws sqs receive-message \
  --queue-url "$DLQ_URL" \
  --region "$REGION" \
  --max-number-of-messages 1 \
  --visibility-timeout 5 \
  --query 'Messages[0].Body' \
  --output text || true

echo ""
echo -e "${YELLOW}Step 7: Checking CloudWatch alarm state...${NC}"
echo "Waiting 60 seconds for CloudWatch metric evaluation..."
sleep 60

ALARM_STATE=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --region "$REGION" \
  --query 'MetricAlarms[0].StateValue' \
  --output text)

ALARM_REASON=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --region "$REGION" \
  --query 'MetricAlarms[0].StateReason' \
  --output text)

if [ "$ALARM_STATE" = "ALARM" ]; then
  echo -e "${GREEN}[OK] CloudWatch Alarm is ALARM${NC}"
else
  echo -e "${YELLOW}[WARN] CloudWatch Alarm state: $ALARM_STATE${NC}"
fi

echo "Reason: $ALARM_REASON"

echo ""
echo "=========================================="
echo "   TEST SUMMARY"
echo "=========================================="
echo "Invalid requests sent: $REQUEST_COUNT"
echo "Messages visible in DLQ: $DLQ_COUNT"
echo "CloudWatch Alarm: $ALARM_STATE"
echo "SNS Email: Check your inbox"
echo "=========================================="

echo ""
read -p "Delete messages from DLQ now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  aws sqs purge-queue --queue-url "$DLQ_URL" --region "$REGION"
  echo -e "${GREEN}[OK] DLQ purge requested${NC}"
fi

echo ""
echo -e "${GREEN}Test complete.${NC}"
