locals {
  setup_dir = "/tmp/ocp-install"
}

data "tls_public_key" "ocp" {
  private_key_pem = var.vm_private_key
}

data "template_file" "install_config" {
  template = file("${path.module}/scripts/install-config.yaml.template")

  vars = {
    base_domain        = var.domain_name
    master_node_count  = var.master_node_count
    cluster_name       = var.cluster_name
    region             = var.region
    redhat_pull_secret = var.redhat_pull_secret
    public_key         = data.tls_public_key.ocp.public_key_openssh
    vpc_cidr           = var.vpc_cidr
  }
}

resource "random_id" "setup_install" {
  byte_length = 1 # using random_id since null_resource cannot be used for module dependency hack

  connection {
    type        = "ssh"
    host        = var.bastion_public_ip
    user        = var.rhel_user
    agent       = false
    timeout     = "5m"
    private_key = var.vm_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.setup_dir}",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/setup-install.sh"
    destination = "${local.setup_dir}/setup-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > ${local.setup_dir}/install-config.yaml",
      data.template_file.install_config.rendered,
      "EOF",
      "cp ${local.setup_dir}/install-config.yaml ${local.setup_dir}/install-config.yaml.bkp",
      "chmod +x ${local.setup_dir}/setup-install.sh",
      "${local.setup_dir}/setup-install.sh ${var.aws_access_key_id} ${var.aws_secret_access_key} ${local.setup_dir} ${var.cluster_name} ${var.s3_bucket}",
    ]
  }
}

