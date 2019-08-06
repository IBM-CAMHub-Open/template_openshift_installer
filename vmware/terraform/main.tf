provider "vsphere" {
  version              = "~> 1.3"
  allow_unverified_ssl = "true"
}

provider "random" {
  version = "~> 1.0"
}

provider "local" {
  version = "~> 1.1"
}

provider "null" {
  version = "~> 1.0"
}

provider "tls" {
  version = "~> 1.0"
}

resource "random_string" "random-dir" {
  length  = 8
  special = false
}

resource "tls_private_key" "generate" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "null_resource" "create-temp-random-dir" {
  provisioner "local-exec" {
    command = "${format("mkdir -p  /tmp/%s" , "${random_string.random-dir.result}")}"
  }
}

module "deployVM_infra" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"

  # count                 = "${length(var.infra_vm_ipv4_address)}"
  count = "${length(keys(var.infra_hostname_ip))}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"
  enable_vm                  = "true"
  vm_vcpu                    = "${var.infra_vcpu}"                                                                                                           // vm_number_of_vcpu
  vm_name                    = "${keys(var.infra_hostname_ip)}"
  vm_memory                  = "${var.infra_memory}"
  vm_template                = "${var.vm_template}"
  vm_os_password             = "${var.vm_os_password}"
  vm_os_user                 = "${var.vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.os_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.os_public_ssh_key}"}"
  vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_ipv4_gateway            = "${var.infra_vm_ipv4_gateway}"
  # vm_ipv4_address            = "${var.infra_vm_ipv4_address}"
  vm_ipv4_address         = "${values(var.infra_hostname_ip)}"
  vm_ipv4_prefix_length   = "${var.infra_vm_ipv4_prefix_length}"
  vm_adapter_type         = "${var.vm_adapter_type}"
  vm_disk1_size           = "${var.infra_vm_disk1_size}"
  vm_disk1_datastore      = "${var.vm_disk1_datastore}"
  vm_disk1_keep_on_remove = "${var.infra_vm_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.infra_vm_disk2_enable}"
  vm_disk2_size           = "${var.infra_vm_disk2_size}"
  vm_disk2_datastore      = "${var.vm_disk2_datastore}"
  vm_disk2_keep_on_remove = "${var.infra_vm_disk2_keep_on_remove}"
  vm_dns_servers          = "${var.vm_dns_servers}"
  vm_dns_suffixes         = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"

  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"    
  
}

module "deployVM_master" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"

  # count                 = "${length(var.master_vm_ipv4_address)}"
  count = "${length(keys(var.master_hostname_ip))}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"
  enable_vm = "true"
  vm_vcpu = "${var.master_vcpu}" // vm_number_of_vcpu
  # vm_name                    = "${var.master_prefix_name}"
  vm_name                    = "${keys(var.master_hostname_ip)}"
  vm_memory                  = "${var.master_memory}"
  vm_template                = "${var.vm_template}"
  vm_os_password             = "${var.vm_os_password}"
  vm_os_user                 = "${var.vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.os_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.os_public_ssh_key}"}"
  vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_ipv4_gateway            = "${var.master_vm_ipv4_gateway}"
  # vm_ipv4_address            = "${var.master_vm_ipv4_address}"
  vm_ipv4_address         = "${values(var.master_hostname_ip)}"
  vm_ipv4_prefix_length   = "${var.master_vm_ipv4_prefix_length}"
  vm_adapter_type         = "${var.vm_adapter_type}"
  vm_disk1_size           = "${var.master_vm_disk1_size}"
  vm_disk1_datastore      = "${var.vm_disk1_datastore}"
  vm_disk1_keep_on_remove = "${var.master_vm_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.master_vm_disk2_enable}"
  vm_disk2_size           = "${var.master_vm_disk2_size}"
  vm_disk2_datastore      = "${var.vm_disk2_datastore}"
  vm_disk2_keep_on_remove = "${var.master_vm_disk2_keep_on_remove}"
  vm_dns_servers          = "${var.vm_dns_servers}"
  vm_dns_suffixes         = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"    
}

module "deployVM_etcd" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"

  # count                 = "${length(var.etcd_vm_ipv4_address)}"
  count = "${(length(keys(var.etcd_hostname_ip)) == length(keys(var.master_hostname_ip)) && length(distinct(concat(keys(var.etcd_hostname_ip), keys(var.master_hostname_ip)))) == length(keys(var.etcd_hostname_ip))) ? 0 : length(keys(var.etcd_hostname_ip))}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"
  enable_vm = "${(length(keys(var.etcd_hostname_ip)) == length(keys(var.master_hostname_ip)) && length(distinct(concat(keys(var.etcd_hostname_ip), keys(var.master_hostname_ip)))) == length(keys(var.etcd_hostname_ip))) ? "false" : "true"}"
  vm_vcpu = "${var.etcd_vcpu}" // vm_number_of_vcpu
  # vm_name                    = "${var.etcd_prefix_name}"
  vm_name                    = "${keys(var.etcd_hostname_ip)}"
  vm_memory                  = "${var.etcd_memory}"
  vm_template                = "${var.vm_template}"
  vm_os_password             = "${var.vm_os_password}"
  vm_os_user                 = "${var.vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.os_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.os_public_ssh_key}"}"
  vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_ipv4_gateway            = "${var.etcd_vm_ipv4_gateway}"
  # vm_ipv4_address            = "${var.etcd_vm_ipv4_address}"
  vm_ipv4_address         = "${values(var.etcd_hostname_ip)}"
  vm_ipv4_prefix_length   = "${var.etcd_vm_ipv4_prefix_length}"
  vm_adapter_type         = "${var.vm_adapter_type}"
  vm_disk1_size           = "${var.etcd_vm_disk1_size}"
  vm_disk1_datastore      = "${var.vm_disk1_datastore}"
  vm_disk1_keep_on_remove = "${var.etcd_vm_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.etcd_vm_disk2_enable}"
  vm_disk2_size           = "${var.etcd_vm_disk2_size}"
  vm_disk2_datastore      = "${var.vm_disk2_datastore}"
  vm_disk2_keep_on_remove = "${var.etcd_vm_disk2_keep_on_remove}"
  vm_dns_servers          = "${var.vm_dns_servers}"
  vm_dns_suffixes         = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"    
}

module "deployVM_compute" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"

  # count                 = "${length(var.compute_vm_ipv4_address)}"
  count = "${length(keys(var.compute_hostname_ip))}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"
  enable_vm = "true"
  vm_vcpu = "${var.compute_vcpu}" // vm_number_of_vcpu
  # vm_name                    = "${var.compute_prefix_name}"
  vm_name                    = "${keys(var.compute_hostname_ip)}"
  vm_memory                  = "${var.compute_memory}"
  vm_template                = "${var.vm_template}"
  vm_os_password             = "${var.vm_os_password}"
  vm_os_user                 = "${var.vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.os_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.os_public_ssh_key}"}"
  vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_ipv4_gateway            = "${var.compute_vm_ipv4_gateway}"
  # vm_ipv4_address            = "${var.compute_vm_ipv4_address}"
  vm_ipv4_address         = "${values(var.compute_hostname_ip)}"
  vm_ipv4_prefix_length   = "${var.compute_vm_ipv4_prefix_length}"
  vm_adapter_type         = "${var.vm_adapter_type}"
  vm_disk1_size           = "${var.compute_vm_disk1_size}"
  vm_disk1_datastore      = "${var.vm_disk1_datastore}"
  vm_disk1_keep_on_remove = "${var.compute_vm_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.compute_enable_glusterFS && var.compute_vm_disk2_enable}"
  vm_disk2_size           = "${var.compute_vm_disk2_size}"
  vm_disk2_datastore      = "${var.vm_disk2_datastore}"
  vm_disk2_keep_on_remove = "${var.compute_vm_disk2_keep_on_remove}"
  vm_dns_servers          = "${var.vm_dns_servers}"
  vm_dns_suffixes         = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
}

module "deployVM_lb" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"

  # count                 = "${length(var.lb_vm_ipv4_address)}"
  count = "${length(keys(var.lb_hostname_ip))}"

  #######
  // vm_folder = "${module.createFolder.folderPath}"
  enable_vm                  = "${var.enable_lb}"
  vm_vcpu = "${var.lb_vcpu}" // vm_number_of_vcpu
  # vm_name                    = "${var.lb_prefix_name}"
  vm_name                    = "${keys(var.lb_hostname_ip)}"
  vm_memory                  = "${var.lb_memory}"
  vm_template                = "${var.vm_template}"
  vm_os_password             = "${var.vm_os_password}"
  vm_os_user                 = "${var.vm_os_user}"
  vm_domain                  = "${var.vm_domain}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.os_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.os_public_ssh_key}"}"
  vm_network_interface_label = "${var.vm_network_interface_label}"
  vm_ipv4_gateway            = "${var.lb_vm_ipv4_gateway}"
  # vm_ipv4_address            = "${var.lb_vm_ipv4_address}"
  vm_ipv4_address         = "${values(var.lb_hostname_ip)}"
  vm_ipv4_prefix_length   = "${var.lb_vm_ipv4_prefix_length}"
  vm_adapter_type         = "${var.vm_adapter_type}"
  vm_disk1_size           = "${var.lb_vm_disk1_size}"
  vm_disk1_datastore      = "${var.vm_disk1_datastore}"
  vm_disk1_keep_on_remove = "${var.lb_vm_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.lb_vm_disk2_enable}"
  vm_disk2_size           = "${var.lb_vm_disk2_size}"
  vm_disk2_datastore      = "${var.vm_disk2_datastore}"
  vm_disk2_keep_on_remove = "${var.lb_vm_disk2_keep_on_remove}"
  vm_dns_servers          = "${var.vm_dns_servers}"
  vm_dns_suffixes         = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
}

module "host_prepare" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//host_prepare"
  
  private_key          = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.os_private_ssh_key)}"}"
  vm_os_user           = "${var.vm_os_user}"
  vm_os_password       = "${var.vm_os_password}"
  rh_user              = "${var.rh_user}"
  rh_password          = "${var.rh_password}"
  vm_ipv4_address_list = "${compact(split(",", replace(join(",",distinct(concat(values(var.infra_hostname_ip), values(var.master_hostname_ip), values(var.etcd_hostname_ip), values(var.compute_hostname_ip), values(var.lb_hostname_ip)))),"0.0.0.0", "" )))}"
  vm_hostname_list     = "${join(",",distinct(concat(keys(var.infra_hostname_ip), keys(var.master_hostname_ip), keys(var.etcd_hostname_ip), keys(var.compute_hostname_ip), keys(var.lb_hostname_ip))))}"
  domain_name          = "${var.vm_domain}"
  installer_hostname   = "${element(keys(var.master_hostname_ip), 0)}"
  random               = "${random_string.random-dir.result}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
  dependsOn           = "${module.deployVM_compute.dependsOn}+${module.deployVM_master.dependsOn}+${module.deployVM_infra.dependsOn}"
}

module "config_inventory" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//config_inventory"
  
  private_key          = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.os_private_ssh_key)}"}"
  vm_os_user           = "${var.vm_os_user}"
  vm_os_password       = "${var.vm_os_password}"
  master_vm_hostname         = "${join(",",keys(var.master_hostname_ip))}"
  etcd_vm_hostname           = "${join(",",keys(var.etcd_hostname_ip))}"
  compute_vm_hostname        = "${join(",",keys(var.compute_hostname_ip))}"
  lb_vm_hostname             = "${join(",",keys(var.lb_hostname_ip))}"
  enable_lb                  = "${var.enable_lb}"
  domain_name                = "${var.vm_domain}"
  infra_vm_hostname          = "${join(",",keys(var.infra_hostname_ip))}"

  infra_vm_ipv4_address      = "${join(",",values(var.infra_hostname_ip))}"
  master_vm_ipv4_address     = "${element(values(var.master_hostname_ip), 0)}"
  rh_user                    = "${var.rh_user}"
  rh_password                = "${var.rh_password}"
  compute_enable_glusterFS   = "${var.compute_enable_glusterFS}"

  random              = "${random_string.random-dir.result}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
  dependsOn           = "${module.host_prepare.dependsOn}"
}

module "run_installer" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//run_installer"
  
  private_key          = "${length(var.os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.os_private_ssh_key)}"}"
  vm_os_user           = "${var.vm_os_user}"
  vm_os_password       = "${var.vm_os_password}"
  master_vm_ipv4_address     = "${element(values(var.master_hostname_ip), 0)}"
  openshift_user      = "${var.openshift_user}"
  openshift_password  = "${var.openshift_password}"

  random              = "${random_string.random-dir.result}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
  dependsOn           = "${module.config_inventory.dependsOn}"
}