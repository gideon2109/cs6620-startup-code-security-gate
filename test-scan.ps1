# test-scan.ps1
# PowerShell verification script for the SAST Scanner Lambda Function URL

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $ScriptDir "terraform"

# Navigate to terraform directory to query outputs
Push-Location $TerraformDir

try {
    # Run terraform output
    $ApiUrl = terraform output -raw lambda_function_url 2>$null
}
catch {
    $ApiUrl = $null
}
finally {
    Pop-Location
}

if ([string]::IsNullOrEmpty($ApiUrl) -or $ApiUrl -like "*No outputs*") {
    Write-Error "Error: Could not retrieve lambda_function_url. Please run deploy.sh or run 'terraform apply' inside the terraform/ directory first."
    exit 1
}

Write-Host "==> Target Endpoint: $ApiUrl"
Write-Host "==> Sending test payload with three vulnerabilities:"
Write-Host "    1. Hardcoded Stripe secret key"
Write-Host "    2. SQL injection query concatenation"
Write-Host "    3. Insecure eval() function usage"
Write-Host "--------------------------------------------------------"

# Construct JSON payload
$Payload = @{
    filename = "demo-vulnerable.js"
    code = "const stripe_key = `"sk_live_51NzABC1234567890abcdef1234567890`";`nconst sql = `"SELECT * FROM users WHERE id = `" + req.query.id;`neval(sql);"
} | ConvertTo-Json

# Send POST request
try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Payload -ContentType "application/json"
    Write-Host "==> Response from AWS Lambda Function URL:"
    $Response | ConvertTo-Json -Depth 5
}
catch {
    Write-Error "Request failed: $_"
    if ($_.Exception.Response) {
        $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $Body = $Reader.ReadToEnd()
        Write-Host "Error Body: $Body"
    }
}
Write-Host "--------------------------------------------------------"
