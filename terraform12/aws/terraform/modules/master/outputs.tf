output "master_private_ips" {
  value = aws_instance.master.*.private_ip
}

