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

variable subnet_id {
  type = "string"
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

variable config_internal_lb_target_group_arn {
  type = "string"
}

variable api_internal_lb_target_group_arn {
  type = "string"
}

variable api_external_lb_target_group_arn {
  type = "string"
}

variable s3_bucket {
  type = "string"
}
