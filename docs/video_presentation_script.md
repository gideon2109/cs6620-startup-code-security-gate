# 5-Minute Presentation Video Script: SAST Scanner (Milestone 1)

This script is designed for a **5-minute screen recording** to achieve maximum marks (30/30) on **Milestone 1**. It focuses on showing running scripts, live AWS resources, functional code execution, and monitoring configs.

---

## ⏱️ Video Timeline Overview

| Timestamp | Section | Key Visual | Spoken Topic |
|:---|:---|:---|:---|
| **0:00 - 0:35** | 1. Introduction | Slide or repository root | Identity, project scope, group work division |
| **0:35 - 1:45** | 2. IaC Deployment | Running `./deploy.sh` | Terraform modular deployment & Docker image compilation |
| **1:45 - 2:45** | 3. Live Scan Test | Local React login & scan trigger | Testing Function URL & viewing Recharts bar charts |
| **2:45 - 4:00** | 4. AWS Web Console | ECR, S3, DynamoDB, Lambda | Verification of deployed backend components |
| **4:00 - 4:45** | 5. Monitoring & Alarms | CloudWatch Alarms, SNS | Throttling, latency duration, and email alerts |
| **4:45 - 5:00** | 6. Conclusion | React UI & architecture diagram | Summary of cloud-native infrastructure |

---

## 🎤 Chronological Script

### Section 1: Introduction (0:00 - 0:35)
*   **Visual:** Show your GitHub repository page or VS Code workspace displaying the project structure.
*   **Action:** Hover your cursor over the project directories inside `sast/backend/`, highlighting the backend code and its nested `frontend/` subdirectory.
*   **Audio Script:**
    > *"Hello, my name is Gideon Ntim Gyakari, representing Group 9 for CS6620 Cloud Computing. My Northeastern email is ntimgyakari.g@northeastern.edu.*
    >
    > *For our semester project, we are building the 'Startup Code Security Gate'—a serverless SAST pipeline for JavaScript applications. In this Milestone 1 demonstration, I will show our fully automated Infrastructure as Code setup using Terraform.*
    >
    > *My individual contribution for this milestone focuses on the cloud backend infrastructure, containerization, and CloudWatch operational monitoring, while my partner Rahul is expanding frontend modules and vulnerability scanning rulesets."*

---

### Section 2: IaC Deployment (0:35 - 1:45)
*   **Visual:** Open your terminal (Git Bash or PowerShell) inside `sast/backend/`.
*   **Action:** Type and run `./deploy.sh`. Keep the terminal visible as compilation and Terraform steps output scrolling logs.
*   **Audio Script:**
    > *"To begin, I will run our automated deployment script, `./deploy.sh`.*
    >
    > *This script starts by initializing our Terraform modules and deploying our secure ECR container registry first. Once the repository is created, the script logs our local Docker daemon into ECR using AWS credentials, compiles our SAST scanner into a container based on the official Node.js AWS Lambda image, and pushes it to ECR.*
    >
    > *Finally, Terraform applies our remaining infrastructure modules, creating the S3 reports bucket, our DynamoDB metadata table, the Lambda Function URL, and our CloudWatch Alarms. As we can see, the deployment is completed and Terraform outputs our public Lambda Function URL and active SNS Alerts ARN."*

---

### Section 3: Live Scan Test (1:45 - 2:45)
*   **Visual:** Bring up a browser window pointing to `http://localhost:3000` (or your S3 hosted URL).
*   **Action:** 
    1. Type `gideon.gyakari@northeastern.edu` as the email, enter a password, and click **Sign In**.
    2. Click **Load Vulnerable Sample**.
    3. Click **Start Security Scan**. Show the loading spinner and then the resulting dashboard.
*   **Audio Script:**
    > *"Now let's test our live frontend connected to this new AWS backend URL. I will log in to our dashboard using my northeastern email address.*
    >
    > *Once authenticated, I will load a vulnerable code sample which contains a hardcoded Stripe API key, a SQL injection query, and an insecure eval statement. When I click 'Start Security Scan', the frontend sends this payload over HTTPS directly to our Lambda Function URL.*
    >
    > *The scan is successful! The response displays our custom scan reference ID and the S3 storage key. Crucially, Recharts bar charts render immediately, displaying a breakdown of the three High severity vulnerabilities detected, along with our scan history trend database saved in local storage."*

---

### Section 4: AWS Console Verification (2:45 - 4:00)
*   **Visual:** Switch to your AWS Web Console in the browser.
*   **Action:** Click through ECR, Lambda, S3, and DynamoDB in order.
    1. **ECR:** Show `startup-code-security-gate-repo` and the pushed image with tag `latest`.
    2. **Lambda:** Show `sast-scanner-lambda`, verify it is image-based, show environment variables, and show the Function URL matching the outputs.
    3. **S3:** Open `sast-reports-...`, click inside `reports/` and show the newly created `.json` scan report.
    4. **DynamoDB:** Open `sast-scan-metadata`, click **Explore table items** and show the metadata row including vulnerability counts and the `ttl` timestamp.
*   **Audio Script:**
    > *"Let's verify these resources inside the AWS Management Console.*
    >
    > *First, inside ECR, we see our container repository holding our compiled scanner image. Under Lambda, our `sast-scanner-lambda` is successfully configured with its public Function URL, using the pre-provisioned 'LabRole' IAM credentials required for AWS Learner Labs.*
    >
    > *Next, opening our S3 bucket, we can see inside the reports folder that a JSON report has been generated for our scan. It lists our findings and matches the scan ID.*
    >
    > *Over in DynamoDB, exploring our table items shows our scan metadata entry, storing severity counts and the Unix epoch TTL attribute which cleans up items after 30 days."*

---

### Section 5: Operational Alarms & Alerts (4:00 - 4:45)
*   **Visual:** Go to **CloudWatch** -> **Alarms** in the AWS Console, then switch to **SNS** -> **Topics** -> click on your subscription email.
*   **Action:** Show the three alarms: errors alarm, throttles alarm, and high duration alarm.
*   **Audio Script:**
    > *"To satisfy operational reliability requirements, we have set up proactive alerting. Under CloudWatch Alarms, we monitor three major performance limits: execution Errors, Throttling due to region concurrency limits, and Duration latency exceeding 15 seconds—which protects against regex backtracking.*
    >
    > *If any of these alarms are triggered, they publish an event to our AWS SNS Alerts topic. I have configured an active email subscription to this topic, which notifies our operations team immediately so we can bring down the runtime or fix application-level bugs."*

---

### Section 6: Conclusion (4:45 - 5:00)
*   **Visual:** Switch back to the React UI or your architecture diagram.
*   **Audio Script:**
    > *"This concludes the Milestone 1 demonstration. We have successfully deployed a fully functional, repeatable serverless SAST scanner using modular Terraform scripting. Thank you for your time."*
    >
    > *(Stop recording)*

---

## 💡 Tips for a Smooth Recording

1.  **Do a dry run:** Practice the transition from the terminal to the browser.
2.  **AWS details ready:** Open your browser tabs (ECR, S3, DynamoDB, Lambda, CloudWatch) ahead of time in another window to avoid loading lag during the video.
3.  **Ensure Docker is running:** Check that Docker Desktop is active on your machine before starting.
4.  **Confirm credentials:** Double-check that your Learner Lab token hasn't expired right before you start recording.
