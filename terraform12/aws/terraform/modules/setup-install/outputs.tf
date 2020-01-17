output "setup_dir" {
  value = local.setup_dir
}

output "done" {
  value = random_id.setup_install.hex
}

