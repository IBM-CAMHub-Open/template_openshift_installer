provider "aws" {
  region = var.region
}

# data "aws_ami" "rhel" {
#   most_recent = true
#   owners      = ["309956199498"]

#   filter {
#     name   = "name"
#     values = ["RHEL-7*_HVM_GA-*x86_64*"]
#   }
# }

# data "aws_ami" "rhcos" {
#   most_recent = true
#   owners      = ["531415883065"]

#   filter {
#     name   = "name"
#     values = ["rhcos-410.8.20190520.0-hvm"]
#   }
# }

resource "random_id" "cluster_id" {
  byte_length = "2"
}

locals {
  cluster_name = "${var.cluster_name}-${random_id.cluster_id.hex}"
}

module "networking" {

  source = "./modules/networking"

  region               = var.region
  cluster_name         = local.cluster_name
  domain_name          = var.domain_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "bastion" {
  source = "./modules/bastion"

  key_name      = var.key_pair_name
  cluster_name  = local.cluster_name
  volume_size   = var.bastion_volume_size
  node_count    = var.bastion_node_count
  instance_type = var.bastion_instance_type
  subnet_id     = module.networking.subnet_ocp_public_ids[0]
  ami           = var.rhel_lookup[var.region]

  security_group_ids = [
    module.networking.security_group_default_id,
    module.networking.security_group_bastion_id,
    module.networking.security_group_bootstrap_id,
    module.networking.security_group_master_id,
    module.networking.security_group_worker_id,
  ]
}

module "bootstrap" {
  source = "./modules/bootstrap"

  dependency_on                       = module.setup_install.done
  cluster_name                        = local.cluster_name
  volume_size                         = var.bootstrap_volume_size
  node_count                          = var.bootstrap_node_count
  instance_type                       = var.bootstrap_instance_type
  config_internal_lb_target_group_arn = module.networking.config_internal_lb_target_group_arn
  api_internal_lb_target_group_arn    = module.networking.api_internal_lb_target_group_arn
  api_external_lb_target_group_arn    = module.networking.api_external_lb_target_group_arn
  subnet_id                           = module.networking.subnet_ocp_public_ids[0]
  ami                                 = var.rhcos_lookup[var.region]
  s3_bucket                           = var.s3_bucket
  security_group_ids                  = [module.networking.security_group_default_id, module.networking.security_group_bootstrap_id, module.networking.security_group_master_id]
}

module "master" {
  source = "./modules/master"

  dependency_on                       = [module.setup_install.done]
  cluster_name                        = local.cluster_name
  domain_name                         = var.domain_name
  volume_size                         = var.master_volume_size
  node_count                          = var.master_node_count
  instance_type                       = var.master_instance_type
  config_internal_lb_target_group_arn = module.networking.config_internal_lb_target_group_arn
  api_internal_lb_target_group_arn    = module.networking.api_internal_lb_target_group_arn
  api_external_lb_target_group_arn    = module.networking.api_external_lb_target_group_arn
  cluster_route53_zone_id             = module.networking.cluster_route53_zone_id
  subnet_ids                          = module.networking.subnet_ocp_private_ids
  ami                                 = var.rhcos_lookup[var.region]
  s3_bucket                           = var.s3_bucket
  security_group_ids                  = [module.networking.security_group_default_id, module.networking.security_group_master_id]
}

module "worker" {
  source = "./modules/worker"

  dependency_on                     = [module.complete_bootstrap.done]
  cluster_name                      = local.cluster_name
  volume_size                       = var.worker_volume_size
  node_count                        = var.worker_node_count
  instance_type                     = var.worker_instance_type
  apps_external_lb_target_group_arn = module.networking.apps_external_lb_target_group_arn
  apps_internal_lb_target_group_arn = module.networking.apps_internal_lb_target_group_arn
  subnet_ids                        = module.networking.subnet_ocp_private_ids
  ami                               = var.rhcos_lookup[var.region]
  s3_bucket                         = var.s3_bucket
  security_group_ids                = [module.networking.security_group_default_id, module.networking.security_group_worker_id]

  bastion_public_ip = module.bastion.public_ip
  rhel_user         = var.rhel_user
  vm_private_key    = base64decode(var.key_pair_private_key)
  setup_dir         = module.setup_install.setup_dir
}

module "get_aws_credentials" {
  source = "./modules/aws-credentials"
}

module "setup_install" {
  source = "./modules/setup-install"

  region                = var.region
  cluster_name          = local.cluster_name
  domain_name           = var.domain_name
  redhat_pull_secret    = base64decode(var.redhat_pull_secret)
  bastion_public_ip     = module.bastion.public_ip
  rhel_user             = var.rhel_user
  vm_private_key        = base64decode(var.key_pair_private_key)
  aws_access_key_id     = module.get_aws_credentials.access_key_id
  aws_secret_access_key = module.get_aws_credentials.secret_access_key
  s3_bucket             = var.s3_bucket
  master_node_count     = var.master_node_count
  vpc_cidr              = var.vpc_cidr
}

module "complete_bootstrap" {
  source = "./modules/complete-bootstrap"

  dependency_on = "${module.bootstrap.public_ip},${join(",",module.master.master_private_ips)}"

  setup_dir         = module.setup_install.setup_dir
  bastion_public_ip = module.bastion.public_ip
  rhel_user         = var.rhel_user
  vm_private_key    = base64decode(var.key_pair_private_key)
}

module "complete_install" {
  source = "./modules/complete-install"

  dependency_on     = "${join(",", module.worker.worker_private_ips)}, ${join(",", module.master.master_private_ips)}"
  setup_dir         = module.setup_install.setup_dir
  bastion_public_ip = module.bastion.public_ip
  rhel_user         = var.rhel_user
  vm_private_key    = base64decode(var.key_pair_private_key)
  total_nodes       = length(module.worker.worker_private_ips) + length(module.master.master_private_ips)
}
