# HTTP API Gateway
resource "aws_apigatewayv2_api" "this" {
  name          = "sast-scanner-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "application/json"]
    max_age = 300
  }

  tags = var.common_tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = var.common_tags
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "scan" {
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

  depends_on = [aws_apigatewayv2_api.this]
}
