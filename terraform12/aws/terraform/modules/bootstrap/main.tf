resource "null_resource" "dependency_on" {
  triggers = {
    dependency_on = var.dependency_on
  }
}

resource "aws_instance" "bootstrap" {
  depends_on = [null_resource.dependency_on]

  count                       = var.node_count
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.bootstrap[0].name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.volume_size //GiB
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-bootstrap"
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
        "source": "s3://${var.s3_bucket}/bootstrap.ign"
      }
    }
  }
}
EOF

}

resource "aws_lb_target_group_attachment" "config_internal" {
  count            = var.node_count
  target_group_arn = var.config_internal_lb_target_group_arn
  target_id        = aws_instance.bootstrap[0].private_ip
  port             = 22623
}

resource "aws_lb_target_group_attachment" "api_internal" {
  count            = var.node_count
  target_group_arn = var.api_internal_lb_target_group_arn
  target_id        = aws_instance.bootstrap[0].private_ip
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_external" {
  count            = var.node_count
  target_group_arn = var.api_external_lb_target_group_arn
  target_id        = aws_instance.bootstrap[0].private_ip
  port             = 6443
}

resource "aws_iam_instance_profile" "bootstrap" {
  count = var.node_count
  name  = "${var.cluster_name}-bootstrap-instance-profile"
  role  = aws_iam_role.bootstrap[0].name
}

resource "aws_iam_role" "bootstrap" {
  count = var.node_count
  name  = "${var.cluster_name}-bootstrap_role"

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

resource "aws_iam_role_policy" "bootstrap" {
  count = var.node_count
  name  = "${var.cluster_name}-bootstrap-policy"
  role  = aws_iam_role.bootstrap[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:Describe*",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "ec2:AttachVolume",
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
            "Action": "ec2:DetachVolume",
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF

}

