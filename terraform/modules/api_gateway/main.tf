# HTTP API Gateway
resource "aws_apigatewayv2_api" "this" {
  name          = "sast-scanner-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["http://gideon-sast-frontend.s3-website-us-east-1.amazonaws.com"]
    allow_methods = ["POST", "OPTIONS"]
    # Only header names, NOT values like "application/json"
    allow_headers = ["content-type", "authorization", "x-amz-date", "x-api-key"]
    max_age = 300
  }

  tags = var.common_tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  tags        = var.common_tags
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# POST route only – API Gateway handles OPTIONS automatically via CORS config
resource "aws_apigatewayv2_route" "post_scan" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /scan"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
