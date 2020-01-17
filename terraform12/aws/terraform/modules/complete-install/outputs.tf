output "complete" {
  value = random_id.complete_install.hex
}

output "get_kubeadmin_password" {
  value = camc_scriptpackage.get_kubeadmin_password.result["stdout"]
}

output "get_kubeconfig" {
  value = camc_scriptpackage.get_kubeconfig.result["stdout"]
}

