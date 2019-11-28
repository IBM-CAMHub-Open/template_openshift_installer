resource "null_resource" "depends_on" {
  triggers = {
    value = "${join("", var.depends_on)}"
  }
}

resource "aws_instance" "worker" {
  depends_on = [
    "null_resource.depends_on",
  ]

  count                       = "${var.node_count}"
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${element(var.subnet_ids, count.index%var.node_count)}"
  vpc_security_group_ids      = ["${var.security_group_ids}"]
  iam_instance_profile        = "${aws_iam_instance_profile.worker.name}"
  associate_public_ip_address = false

  root_block_device {
    volume_size = "${var.volume_size}"
  }

  tags = "${merge(
    map("Name",  "${format("${var.cluster_name}-worker-%d", count.index + 1) }"),
    map("kubernetes.io/cluster/${var.cluster_name} ", "owned")
  )}"

  user_data = <<EOF
{
  "ignition": {
    "version": "2.1.0",
    "config": {
      "replace": {
        "source": "s3://${var.s3_bucket}/worker.ign"
      }
    }
  }
}
EOF
}

resource "aws_lb_target_group_attachment" "apps_internal" {
  count            = 2
  target_group_arn = "${var.apps_internal_lb_target_group_arn}"
  target_id        = "${element(aws_instance.worker.*.private_ip, count.index)}"
  port             = 443
}

resource "aws_lb_target_group_attachment" "apps_ext" {
  count            = 2
  target_group_arn = "${var.apps_external_lb_target_group_arn}"
  target_id        = "${element(aws_instance.worker.*.private_ip, count.index)}"
  port             = 443
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_name}-worker-instance-profile"
  role = "${aws_iam_role.worker.name}"
}

resource "aws_iam_role" "worker" {
  name = "${var.cluster_name}-worker_role"

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

resource "aws_iam_role_policy" "worker" {
  name = "${var.cluster_name}-worker-policy"
  role = "${aws_iam_role.worker.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*",
            "Effect": "Allow"
        }        
    ]
}
EOF
}
