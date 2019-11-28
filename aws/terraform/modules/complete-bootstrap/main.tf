resource "null_resource" "depends_on" {
  triggers = {
    depends_on = "${join("", var.depends_on)}"
  }
}

resource "random_id" "complete_bootstrap" {
  depends_on = [
    "null_resource.depends_on",
  ]

  byte_length = 1

  connection {
    type        = "ssh"
    host        = "${var.bastion_public_ip}"
    user        = "${var.rhel_user}"
    agent       = false
    timeout     = "30s"
    private_key = "${var.vm_private_key}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "${var.setup_dir}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${var.setup_dir}/complete-bootstrap.sh ${var.setup_dir}",
      "${var.setup_dir}/complete-bootstrap.sh ${var.setup_dir}",
    ]
  }
}
