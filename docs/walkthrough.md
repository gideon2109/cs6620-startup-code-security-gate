# Walkthrough: SAST Scanner & React Frontend Cloud Setup

This guide provides instructions for launching the serverless SAST backend on AWS Lambda and hosting the premium React frontend dashboard on AWS S3 static website hosting.

---

## 🏗️ 1. What was Created

### Backend Pipeline (in `sast/backend/`):
* Pushed ECR docker container scanner configs.
* Enabled public HTTPS **Lambda Function URL** with CORS.
* Programmed S3 JSON reporting and DynamoDB TTL indexing.
* Configured CloudWatch Alarms for Errors, Throttling, and high Latency connected to an SNS Alert Topic.

### Frontend Client (in `frontend/`):
* **`src/pages/Login.js`**: Styled secure card with login domain constraints.
* **`src/pages/Dashboard.js`**: SaaS interface containing a code scanner editor console, metadata inspector, and Recharts bar charts showing current security scans and historical trend data.
* **CORS compatibility**: Directly hooks to your verified live AWS Lambda URL (`https://phii2o2pws6npxec6ikic5lfy40sfbmj.lambda-url.us-east-1.on.aws/`).

---

## 💻 2. Testing the React Dashboard Locally

To test your new frontend locally:

```bash
# 1. Navigate to the frontend directory
cd C:\Users\access\go-rest-api\cloud\cs6620\sast\backend\frontend

# 2. Run the local development server (installs are already completed)
npm start
```

This will boot up the application and open **`http://localhost:3000`** in your browser.
* **Sign In:** Use any academic email ending with `.edu` (e.g. `gideon.gyakari@northeastern.edu`) and any password of at least 6 characters.
* **Scan:** Click **Load Vulnerable Sample** to insert vulnerable test code, and click **Start Security Scan** to test invoking your live AWS Lambda endpoint. The bar charts will dynamically update based on the server response!

---

## 🪣 3. Hosting Your Frontend on AWS S3 (Demo setup)

To host your React application in your AWS account so anyone can access it:

### Step A: Build the React Application
Compile the React code into a production bundle (HTML, JS, CSS) inside your local terminal:
```bash
cd C:\Users\access\go-rest-api\cloud\cs6620\sast\backend\frontend
npm run build
```
This generates a folder named `build/` in your directory.

### Step B: Provision the S3 Website Bucket
Ensure your AWS CLI credentials are active, and run these commands to set up S3 hosting:

```bash
# 1. Create a unique S3 bucket (substitute with your preferred name)
aws s3 mb s3://gideon-sast-frontend --region us-east-1

# 2. Upload the built static files
aws s3 sync build/ s3://gideon-sast-frontend/ --region us-east-1

# 3. Enable S3 Static Website Hosting
aws s3 website s3://gideon-sast-frontend --index-document index.html --error-document index.html
```

### Step C: Configure Public Read Policy
AWS S3 blocks public access by default. Make the static site public by applying a bucket policy:

1. **Disable Public Block:**
   ```bash
   aws s3api put-public-access-block --bucket gideon-sast-frontend --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
   ```
2. **Apply Read Policy:**
   Create a policy JSON allowing public read access:
   ```bash
   aws s3api put-bucket-policy --bucket gideon-sast-frontend --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicReadGetObject\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::gideon-sast-frontend/*\"}]}"
   ```

3. **Get Your Live URL:**
   Your frontend website will now be live at:
   `http://gideon-sast-frontend.s3-website-us-east-1.amazonaws.com`

---

## 📁 4. Push Files to GitHub
All backend changes (including ECR, Lambda Function URL, S3 lifecycle fixes, and test scripts) are already pushed to your remote repository.

Once you are ready to upload your React frontend code to GitHub as well, run these commands:

```bash
# Navigate to the repo root folder
cd C:\Users\access\go-rest-api\cloud\cs6620\sast\backend

# Stage, commit and push the frontend folder
git add frontend/
git commit -m "feat: add premium React frontend dashboard with login and charts"
git push origin main
```
