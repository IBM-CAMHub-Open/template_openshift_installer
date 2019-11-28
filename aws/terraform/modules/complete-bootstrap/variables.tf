variable depends_on {
  type    = "list"
  default = [""]
}

variable bastion_public_ip {
  type = "string"
}

variable rhel_user {
  type = "string"
}

variable vm_private_key {
  type = "string"
}

variable setup_dir {
  type = "string"
}
