#infra Node
variable "infra_hostname_ip" {
  type = "map"
}

variable "infra_vcpu" {
  type    = "string"
  default = "4"
}

variable "infra_memory" {
  type    = "string"
  default = "8192"
}

variable "infra_vm_ipv4_gateway" {
  type = "string"
}

variable "infra_vm_ipv4_prefix_length" {
  type = "string"
}

variable "infra_vm_disk1_size" {
  type = "string"

  default = "150"
}

variable "infra_vm_disk1_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "infra_vm_disk2_enable" {
  type = "string"

  default = "false"
}

variable "infra_vm_disk2_size" {
  type = "string"

  default = "50"
}

variable "infra_vm_disk2_keep_on_remove" {
  type = "string"

  default = "false"
}

# Master Nodes
variable "master_hostname_ip" {
  type = "map"
}

variable "master_vcpu" {
  type = "string"

  default = "8"
}

variable "master_memory" {
  type = "string"

  default = "16384"
}

variable "master_vm_ipv4_gateway" {
  type = "string"
}

variable "master_vm_ipv4_prefix_length" {
  type = "string"
}

variable "master_vm_disk1_size" {
  type = "string"

  default = "200"
}

variable "master_vm_disk1_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "master_vm_disk2_enable" {
  type = "string"

  default = "false"
}

variable "master_vm_disk2_size" {
  type = "string"

  default = "50"
}

variable "master_vm_disk2_keep_on_remove" {
  type = "string"

  default = "false"
}

# lb Node
variable "enable_lb" {
  type    = "string"
  default = "false"
}

variable "lb_hostname_ip" {
  type = "map"
}

variable "lb_vcpu" {
  type = "string"

  default = "8"
}

variable "lb_memory" {
  type = "string"

  default = "16384"
}

variable "lb_vm_ipv4_gateway" {
  type = "string"
}

variable "lb_vm_ipv4_prefix_length" {
  type = "string"
}

variable "lb_vm_disk1_size" {
  type = "string"

  default = "200"
}

variable "lb_vm_disk1_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "lb_vm_disk2_enable" {
  type = "string"

  default = "false"
}

variable "lb_vm_disk2_size" {
  type = "string"

  default = "50"
}

variable "lb_vm_disk2_keep_on_remove" {
  type = "string"

  default = "false"
}

# etcd Nodes
variable "etcd_hostname_ip" {
  type = "map"
}

variable "etcd_vcpu" {
  type = "string"

  default = "8"
}

variable "etcd_memory" {
  type = "string"

  default = "16384"
}

variable "etcd_vm_ipv4_gateway" {
  type = "string"
}

variable "etcd_vm_ipv4_prefix_length" {
  type = "string"
}

variable "etcd_vm_disk1_size" {
  type = "string"

  default = "200"
}

variable "etcd_vm_disk1_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "etcd_vm_disk2_enable" {
  type = "string"

  default = "false"
}

variable "etcd_vm_disk2_size" {
  type = "string"

  default = "50"
}

variable "etcd_vm_disk2_keep_on_remove" {
  type = "string"

  default = "false"
}

# computes Nodes
variable "compute_hostname_ip" {
  type = "map"
}

variable "compute_vcpu" {
  type = "string"

  default = "16"
}

variable "compute_memory" {
  type = "string"

  default = "32768"
}

variable "compute_vm_ipv4_gateway" {
  type = "string"
}

variable "compute_vm_ipv4_prefix_length" {
  type = "string"
}

variable "compute_vm_disk1_size" {
  type = "string"

  default = "200"
}

variable "compute_vm_disk1_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "compute_vm_disk2_enable" {
  type = "string"

  default = "true"
}

variable "compute_vm_disk2_size" {
  type = "string"

  default = "85"
}

variable "compute_vm_disk2_keep_on_remove" {
  type = "string"

  default = "false"
}

variable "compute_enable_glusterFS" {
  type = "string"

  default = "true"
}

# VM Generic Items
variable "vm_domain" {
  type = "string"
}

variable "vm_network_interface_label" {
  type = "string"
}

variable "vm_adapter_type" {
  type    = "string"
  default = "vmxnet3"
}

variable "vm_folder" {
  type = "string"
}

variable "vm_dns_servers" {
  type = "list"
}

variable "vm_dns_suffixes" {
  type = "list"
}

variable "vm_clone_timeout" {
  description = "The timeout, in minutes, to wait for the virtual machine clone to complete."
  default = "30"
}

variable "vsphere_datacenter" {
  type = "string"
}

variable "vsphere_resource_pool" {
  type = "string"
}

variable "vm_template" {
  type = "string"
}

variable "vm_os_user" {
  type = "string"
}

variable "vm_os_password" {
  type = "string"
}

variable "vm_disk1_datastore" {
  type = "string"
}

variable "vm_disk2_datastore" {
  type = "string"
}

# SSH KEY Information
variable "os_private_ssh_key" {
  type = "string"

  default = ""
}

variable "os_public_ssh_key" {
  type = "string"

  default = ""
}

variable "rh_user" {
  type = "string"
}

variable "rh_password" {
  type = "string"
}

variable "openshift_user" {
  type = "string"
}

variable "openshift_password" {
  type = "string"
}