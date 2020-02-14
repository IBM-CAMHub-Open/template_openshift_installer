variable "dependency_on" {
  type    = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
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

variable "redhat_pull_secret" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "master_node_count" {
  type = string //3 or more expected
}

