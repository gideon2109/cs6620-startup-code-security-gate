import { scanCode } from './scanner.js';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

const s3 = new S3Client({});
const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);
const sns = new SNSClient({});

const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME;
const DYNAMODB_TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

const standardHeaders = {
  'Content-Type': 'application/json',
};

export const handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    // ── Route: GET /status (Frontend Polling) ──────────────────────
    const method = event.requestContext?.http?.method || event.httpMethod;
    const path = event.requestContext?.http?.path || event.rawPath || event.path;

    if (method === 'GET' && (path === '/status' || path?.endsWith('/status'))) {
      const scanId = event.queryStringParameters?.scanId;
      
      if (!scanId) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: 'Missing scanId parameter' })
        };
      }

      const result = await ddbClient.send(new GetItemCommand({
        TableName: DYNAMODB_TABLE_NAME,
        Key: { scanId: { S: scanId } }
      }));

      if (!result.Item) {
        return {
          statusCode: 404,
          body: JSON.stringify({ error: 'Scan job not found or still processing' })
        };
      }

      return {
        statusCode: 200,
        body: JSON.stringify({
          status: result.Item.status?.S || 'COMPLETED',
          scanId: scanId,
          filename: result.Item.filename?.S || 'unknown.js',
          scannedAt: result.Item.scannedAt?.S,
          summary: {
            high: parseInt(result.Item.highCount?.N || '0'),
            medium: parseInt(result.Item.mediumCount?.N || '0'),
            low: parseInt(result.Item.lowCount?.N || '0'),
            totalVulnerabilities: parseInt(result.Item.totalCount?.N || '0')
          },
          s3Key: result.Item.s3Key?.S
        })
      };
    }

    // ── Unpack Incoming Request Body ──────────────────────────────
    let body = {};
    if (event.Records && event.Records[0]?.body) {
      body = JSON.parse(event.Records[0].body);
    } else if (event.body) {
      body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } else {
      body = event;
    }

    // ── Route: Email Full Report via SNS ──────────────────────────
    if (body.action === 'email_report') {
      return await handleEmailReport(body);
    }

    // ── Route: Standard/Async Scan ────────────────────────────────
    const { code, filename = 'untitled.js' } = body;

    if (!code) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'No code provided for static analysis' })
      };
    }

    const results = scanCode(code, filename);
    const scanId = crypto.randomUUID();
    const scannedAt = new Date().toISOString();

    const summary = {
      totalVulnerabilities: results.length,
      high: results.filter(v => v.severity === 'HIGH').length,
      medium: results.filter(v => v.severity === 'MEDIUM').length,
      low: results.filter(v => v.severity === 'LOW').length
    };

    const report = {
      success: true,
      scanId,
      filename,
      scannedAt,
      summary,
      vulnerabilities: results
    };

    // Store full report document in S3
    let s3Key = null;
    if (S3_BUCKET_NAME) {
      s3Key = `reports/${scanId}.json`;
      await s3.send(new PutObjectCommand({
        Bucket: S3_BUCKET_NAME,
        Key: s3Key,
        Body: JSON.stringify(report),
        ContentType: 'application/json'
      }));
    }

    // Store tracking record in DynamoDB with status tracking
    if (DYNAMODB_TABLE_NAME) {
      const ttl = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 30-Day TTL
      await docClient.send(new PutCommand({
        TableName: DYNAMODB_TABLE_NAME,
        Item: {
          scanId,
          status: 'COMPLETED',
          scannedAt,
          filename,
          highCount: summary.high,
          mediumCount: summary.medium,
          lowCount: summary.low,
          totalCount: summary.totalVulnerabilities,
          s3Key,
          ttl
        }
      }));
    }

    // Alert team via SNS for High vulnerabilities
   // if (SNS_TOPIC_ARN && summary.high > 0) {
   //   const highFindings = results
   //     .filter(v => v.severity === 'HIGH')
     //   .map(v => `  • [Line ${v.line}] ${v.name}: ${v.message}`)
    //    .join('\n');

    //  await sns.send(new PublishCommand({
     //   TopicArn: SNS_TOPIC_ARN,
     //   Subject: `🚨 SAST Alert: ${summary.high} HIGH Findings in ${filename}`,
     //   Message: [
      //    `SAST Scanner – Critical Vulnerability Alert`,
      //    `─────────────────────────────────────────`,
      //    `Scan ID   : ${scanId}`,
      //    `File      : ${filename}`,
      //    ``,
      //    `HIGH Severity Findings`,
      //    highFindings
      //  ].join('\n')
     // }));
    // }

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        scanId,
        scannedAt,
        filename,
        summary,
        vulnerabilities: results,
        s3Key
      })
    };

  } catch (error) {
    console.error('Handler execution failure:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Scan failed', message: error.message })
    };
  }
};
async function handleEmailReport(body) {
  const { scanId, filename, scannedAt, summary, vulnerabilities, s3Key } = body;

  if (!SNS_TOPIC_ARN) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'SNS topic component not set' })
    };
  }

  // 1. Group vulnerabilities cleanly
  const grouped = { HIGH: [], MEDIUM: [], LOW: [] };
  (vulnerabilities || []).forEach(v => {
    const sev = (v.severity || 'LOW').toUpperCase();
    if (grouped[sev]) grouped[sev].push(v);
  });

  // 2. Compute visual proportions for the ASCII Bar Chart
  const totalCounts = [summary.high || 0, summary.medium || 0, summary.low || 0];
  const maxCount = Math.max(...totalCounts, 1);
  const maxBarLength = 25; // Length of chart bars

  const generateASCIIBar = (count) => {
    const currentCount = count || 0;
    const filledLength = Math.round((currentCount / maxCount) * maxBarLength);
    const emptyLength = Math.max(0, maxBarLength - filledLength);
    return '█'.repeat(filledLength) + '░'.repeat(emptyLength);
  };

  const highBar   = generateASCIIBar(summary.high);
  const mediumBar = generateASCIIBar(summary.medium);
  const lowBar    = generateASCIIBar(summary.low);

  // 3. Format individual line reports inside categories
  const formatFindings = (findings) => {
    if (!findings || findings.length === 0) return '   (No vulnerabilities identified in this tier)\n';
    return findings
      .map((v, i) => `   [${i + 1}] Line ${v.line} | ${v.name}\n       Description: ${v.message}`)
      .join('\n\n');
  };

  // 4. layout structure
  const emailBody = [
    `=============================================================`,
    ` 🛡️  SECURE PIPELINE ANALYSIS REPORT — GROUP 9`,
    `=============================================================`,
    ` SUMMARY METRICS`,
    ` ────────────────────────────────────────────────────────────`,
    ` Target File   : ${filename.toUpperCase()}`,
    ` Scan ID       : ${scanId}`,
    ` Timestamp     : ${scannedAt}`,
    ` S3 Report Key : ${s3Key || 'N/A'}`,
    ` Total Flaws   : ${summary.totalVulnerabilities || summary.high + summary.medium + summary.low} Findings`,
    ``,
    ` 📊 SEVERITY DISTRIBUTION CHART`,
    ` ────────────────────────────────────────────────────────────`,
    ` HIGH   [${String(summary.high || 0).padStart(2, ' ')}] | ${highBar}`,
    ` MEDIUM [${String(summary.medium || 0).padStart(2, ' ')}] | ${mediumBar}`,
    ` LOW    [${String(summary.low || 0).padStart(2, ' ')}] | ${lowBar}`,
    ``,
    `=============================================================`,
    ` DETAILED FINDINGS LOG`,
    `=============================================================`,
    ``,
    ` 🚨 HIGH SEVERITY RISK FOUND`,
    ` ────────────────────────────────────────────────────────────`,
    formatFindings(grouped.HIGH),
    ``,
    ` ⚠️ MEDIUM SEVERITY RISK FOUND`,
    ` ────────────────────────────────────────────────────────────`,
    formatFindings(grouped.MEDIUM),
    ``,
    ` ℹ️ LOW SEVERITY RISK FOUND`,
    ` ────────────────────────────────────────────────────────────`,
    formatFindings(grouped.LOW),
    ``,
    ` ────────────────────────────────────────────────────────────`,
    ` End of Security Report | Startup Code Security Gate — Group 9`,
    `=============================================================`
  ].join('\n');

  // 5. Send out the clean layout block via SNS
  await sns.send(new PublishCommand({
    TopicArn: SNS_TOPIC_ARN,
    Subject: `🛡️ SAST Security Summary: ${summary.totalVulnerabilities || summary.high + summary.medium + summary.low} Issues Found in ${filename}`,
    Message: emailBody
  }));

  return {
    statusCode: 200,
    body: JSON.stringify({ success: true, message: 'Structured report delivered via SNS' })
  };
}