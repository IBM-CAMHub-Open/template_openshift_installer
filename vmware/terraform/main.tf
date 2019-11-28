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

#Get from ENV
data "external" "get_vcenter_details" {
  program = ["/bin/bash", "./scripts/get_vcenter_details.sh"]
}

locals{
	vcenter="${data.external.get_vcenter_details.result["vcenter"]}"
	vcenteruser="${data.external.get_vcenter_details.result["vcenteruser"]}"
	vcenterpassword="${data.external.get_vcenter_details.result["vcenterpassword"]}"
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

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

module "folder" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/folder"

  path          = "${var.clustername}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

module "resource_pool" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/resource_pool"

  name            = "${var.clustername}"
  datacenter_id   = "${data.vsphere_datacenter.dc.id}"
  vsphere_cluster = "${var.vsphere_cluster}"
}

module "deployVM_infranode" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/vmware_infravm_provision"

  #######
  vsphere_datacenter    = "${var.vsphere_datacenter}"
  vsphere_resource_pool = "${var.vsphere_resource_pool}"
  vm_ipv4_private_address = "${var.infra_private_ipv4_address}"
  vm_private_ipv4_prefix_length = "${var.infra_private_ipv4_prefix_length}"
  vm_vcpu                    = "${var.infranode_vcpu}"
  vm_name                    = "${var.infranode_hostname}"
  vm_memory                  = "${var.infranode_memory}"
  vm_template                = "${var.infranode_vm_template}"
  vm_os_password             = "${var.infranode_vm_os_password}"
  vm_os_user                 = "${var.infranode_vm_os_user}"
  vm_domain                  = "${var.vm_domain_name}"
  vm_folder                  = "${var.vm_folder}"
  vm_private_ssh_key         = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}"     : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_public_ssh_key          = "${length(var.infra_public_ssh_key)  == 0 ? "${tls_private_key.generate.public_key_openssh}"  : "${var.infra_public_ssh_key}"}"
  vm_public_network_interface_label = "${var.vm_public_network_interface_label}"
  vm_private_network_interface_label = "${var.vm_private_network_interface_label}"
  vm_ipv4_gateway            = "${var.infranode_vm_ipv4_gateway}"
  vm_ipv4_address            = "${var.infranode_ip}"
  vm_ipv4_prefix_length      = "${var.infranode_vm_ipv4_prefix_length}"
  vm_private_adapter_type            = "${var.vm_private_adapter_type}"
  vm_public_adapter_type            = "${var.vm_public_adapter_type}"
  vm_disk1_size              = "${var.infranode_vm_disk1_size}"
  vm_disk1_datastore         = "${var.infranode_vm_disk1_datastore}"
  vm_disk1_keep_on_remove    = "${var.infranode_vm_disk1_keep_on_remove}"
  vm_disk2_enable            = "${var.infranode_vm_disk2_enable}"
  vm_disk2_size              = "${var.infranode_vm_disk2_size}"
  vm_disk2_datastore         = "${var.infranode_vm_disk2_datastore}"
  vm_disk2_keep_on_remove    = "${var.infranode_vm_disk2_keep_on_remove}"
  vm_dns_servers             = "${var.vm_dns_servers}"
  vm_dns_suffixes            = "${var.vm_dns_suffixes}"
  vm_clone_timeout        = "${var.vm_clone_timeout}"
  random                     = "${random_string.random-dir.result}"
  
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"  
}

module "NFSServer-Setup" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_nfs_server"
  
  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  nfs_drive            = "/dev/sdb"
  nfs_link_folders     = "${var.nfs_link_folders}"
  enable_nfs           = "${var.enable_nfs}"
  #######
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"        
  dependsOn            = "${module.deployVM_infranode.dependsOn}"
}

module "HTTPServer-Setup" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_apache_web_server"
  
  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"        
  dependsOn            = "${module.NFSServer-Setup.dependsOn}"
}

module "HAProxy-install" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_lb_server" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"     
  install			 	= "true"   
  dependsOn            = "${module.HTTPServer-Setup.dependsOn}"
}

module "vmware_ign_config" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/vmware_ign_config"
  
  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key_base64    = "${length(var.infra_private_ssh_key) == 0 ? "${base64encode(tls_private_key.generate.private_key_pem)}" : "${var.infra_private_ssh_key}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"        
  dependsOn            = "${module.HAProxy-install.dependsOn}"
  ocversion			= "${var.ocversion}"  
  domain			= "${var.ocp_cluster_domain}"
  clustername 		= "${var.clustername}"
  controlnodes 		= "${var.control_plane_count}"
  computenodes 		= "${var.compute_count}"
  vcenter			= "${local.vcenter}"
  vcenteruser		= "${local.vcenteruser}"
  vcenterpassword	= "${local.vcenterpassword}"
  vcenterdatacenter    = "${var.vsphere_datacenter}"
  vmwaredatastore 	= "${var.infranode_vm_disk1_datastore}"  
  pullsecret		= "${var.pullsecret}"  
  vm_ipv4_private_address = "${var.infra_private_ipv4_address}"
}

module "prepare_dns" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_dns"
  
  dns_server_ip     = "${var.infranode_ip}"
  vm_os_user        = "${var.infranode_vm_os_user}"
  vm_os_password    = "${var.infranode_vm_os_password}"
  private_key       = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  action            = "setup"
  domain_name       = "${var.ocp_cluster_domain}"
  cluster_name      = "${var.clustername}"  
  cluster_ip        = "${var.infra_private_ipv4_address}"

  ## Access to optional bastion host
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
  dependsOn            = "${module.vmware_ign_config.dependsOn}"
}

module "prepare_dhcp" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_dns"
  
  dns_server_ip     = "${var.infranode_ip}"
  vm_os_user        = "${var.infranode_vm_os_user}"
  vm_os_password    = "${var.infranode_vm_os_password}"
  private_key       = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  action            = "dhcp"
  dhcp_interface    = "${module.vmware_ign_config.private_interface}"
  dhcp_router_ip    = "${var.infra_private_ipv4_address}"
  dhcp_ip_range_start = "${var.dhcp_ip_range_start}"
  dhcp_ip_range_end = "${var.dhcp_ip_range_end}"
  dhcp_netmask = "${var.dhcp_netmask}"
  dhcp_lease_time = "${var.dhcp_lease_time}"

  ## Access to optional bastion host
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
  dependsOn            = "${module.prepare_dns.dependsOn}"
}

module "bootstrap" {
  source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/machine_boot"
  wait_for_guest_net_timeout = "${var.vm_clone_timeout}"
  name             = "bootstrap"
  instance_count   = "1"
  ignition         = "${module.vmware_ign_config.bootstrap_sec_ign}"
  resource_pool_id = "${module.resource_pool.pool_id}"
  datastore        = "${var.vsphere_datastore}"
  folder           = "${module.folder.path}"
  network          = "${var.vm_private_network_interface_label}"
  datacenter_id    = "${data.vsphere_datacenter.dc.id}"
  template         = "${var.ocp_vm_template}"
  memory           = "${var.ocp_boot_vm_memory}"
  cpu              = "${var.ocp_boot_vm_cpu}"
  disk_size        = "${var.ocp_boot_vm_disk_size}"
  #use_static_mac   = "${var.use_static_mac}"
  #mac_address      = "${var.mac_address_boot}"
  dependsOn        = "${module.prepare_dhcp.dependsOn}"
}

module "HAProxy-config-boot" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_lb_server" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"     
  is_boot			 	= "true"   
  configure_api_url   = "true"
  vm_ipv4_controlplane_addresses = "${join(",", flatten(module.bootstrap.ip))}"
  dependsOn            = "${module.bootstrap.dependsOn}"
}

module "wait_for_master_api_url" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/wait_for_api_url" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
  ocp_domain			= "${var.ocp_cluster_domain}"
  ocp_cluster_name 		= "${var.clustername}"    
  api_type				= "master"       
  dependsOn            = "${module.HAProxy-config-boot.dependsOn}"
}

module "control_plane" {
   source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/machine_boot"
   wait_for_guest_net_timeout = "${var.vm_clone_timeout}"
   name             = "control-plane"
   instance_count   = "${var.control_plane_count}"
   ignition         = "${module.vmware_ign_config.master_ign}"
   resource_pool_id = "${module.resource_pool.pool_id}"
   folder           = "${module.folder.path}"
   datastore        = "${var.vsphere_datastore}"
   network          = "${var.vm_private_network_interface_label}"
   datacenter_id    = "${data.vsphere_datacenter.dc.id}"
   template         = "${var.ocp_vm_template}"
   memory           = "${var.ocp_control_vm_memory}"
   cpu              = "${var.ocp_control_vm_cpu}"
   disk_size        = "${var.ocp_control_vm_disk_size}"
   #use_static_mac   = "${var.use_static_mac}"
   #mac_address      = "${var.mac_address_control}"
   dependsOn        = "${module.wait_for_master_api_url.dependsOn}"
 }
 
 module "set_dns_control" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_dns"
  
  dns_server_ip     = "${var.infranode_ip}"
  vm_os_user        = "${var.infranode_vm_os_user}"
  vm_os_password    = "${var.infranode_vm_os_password}"
  private_key       = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  action            = "addMaster"
  domain_name       = "${var.ocp_cluster_domain}"
  cluster_name      = "${var.clustername}"  
  cluster_ip        = "${var.infra_private_ipv4_address}"
  node_ips          = "${join(",", flatten(module.control_plane.ip))}"
  node_names        = "${join(",", flatten(module.control_plane.name))}"
  dependsOn            = "${module.control_plane.dependsOn}"
  ## Access to optional bastion host
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
}

module "monitor_controlplane_bootstrap" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/monitor_controlplane_bootstrap" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"       
  boot_ipv4_address = "${join(",", flatten(module.bootstrap.ip))}"
  dependsOn            = "${module.set_dns_control.dependsOn}"
}

module "HAProxy-config-control" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_lb_server" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"       
  configure_api_url   = "true"
  vm_ipv4_controlplane_addresses = "${join(",", flatten(module.control_plane.ip))}"
  dependsOn            = "${module.monitor_controlplane_bootstrap.dependsOn}"    
}

module "HAProxy-remove-boot" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_lb_server" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
  remove_api_url   = "true"
  vm_ipv4_controlplane_addresses = "${join(",", flatten(module.bootstrap.ip))}"
  dependsOn            = "${module.HAProxy-config-control.dependsOn}"
}

module "wait_for_worker_api_url" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/wait_for_api_url" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
  ocp_domain			= "${var.ocp_cluster_domain}"
  ocp_cluster_name 		= "${var.clustername}"    
  api_type				= "worker"       
  dependsOn            = "${module.HAProxy-remove-boot.dependsOn}"
}

module "compute" {
   source = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/machine_boot"
   wait_for_guest_net_timeout = "${var.vm_clone_timeout}"
   name             = "compute"
   instance_count   = "${var.compute_count}"
   ignition         = "${module.vmware_ign_config.worker_ign}"
   resource_pool_id = "${module.resource_pool.pool_id}"
   folder           = "${module.folder.path}"
   datastore        = "${var.vsphere_datastore}"
   network          = "${var.vm_private_network_interface_label}"
   datacenter_id    = "${data.vsphere_datacenter.dc.id}"
   template         = "${var.ocp_vm_template}"
   memory           = "${var.ocp_compute_vm_memory}"
   cpu              = "${var.ocp_compute_vm_cpu}"
   disk_size        = "${var.ocp_compute_vm_disk_size}"
   #use_static_mac   = "${var.use_static_mac}"
   #mac_address      = "${var.mac_address_compute}"
   dependsOn        = "${module.wait_for_worker_api_url.dependsOn}"
}

module "set_dns_compute" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_dns"

  dns_server_ip     = "${var.infranode_ip}"
  vm_os_user        = "${var.infranode_vm_os_user}"
  vm_os_password    = "${var.infranode_vm_os_password}"
  private_key       = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  action            = "addWorker"
  domain_name       = "${var.ocp_cluster_domain}"
  cluster_name      = "${var.clustername}"  
  cluster_ip        = "${var.infra_private_ipv4_address}"
  node_ips          = "${join(",", flatten(module.compute.ip))}"  
  node_names        = "${join(",", flatten(module.compute.name))}"  
  dependsOn            = "${module.compute.dependsOn}"
  ## Access to optional bastion host
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"
}

module "HAProxy-config-compute" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_lb_server" 

  vm_ipv4_address      = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"       
  configure_app_url   = "true"
  vm_ipv4_worker_addresses = "${join(",", flatten(module.compute.ip))}"
  dependsOn            = "${module.set_dns_compute.dependsOn}"
}

module "complete_bootstrap" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/complete_bootstrap" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"       
  dependsOn            = "${module.HAProxy-config-compute.dependsOn}"
  ocp_domain			= "${var.ocp_cluster_domain}"
  ocp_cluster_name 		= "${var.clustername}"    
  number_nodes =    "${var.compute_count + var.control_plane_count}"
}

module "config_image_registry" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/config_image_registry" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"      
  nfs_ipv4_address    =  "${var.infra_private_ipv4_address}"
  nfs_path            =   "/var/nfs/registry"
  dependsOn            = "${module.complete_bootstrap.dependsOn}"
}

module "complete_install" {
  source               = "git::https://github.com/IBM-CAMHub-Open/template_openshift_modules.git?ref=4.2//vmware/complete_install" 

  vm_ipv4_address = "${var.infranode_ip}"
  vm_os_private_key    = "${length(var.infra_private_ssh_key) == 0 ? "${tls_private_key.generate.private_key_pem}" : "${base64decode(var.infra_private_ssh_key)}"}"
  vm_os_user           = "${var.infranode_vm_os_user}"
  vm_os_password       = "${var.infranode_vm_os_password}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  bastion_port        = "${var.bastion_port}"
  bastion_host_key    = "${var.bastion_host_key}"
  bastion_password    = "${var.bastion_password}"       
  dependsOn            = "${module.config_image_registry.dependsOn}"
}