output "api_endpoint" {
  description = "The base URL of the API Gateway"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "scan_url" {
  description = "The full URL for the /scan endpoint"
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/scan"
}
