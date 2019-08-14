#infra Node
variable "infra_node_hostname_ip" {
  type = "map"
}

variable "infra_node_vcpu" {
  type    = "string"
}

variable "infra_node_memory" {
  type    = "string"
}

variable "infra_node_disk1_size" {
  type = "string"
}

variable "infra_node_disk1_keep_on_remove" {
  type = "string"
}

# Master Nodes
variable "master_node_hostname_ip" {
  type = "map"
}

variable "master_node_vcpu" {
  type = "string"
}

variable "master_node_memory" {
  type = "string"
}

variable "master_node_disk1_size" {
  type = "string"
}

variable "master_node_disk1_keep_on_remove" {
  type = "string"
}

# lb Node
variable "enable_lb" {
  type    = "string"
  default = "false"
}

variable "lb_node_hostname_ip" {
  type = "map"
}

variable "lb_node_vcpu" {
  type = "string"
}

variable "lb_node_memory" {
  type = "string"
}


variable "lb_node_disk1_size" {
  type = "string"
}

variable "lb_node_disk1_keep_on_remove" {
  type = "string"
}


# etcd Nodes
variable "etcd_node_hostname_ip" {
  type = "map"
}

variable "etcd_node_vcpu" {
  type = "string"
}

variable "etcd_node_memory" {
  type = "string"
}

variable "etcd_node_disk1_size" {
  type = "string"
}

variable "etcd_node_disk1_keep_on_remove" {
  type = "string"
}

# computes Nodes
variable "compute_node_hostname_ip" {
  type = "map"
}

variable "compute_node_vcpu" {
  type = "string"
}

variable "compute_node_memory" {
  type = "string"
}

variable "compute_node_disk1_size" {
  type = "string"
}

variable "compute_node_disk1_keep_on_remove" {
  type = "string"
}

variable "compute_node_disk2_enable" {
  type = "string"
}

variable "compute_node_disk2_size" {
  type = "string"
}

variable "compute_node_disk2_keep_on_remove" {
  type = "string"
}

variable "compute_enable_glusterFS" {
  type = "string"
  default = "true"
}

variable "vm_ipv4_gateway" {
  type = "string"
}

variable "vm_ipv4_netmask" {
  type = "string"
}

variable "vm_domain_name" {
  type = "string"
}

variable "network" {
  type = "string"
}

variable "adapter_type" {
  type    = "string"
  default = "vmxnet3"
}

variable "vm_folder" {
  type = "string"
}

variable "dns_servers" {
  type = "list"
}

variable "dns_suffixes" {
  type = "list"
}

variable "vm_clone_timeout" {
  description = "The timeout, in minutes, to wait for the virtual machine clone to complete."
  default = "30"
}

variable "datacenter" {
  type = "string"
}

variable "resource_pool" {
  type = "string"
}

variable "vm_image_template" {
  type = "string"
}

variable "vm_os_user" {
  type = "string"
}

variable "vm_os_password" {
  type = "string"
}

variable "datastore" {
  type = "string"
}

variable "vm_os_private_ssh_key" {
  type = "string"
}

variable "vm_os_public_ssh_key" {
  type = "string"
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