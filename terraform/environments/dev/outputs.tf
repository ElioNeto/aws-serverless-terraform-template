output "api_base_url" {
  description = "URL to test the deployed API"
  value       = module.api.api_endpoint
}

output "curl_command" {
  description = "Command to test the endpoint immediately"
  value       = "curl -X POST ${module.api.api_endpoint}/items -d '{\"hello\":\"world\"}'"
}