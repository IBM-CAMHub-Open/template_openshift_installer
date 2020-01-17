output "security_group_default_id" {
  value = aws_security_group.default.id
}

output "security_group_master_id" {
  value = aws_security_group.master.id
}

output "security_group_worker_id" {
  value = aws_security_group.worker.id
}

output "security_group_bootstrap_id" {
  value = aws_security_group.bootstrap.id
}

output "security_group_bastion_id" {
  value = aws_security_group.bastion.id
}

output "subnet_ocp_public_ids" {
  value = aws_subnet.ocp_public.*.id
}

output "subnet_ocp_private_ids" {
  value = aws_subnet.ocp_private.*.id
}

output "config_internal_lb_target_group_arn" {
  value = aws_lb_target_group.config_internal.arn
}

output "api_internal_lb_target_group_arn" {
  value = aws_lb_target_group.api_internal.arn
}

output "api_external_lb_target_group_arn" {
  value = aws_lb_target_group.api_external.arn
}

output "apps_external_lb_target_group_arn" {
  value = aws_lb_target_group.apps_external.arn
}

output "apps_internal_lb_target_group_arn" {
  value = aws_lb_target_group.apps_internal.arn
}

output "cluster_route53_zone_id" {
  value = aws_route53_zone.cluster.zone_id
}

