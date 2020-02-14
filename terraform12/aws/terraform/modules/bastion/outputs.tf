output "public_ip" {
  value = element(
    compact(concat(aws_instance.bastion.*.public_ip, ["destroyed"])),
    0,
  )
}

output "dependency_on" {
  value       = null_resource.bastion_created.id
  description = "Output Parameter set when the module execution is completed"
}

