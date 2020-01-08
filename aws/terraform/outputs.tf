output "cluster_name" {
  value = "${local.cluster_name}"
}

output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}

output "bootstrap_public_ip" {
  value = "${module.bootstrap.public_ip}"
}

output "ocp_web_console" {
  value = "https://console-openshift-console.apps.${local.cluster_name}.${var.domain_name}"
}

output "ocp_api_url" {
  value = "https://api.${local.cluster_name}.${var.domain_name}:6443"
}

output "ocp_oauth_url" {
  value = "https://oauth-openshift.apps.${local.cluster_name}.${var.domain_name}"
}

output "admin_user" {
  value = "kubeadmin"
}

output "admin_password" {
  value = "${module.complete_install.get_kubeadmin_password}"
}

output "kubeconfig" {
  value = "${module.complete_install.get_kubeconfig}"
}
