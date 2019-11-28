output "public_ip" {
  value = "${element(compact(concat(aws_instance.bootstrap.*.public_ip,list("destroyed"))), 0)}"
}
