variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

