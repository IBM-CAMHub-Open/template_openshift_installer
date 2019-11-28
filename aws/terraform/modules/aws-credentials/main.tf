data "external" "access_key_id" {
  program = ["sh", "${path.module}/scripts/get_access_key_id.sh"]
}

data "external" "secret_access_key" {
  program = ["sh", "${path.module}/scripts/get_secret_access_key.sh"]
}
