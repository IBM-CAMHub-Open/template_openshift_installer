output "openshift_url" {
  value = "https://${element(keys(var.master_hostname_ip),0)}.${var.vm_domain}:8443"
}

output "openshift_user" {
  value = "${var.openshift_user}"
}

output "openshift_password" {
  value = "${var.openshift_password}"
}

output "openshift_master_ip" {
  value = "${element(values(var.master_hostname_ip),0)}"
}