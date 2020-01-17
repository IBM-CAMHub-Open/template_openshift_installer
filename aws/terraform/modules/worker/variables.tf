// Hack to force terraform module to wait for other module(s) completion
variable depends_on {
  type    = "list"
  default = [""]
}

variable cluster_name {
  type = "string"
}

variable security_group_ids {
  type = "list"
}

variable subnet_ids {
  type = "list"
}

variable ami {
  type = "string"
}

variable node_count {
  type = "string"
}

variable instance_type {
  type = "string"
}

variable volume_size {
  type = "string"
}

variable apps_external_lb_target_group_arn {
  type = "string"
}

variable apps_internal_lb_target_group_arn {
  type = "string"
}

variable s3_bucket {
  type = "string"
}

variable "bastion_public_ip" {
  type = "string"
}

variable "rhel_user" {
  type = "string"
}

variable "vm_private_key" {
  type = "string"
}

variable "setup_dir" {
  type = "string"
}