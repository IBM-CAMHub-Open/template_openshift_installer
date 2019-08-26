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

  count  = "${length(keys(var.infra_node_hostname_ip))}"
  
  #######
  datacenter              = "${var.datacenter}"
  resource_pool           = "${var.resource_pool}"
  enable_vm               = "true"
  vm_vcpu                 = "${var.infra_node_vcpu}"                                                                                                           // vm_number_of_vcpu
  vm_name                 = "${keys(var.infra_node_hostname_ip)}"
  vm_memory               = "${var.infra_node_memory}"
  vm_image_template       = "${var.vm_image_template}"
  vm_os_password          = "${var.vm_os_password}"
  vm_os_user              = "${var.vm_os_user}"
  vm_domain_name          = "${var.vm_domain_name}"
  vm_folder               = "${var.vm_folder}"
  vm_private_ssh_key      = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_public_ssh_key       = "${length(var.vm_os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"
  network                 = "${var.network}"
  vm_ipv4_gateway         = "${var.vm_ipv4_gateway}"
  vm_ipv4_address         = "${values(var.infra_node_hostname_ip)}"
  vm_ipv4_netmask         = "${var.vm_ipv4_netmask}"
  adapter_type            = "${var.adapter_type}"
  vm_disk1_size           = "${var.infra_node_disk1_size}"
  vm_disk1_datastore      = "${var.datastore}"
  vm_disk1_keep_on_remove = "${var.infra_node_disk1_keep_on_remove}"
  vm_disk2_enable         = "false"
  vm_disk2_size           = "0"
  vm_disk2_datastore      = "${var.datastore}"
  vm_disk2_keep_on_remove = "false"
  dns_servers             = "${var.dns_servers}"
  dns_suffixes            = "${var.dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"

  #######
  bastion_host            = "${var.bastion_host}"
  bastion_user            = "${var.bastion_user}"
  bastion_private_key     = "${var.bastion_private_key}"
  bastion_port            = "${var.bastion_port}"
  bastion_host_key        = "${var.bastion_host_key}"
  bastion_password        = "${var.bastion_password}"    
  
}

module "deployVM_master" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  count  = "${length(keys(var.master_node_hostname_ip))}"

  #######
  datacenter              = "${var.datacenter}"
  resource_pool           = "${var.resource_pool}"
  enable_vm               = "true"
  vm_vcpu                 = "${var.master_node_vcpu}" 
  vm_name                 = "${keys(var.master_node_hostname_ip)}"
  vm_memory               = "${var.master_node_memory}"
  vm_image_template       = "${var.vm_image_template}"
  vm_os_password          = "${var.vm_os_password}"
  vm_os_user              = "${var.vm_os_user}"
  vm_domain_name          = "${var.vm_domain_name}"
  vm_folder               = "${var.vm_folder}"
  vm_private_ssh_key      = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_public_ssh_key       = "${length(var.vm_os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"
  network                 = "${var.network}"
  vm_ipv4_gateway         = "${var.vm_ipv4_gateway}"
  vm_ipv4_address         = "${values(var.master_node_hostname_ip)}"
  vm_ipv4_netmask         = "${var.vm_ipv4_netmask}"
  adapter_type            = "${var.adapter_type}"
  vm_disk1_size           = "${var.master_node_disk1_size}"
  vm_disk1_datastore      = "${var.datastore}"
  vm_disk1_keep_on_remove = "${var.master_node_disk1_keep_on_remove}"
  vm_disk2_enable         = "false"
  vm_disk2_size           = "0"
  vm_disk2_datastore      = "${var.datastore}"
  vm_disk2_keep_on_remove = "false"
  dns_servers             = "${var.dns_servers}"
  dns_suffixes            = "${var.dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  
  #######
  bastion_host            = "${var.bastion_host}"
  bastion_user            = "${var.bastion_user}"
  bastion_private_key     = "${var.bastion_private_key}"
  bastion_port            = "${var.bastion_port}"
  bastion_host_key        = "${var.bastion_host_key}"
  bastion_password        = "${var.bastion_password}"    
}

module "deployVM_etcd" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  count = "${(length(keys(var.etcd_node_hostname_ip)) == length(keys(var.master_node_hostname_ip)) && length(distinct(concat(keys(var.etcd_node_hostname_ip), keys(var.master_node_hostname_ip)))) == length(keys(var.etcd_node_hostname_ip))) ? 0 : length(keys(var.etcd_node_hostname_ip))}"
  
  #######
  datacenter              = "${var.datacenter}"
  resource_pool           = "${var.resource_pool}"
  enable_vm               = "${(length(keys(var.etcd_node_hostname_ip)) == length(keys(var.master_node_hostname_ip)) && length(distinct(concat(keys(var.etcd_node_hostname_ip), keys(var.master_node_hostname_ip)))) == length(keys(var.etcd_node_hostname_ip))) ? "false" : "true"}"
  vm_vcpu                 = "${var.etcd_node_vcpu}" 
  vm_name                 = "${keys(var.etcd_node_hostname_ip)}"
  vm_memory               = "${var.etcd_node_memory}"
  vm_image_template       = "${var.vm_image_template}"
  vm_os_password          = "${var.vm_os_password}"
  vm_os_user              = "${var.vm_os_user}"
  vm_domain_name          = "${var.vm_domain_name}"
  vm_folder               = "${var.vm_folder}"
  vm_private_ssh_key      = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_public_ssh_key       = "${length(var.vm_os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"
  network                 = "${var.network}"
  vm_ipv4_gateway         = "${var.vm_ipv4_gateway}"
  vm_ipv4_address         = "${values(var.etcd_node_hostname_ip)}"
  vm_ipv4_netmask         = "${var.vm_ipv4_netmask}"
  adapter_type            = "${var.adapter_type}"
  vm_disk1_size           = "${var.etcd_node_disk1_size}"
  vm_disk1_datastore      = "${var.datastore}"
  vm_disk1_keep_on_remove = "${var.etcd_node_disk1_keep_on_remove}"
  vm_disk2_enable         = "false"
  vm_disk2_size           = "0"
  vm_disk2_datastore      = "${var.datastore}"
  vm_disk2_keep_on_remove = "false"
  dns_servers             = "${var.dns_servers}"
  dns_suffixes            = "${var.dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  
  #######
  bastion_host            = "${var.bastion_host}"
  bastion_user            = "${var.bastion_user}"
  bastion_private_key     = "${var.bastion_private_key}"
  bastion_port            = "${var.bastion_port}"
  bastion_host_key        = "${var.bastion_host_key}"
  bastion_password        = "${var.bastion_password}"    
}

module "deployVM_compute" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  count  = "${length(keys(var.compute_node_hostname_ip))}"
  
  #######
  datacenter              = "${var.datacenter}"
  resource_pool           = "${var.resource_pool}"
  enable_vm               = "true"
  vm_vcpu                 = "${var.compute_node_vcpu}" 
  vm_name                 = "${keys(var.compute_node_hostname_ip)}"
  vm_memory               = "${var.compute_node_memory}"
  vm_image_template       = "${var.vm_image_template}"
  vm_os_password          = "${var.vm_os_password}"
  vm_os_user              = "${var.vm_os_user}"
  vm_domain_name          = "${var.vm_domain_name}"
  vm_folder               = "${var.vm_folder}"
  vm_private_ssh_key      = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_public_ssh_key       = "${length(var.vm_os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"
  network                 = "${var.network}"
  vm_ipv4_gateway         = "${var.vm_ipv4_gateway}"
  vm_ipv4_address         = "${values(var.compute_node_hostname_ip)}"
  vm_ipv4_netmask         = "${var.vm_ipv4_netmask}"
  adapter_type            = "${var.adapter_type}"
  vm_disk1_size           = "${var.compute_node_disk1_size}"
  vm_disk1_datastore      = "${var.datastore}"
  vm_disk1_keep_on_remove = "${var.compute_node_disk1_keep_on_remove}"
  vm_disk2_enable         = "${var.compute_node_enable_glusterfs && var.compute_node_disk2_enable}"
  vm_disk2_size           = "${var.compute_node_disk2_size}"
  vm_disk2_datastore      = "${var.datastore}"
  vm_disk2_keep_on_remove = "${var.compute_node_disk2_keep_on_remove}"
  dns_servers             = "${var.dns_servers}"
  dns_suffixes            = "${var.dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  #######
  bastion_host            = "${var.bastion_host}"
  bastion_user            = "${var.bastion_user}"
  bastion_private_key     = "${var.bastion_private_key}"
  bastion_port            = "${var.bastion_port}"
  bastion_host_key        = "${var.bastion_host_key}"
  bastion_password        = "${var.bastion_password}"      
}

module "deployVM_lb" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//vmware_provision"

  count  = "${length(keys(var.lb_node_hostname_ip))}"
  
  #######
  datacenter              = "${var.datacenter}"
  resource_pool           = "${var.resource_pool}"
  enable_vm               = "${var.enable_lb}"
  vm_vcpu                 = "${var.lb_node_vcpu}" 
  vm_name                 = "${keys(var.lb_node_hostname_ip)}"
  vm_memory               = "${var.lb_node_memory}"
  vm_image_template       = "${var.vm_image_template}"
  vm_os_password          = "${var.vm_os_password}"
  vm_os_user              = "${var.vm_os_user}"
  vm_domain_name          = "${var.vm_domain_name}"
  vm_folder               = "${var.vm_folder}"
  vm_private_ssh_key      = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_public_ssh_key       = "${length(var.vm_os_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.vm_os_public_ssh_key}"}"
  network                 = "${var.network}"
  vm_ipv4_gateway         = "${var.vm_ipv4_gateway}"
  vm_ipv4_address         = "${values(var.lb_node_hostname_ip)}"
  vm_ipv4_netmask         = "${var.vm_ipv4_netmask}"
  adapter_type            = "${var.adapter_type}"
  vm_disk1_size           = "${var.lb_node_disk1_size}"
  vm_disk1_datastore      = "${var.datastore}"
  vm_disk1_keep_on_remove = "${var.lb_node_disk1_keep_on_remove}"
  vm_disk2_enable         = "false"
  vm_disk2_size           = "0"
  vm_disk2_datastore      = "${var.datastore}"
  vm_disk2_keep_on_remove = "false"
  dns_servers             = "${var.dns_servers}"
  dns_suffixes            = "${var.dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                  = "${random_string.random-dir.result}"
  #######
  bastion_host            = "${var.bastion_host}"
  bastion_user            = "${var.bastion_user}"
  bastion_private_key     = "${var.bastion_private_key}"
  bastion_port            = "${var.bastion_port}"
  bastion_host_key        = "${var.bastion_host_key}"
  bastion_password        = "${var.bastion_password}"      
}

module "host_prepare" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//host_prepare"
  
  private_key           = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_os_user            = "${var.vm_os_user}"
  vm_os_password        = "${var.vm_os_password}"
  rh_user               = "${var.rh_user}"
  rh_password           = "${var.rh_password}"
  vm_ipv4_address_list  = "${compact(split(",", replace(join(",",distinct(concat(values(var.infra_node_hostname_ip), values(var.master_node_hostname_ip), values(var.etcd_node_hostname_ip), values(var.lb_node_hostname_ip)))),"0.0.0.0", "" )))}"
  vm_hostname_list      = "${join(",",distinct(concat(keys(var.infra_node_hostname_ip), keys(var.master_node_hostname_ip), keys(var.etcd_node_hostname_ip), keys(var.lb_node_hostname_ip))))}"
  vm_domain_name        = "${var.vm_domain_name}"
  installer_hostname    = "${element(keys(var.master_node_hostname_ip), 0)}"
  compute_hostname      = "${element(keys(var.compute_node_hostname_ip), 0)}"
  random                = "${random_string.random-dir.result}"
  #######
  bastion_host          = "${var.bastion_host}"
  bastion_user          = "${var.bastion_user}"
  bastion_private_key   = "${var.bastion_private_key}"
  bastion_port          = "${var.bastion_port}"
  bastion_host_key      = "${var.bastion_host_key}"
  bastion_password      = "${var.bastion_password}"      
  dependsOn             = "${module.deployVM_master.dependsOn}+${module.deployVM_infra.dependsOn}+${module.deployVM_compute.dependsOn}"
}

module "host_prepare_compute" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//host_prepare"
  
  private_key           = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_os_user            = "${var.vm_os_user}"
  vm_os_password        = "${var.vm_os_password}"
  rh_user               = "${var.rh_user}"
  rh_password           = "${var.rh_password}"
  vm_ipv4_address_list  = "${values(var.compute_node_hostname_ip)}"
  vm_hostname_list      = "${join(",", keys(var.compute_node_hostname_ip))}"
  vm_domain_name           = "${var.vm_domain_name}"
  installer_hostname    = "${element(keys(var.master_node_hostname_ip), 0)}"
  compute_hostname      = "${element(keys(var.compute_node_hostname_ip), 0)}"
  random                = "${random_string.random-dir.result}"
  #######
  bastion_host          = "${var.bastion_host}"
  bastion_user          = "${var.bastion_user}"
  bastion_private_key   = "${var.bastion_private_key}"
  bastion_port          = "${var.bastion_port}"
  bastion_host_key      = "${var.bastion_host_key}"
  bastion_password      = "${var.bastion_password}"      
  dependsOn             = "${module.deployVM_master.dependsOn}+${module.deployVM_infra.dependsOn}+${module.deployVM_compute.dependsOn}"
}

module "config_inventory" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//config_inventory"
  
  private_key               = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_os_user                = "${var.vm_os_user}"
  vm_os_password            = "${var.vm_os_password}"
  master_node_hostname      = "${join(",",keys(var.master_node_hostname_ip))}"
  etcd_node_hostname        = "${join(",",keys(var.etcd_node_hostname_ip))}"
  compute_node_hostname     = "${join(",",keys(var.compute_node_hostname_ip))}"
  lb_node_hostname          = "${var.enable_lb == "false" ? "Hostname" : join(",",keys(var.lb_node_hostname_ip))}"
  enable_lb                 = "${var.enable_lb}"
  vm_domain_name            = "${var.vm_domain_name}"
  infra_node_hostname       = "${join(",",keys(var.infra_node_hostname_ip))}"
  infra_node_ip             = "${join(",",values(var.infra_node_hostname_ip))}"
  master_node_ip            = "${element(values(var.master_node_hostname_ip), 0)}"
  rh_user                   = "${var.rh_user}"
  rh_password               = "${var.rh_password}"
  compute_node_enable_glusterfs  = "${var.compute_node_enable_glusterfs}"
  random                    = "${random_string.random-dir.result}"
  
  #######
  bastion_host              = "${var.bastion_host}"
  bastion_user              = "${var.bastion_user}"
  bastion_private_key       = "${var.bastion_private_key}"
  bastion_port              = "${var.bastion_port}"
  bastion_host_key          = "${var.bastion_host_key}"
  bastion_password          = "${var.bastion_password}"      
  dependsOn                 = "${module.host_prepare.dependsOn}+${module.host_prepare_compute.dependsOn}"
}

module "run_installer" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//run_installer"
  
  private_key               = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_os_user                = "${var.vm_os_user}"
  vm_os_password            = "${var.vm_os_password}"
  master_node_ip           = "${values(var.master_node_hostname_ip)}"
  openshift_user            = "${var.openshift_user}"
  openshift_password        = "${var.openshift_password}"
  random                    = "${random_string.random-dir.result}"
  
  #######
  bastion_host              = "${var.bastion_host}"
  bastion_user              = "${var.bastion_user}"
  bastion_private_key       = "${var.bastion_private_key}"
  bastion_port              = "${var.bastion_port}"
  bastion_host_key          = "${var.bastion_host_key}"
  bastion_password          = "${var.bastion_password}"      
  dependsOn                 = "${module.config_inventory.dependsOn}"
}

module "scale_node" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=3.11//scale_node"
  
  private_key           = "${length(var.vm_os_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.vm_os_private_ssh_key)}"}"
  vm_os_user            = "${var.vm_os_user}"
  vm_os_password        = "${var.vm_os_password}"
  master_node_ip        = "${element(values(var.master_node_hostname_ip), 0)}"
  compute_node_hostname = "${keys(var.compute_node_hostname_ip)}"
  compute_node_ip       = "${values(var.compute_node_hostname_ip)}"
  vm_domain_name           = "${var.vm_domain_name}"
  random                = "${random_string.random-dir.result}"
  
  #######
  bastion_host          = "${var.bastion_host}"
  bastion_user          = "${var.bastion_user}"
  bastion_private_key   = "${var.bastion_private_key}"
  bastion_port          = "${var.bastion_port}"
  bastion_host_key      = "${var.bastion_host_key}"
  bastion_password      = "${var.bastion_password}"      
  dependsOn             = "${module.run_installer.dependsOn}"
}
