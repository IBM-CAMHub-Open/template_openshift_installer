output "access_key_id" {
  value = data.external.access_key_id.result["content"]
}

output "secret_access_key" {
  value = data.external.secret_access_key.result["content"]
}

