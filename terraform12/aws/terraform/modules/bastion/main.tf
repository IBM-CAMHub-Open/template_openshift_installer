resource "aws_instance" "bastion" {
  count                       = var.node_count
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size = var.volume_size //GiB
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-bastion"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

