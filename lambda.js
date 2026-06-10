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
  'Content-Type': 'application/json'
};

export const handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  // ──────────────────────────────────────────────────────────────────────────
  // ── GET /status (Frontend Polling) ────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────
  if (event.httpMethod === 'GET' && event.rawPath === '/status') {
    const scanId = event.queryStringParameters?.scanId;
    
    if (!scanId) {
      return {
        statusCode: 400,
        headers: standardHeaders,
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
        headers: standardHeaders,
        body: JSON.stringify({ error: 'Scan ID not found' })
      };
    }

    return {
      statusCode: 200,
      headers: standardHeaders,
      body: JSON.stringify({
        status: result.Item.status?.S || 'COMPLETED',
        highCount: parseInt(result.Item.highCount?.N || '0'),
        mediumCount: parseInt(result.Item.mediumCount?.N || '0'),
        lowCount: parseInt(result.Item.lowCount?.N || '0'),
        totalCount: parseInt(result.Item.totalCount?.N || '0'),
        s3Key: result.Item.s3Key?.S,
        scannedAt: result.Item.scannedAt?.S,
        filename: result.Item.filename?.S
      })
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ── Email Full Report via SNS ─────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────
  try {
    let body = {};
    if (event.body) {
      body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } else {
      body = event;
    }

    if (body.action === 'email_report') {
      return await handleEmailReport(body);
    }

    // ────────────────────────────────────────────────────────────────────────
    // ── Default Scan ────────────────────────────────────────────────────────
    // ────────────────────────────────────────────────────────────────────────
    const { code, filename = 'untitled.js' } = body;

    if (!code) {
      return {
        statusCode: 400,
        headers: standardHeaders,
        body: JSON.stringify({ error: 'No code provided' })
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

    if (DYNAMODB_TABLE_NAME) {
      const ttl = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60);
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

    // SNS alert for HIGH severity findings
    if (SNS_TOPIC_ARN && summary.high > 0) {
      const highFindings = results
        .filter(v => v.severity === 'HIGH')
        .map(v => `  • [Line ${v.line}] ${v.name}: ${v.message}`)
        .join('\n');

      await sns.send(new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Subject: `🚨 SAST Alert: ${summary.high} HIGH Severity Finding(s) in ${filename}`,
        Message: [
          `SAST Scanner – Critical Vulnerability Alert`,
          `─────────────────────────────────────────`,
          `Scan ID   : ${scanId}`,
          `File      : ${filename}`,
          `Timestamp : ${scannedAt}`,
          ``,
          `Summary`,
          `  High   : ${summary.high}`,
          `  Medium : ${summary.medium}`,
          `  Low    : ${summary.low}`,
          `  Total  : ${summary.totalVulnerabilities}`,
          ``,
          `HIGH Severity Findings`,
          highFindings,
          ``,
          `Full report stored in S3: ${s3Key}`
        ].join('\n')
      }));
      console.log(`SNS alert published for ${summary.high} HIGH finding(s) in ${filename}`);
    }

    return {
      statusCode: 200,
      headers: standardHeaders,
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
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers: standardHeaders,
      body: JSON.stringify({ error: 'Scan failed', message: error.message })
    };
  }
};

// ══════════════════════════════════════════════════════════════════════════════
// Handler: Email Full Vulnerability Report via SNS
// ══════════════════════════════════════════════════════════════════════════════
async function handleEmailReport(body) {
  const { scanId, filename, scannedAt, summary, vulnerabilities, s3Key } = body;

  if (!SNS_TOPIC_ARN) {
    return {
      statusCode: 500,
      headers: standardHeaders,
      body: JSON.stringify({ error: 'SNS topic not configured' })
    };
  }

  if (!scanId || !summary) {
    return {
      statusCode: 400,
      headers: standardHeaders,
      body: JSON.stringify({ error: 'Missing scan data. Please run a scan first.' })
    };
  }

  const grouped = { HIGH: [], MEDIUM: [], LOW: [] };
  (vulnerabilities || []).forEach(v => {
    const sev = (v.severity || 'LOW').toUpperCase();
    if (grouped[sev]) grouped[sev].push(v);
  });

  const formatFindings = (findings) => {
    if (findings.length === 0) return '  (none)\n';
    return findings
      .map((v, i) => [
        `  ${i + 1}. ${v.name}`,
        `     Line     : ${v.line}`,
        `     Message  : ${v.message}`,
        `     Evidence : ${v.evidence || 'N/A'}`
      ].join('\n'))
      .join('\n\n');
  };

  const emailBody = [
    `╔══════════════════════════════════════════════════════════╗`,
    `║   SAST SCANNER — FULL VULNERABILITY REPORT             ║`,
    `╚══════════════════════════════════════════════════════════╝`,
    ``,
    `Scan ID     : ${scanId}`,
    `File        : ${filename || 'unknown'}`,
    `Scanned At  : ${scannedAt || new Date().toISOString()}`,
    `S3 Report   : ${s3Key || 'N/A'}`,
    ``,
    `────────────────── SUMMARY ──────────────────`,
    `  Total Vulnerabilities : ${summary.totalVulnerabilities}`,
    `  🔴 High               : ${summary.high}`,
    `  🟡 Medium             : ${summary.medium}`,
    `  🟢 Low                : ${summary.low}`,
    ``,
    `────────────────── HIGH SEVERITY ──────────────────`,
    formatFindings(grouped.HIGH),
    ``,
    `────────────────── MEDIUM SEVERITY ──────────────────`,
    formatFindings(grouped.MEDIUM),
    ``,
    `────────────────── LOW SEVERITY ──────────────────`,
    formatFindings(grouped.LOW),
    ``,
    `──────────────────────────────────────────────`,
    `Report generated by Startup Code Security Gate`,
    `Cloud Computing CS6620 — Group 9`
  ].join('\n');

  const subjectTag = summary.high > 0 ? '🚨 CRITICAL' : summary.medium > 0 ? '⚠️ WARNING' : '✅ CLEAN';

  await sns.send(new PublishCommand({
    TopicArn: SNS_TOPIC_ARN,
    Subject: `${subjectTag} SAST Report: ${summary.totalVulnerabilities} finding(s) in ${filename || 'scan'}`,
    Message: emailBody
  }));

  return {
    statusCode: 200,
    headers: standardHeaders,
    body: JSON.stringify({
      success: true,
      message: `Full vulnerability report sent via email (SNS) for scan ${scanId}`
    })
  };
}
