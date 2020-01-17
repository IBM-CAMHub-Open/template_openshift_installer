output "worker_private_ips" {
  value = aws_instance.worker.*.private_ip
}

