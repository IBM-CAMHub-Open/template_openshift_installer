output "cluster_url" {
	value = "${module.complete_install.console}"
}

output "oauth_url" {
	value = "https://oauth-openshift.apps.${var.clustername}.${var.ocp_cluster_domain}"
}

output "api_url" {
	value = "https://api.${var.clustername}.${var.ocp_cluster_domain}:6443"
}

output "kubeadmin_password" {
	value = "${module.complete_install.password}"
}

output "cluster_prvt_key" {
	value = "${module.vmware_ign_config.cluster_prvt_key}"
}

output "boot_ip" { 
    value = "${module.bootstrap.ip}"
}

output "control_ip" {
    value = "${module.get_control_ip.control_ip}"
}

output "compute_ip" {
    value = "${module.get_compute_ip.compute_ip}"
}