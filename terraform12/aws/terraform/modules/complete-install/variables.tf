variable "dependency_on" {
  type    = string
  default = ""
}

variable "bastion_public_ip" {
  type = string
}

variable "rhel_user" {
  type = string
}

variable "vm_private_key" {
  type = string
}

variable "setup_dir" {
  type = string
}

variable "total_nodes" {
  type = string
}

