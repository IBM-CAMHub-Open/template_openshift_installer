variable "key_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "subnet_id" {
  type = string
}

variable "ami" {
  type = string
}

variable "node_count" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "volume_size" {
  type = string
}

