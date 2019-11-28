output "cluster_url" {
	value = "${module.complete_install.console}"
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
    value = "${module.control_plane.ip}"
}

output "compute_ip" {
    value = "${module.compute.ip}"
}