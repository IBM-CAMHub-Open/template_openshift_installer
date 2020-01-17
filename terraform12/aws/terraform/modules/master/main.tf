resource "null_resource" "dependency_on" {
  triggers = {
    value = join("", var.dependency_on)
  }
}

resource "aws_instance" "master" {
  depends_on = [null_resource.dependency_on]

  count                       = var.node_count
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = element(var.subnet_ids, count.index % var.node_count)
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.master.name
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.volume_size //GiB
  }

  tags = merge(
    {
      "Name" = format("${var.cluster_name}-master-%d", count.index + 1)
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )

  user_data = <<EOF
{
  "ignition": {
    "version": "2.1.0",
    "config": {
      "replace": {
        "source": "s3://${var.s3_bucket}/master.ign"
      }
    }
  }
}
EOF

}

resource "aws_lb_target_group_attachment" "config_internal" {
  count            = var.node_count
  target_group_arn = var.config_internal_lb_target_group_arn
  target_id        = element(aws_instance.master.*.private_ip, count.index)
  port             = 22623
}

resource "aws_lb_target_group_attachment" "api_internal" {
  count            = var.node_count
  target_group_arn = var.api_internal_lb_target_group_arn
  target_id        = element(aws_instance.master.*.private_ip, count.index)
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_external" {
  count            = var.node_count
  target_group_arn = var.api_external_lb_target_group_arn
  target_id        = element(aws_instance.master.*.private_ip, count.index)
  port             = 6443
}

resource "aws_route53_record" "etcd_instance" {
  count   = var.node_count
  zone_id = var.cluster_route53_zone_id
  name    = format("etcd-%d.", count.index)
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.master.*.private_ip, count.index)]
}

resource "aws_route53_record" "etcd_srv" {
  zone_id = var.cluster_route53_zone_id
  name    = "_etcd-server-ssl._tcp."
  type    = "SRV"
  ttl     = "300"

  records = formatlist(
    "0 10 2380 %s.%s",
    aws_route53_record.etcd_instance.*.name,
    "${var.cluster_name}.${var.domain_name}",
  )
}

resource "aws_iam_instance_profile" "master" {
  name = "${var.cluster_name}-master-instance-profile"
  role = aws_iam_role.master.name
}

resource "aws_iam_role" "master" {
  name = "${var.cluster_name}-master_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "master" {
  name = "${var.cluster_name}-master-policy"
  role = aws_iam_role.master.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "iam:PassRole",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*",
            "Effect": "Allow"
        },
        {
            "Action": "elasticloadbalancing:*",
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF

}

