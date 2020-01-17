output "public_ip" {
  value = element(
    compact(concat(aws_instance.bastion.*.public_ip, ["destroyed"])),
    0,
  )
}

