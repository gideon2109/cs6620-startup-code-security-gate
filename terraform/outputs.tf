
output "api_gateway_url" {
  description = "API Gateway URL for scanning"
  value       = module.api_gateway.scan_url
}
