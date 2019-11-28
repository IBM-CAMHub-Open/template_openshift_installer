#######
# AWS
#######
variable "key_pair_name" {
  type = "string"
}

variable "key_pair_private_key" {
  type = "string"
}

variable "s3_bucket" {
  type = "string"
}

##########
# Redhat 
##########
variable redhat_pull_secret {
  type = "string"
}

variable rhel_lookup {
  type = "map" //RHEL-7.7_HVM_GA

  default = {
    us-east-1      = "ami-0916c408cb02e310b"
    us-east-2      = "ami-03cfe750d5ea278f5"
    us-west-1      = "ami-0388d197bb42be9be"
    us-west-2      = "ami-04b7963c90686dd4c"
    ca-central-1   = "ami-05816666b3178f208"
    eu-west-1      = "ami-0a0d2dc2f521ddce6"
    eu-central-1   = "ami-062dacb006c5860f9"
    eu-west-2      = "ami-096fbd31de0375d2a"
    ap-northeast-1 = "ami-0dc41c7805e171046"
    ap-northeast-2 = "ami-0b5425629eb18a008"
    ap-southeast-1 = "ami-07cafca3788493264"
    ap-southeast-2 = "ami-0f1ef883e90ca71c0"
    ap-south-1     = "ami-021912f2c8d2c70c9"
    sa-east-1      = "ami-048b2348ac2ccfc53"
  }
}

variable rhcos_lookup {
  type = "map" //rhcos-410.8.20190520.0

  default = {
    us-east-1      = "ami-046fe691f52a953f9"
    us-east-2      = "ami-0649fd5d42859bdfc"
    us-west-1      = "ami-0c1d2b5606111ac8c"
    us-west-2      = "ami-00745fcbb14a863ed"
    ca-central-1   = "ami-0f907257d1686e3f7"
    eu-west-1      = "ami-0d4839574724ed3fa"
    eu-central-1   = "ami-02fdd627029c0055b"
    eu-west-2      = "ami-053073b95aa285347"
    ap-northeast-1 = "ami-0c63b39219b8123e5"
    ap-northeast-2 = "ami-073cba0913d2250a4"
    ap-southeast-1 = "ami-06eb9d35ede4f08a3"
    ap-southeast-2 = "ami-0d980796ce258b5d5"
    ap-south-1     = "ami-0270be11430101040"
    sa-east-1      = "ami-068a2000546e1889d"
  }
}

variable cos_user {
  type    = "string"
  default = "core"   //default user for core os vm; currently cannot change this in the install
}

variable rhel_user {
  type    = "string"
  default = "ec2-user" //default user for rhel  vms; currently cannot change this in the install
}

###########
# Network
###########
variable "region" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "cluster_name" {
  type = "string"
}

variable "domain_name" {
  type = "string"
}

variable "vpc_cidr" {
  type = "string"
}

variable "public_subnet_cidrs" {
  type = "list"
}

variable "private_subnet_cidrs" {
  type = "list"
}

###########
# Bastion 
###########
variable bastion_node_count {
  type = "string" //0 or 1 expected
}

variable bastion_instance_type {
  type = "string"
}

variable bastion_volume_size {
  type = "string"
}

#############
# Bootstrap
#############
variable bootstrap_node_count {
  type = "string" //0 or 1 expected
}

variable bootstrap_instance_type {
  type = "string"
}

variable bootstrap_volume_size {
  type = "string"
}

###########
# Master
###########
variable master_node_count {
  type = "string" //3 or more expected
}

variable master_instance_type {
  type = "string"
}

variable master_volume_size {
  type = "string"
}

###########
# Worker
###########
variable worker_node_count {
  type = "string" //2 or more expected
}

variable worker_instance_type {
  type = "string"
}

variable worker_volume_size {
  type = "string"
}
