resource "aws_vpc" "ocp" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      "Name" = var.cluster_name
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_subnet" "ocp_public" {
  count      = length(var.availability_zones)
  vpc_id     = aws_vpc.ocp.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = format(
    "${var.region}%s",
    element(var.availability_zones, count.index),
  )
  map_public_ip_on_launch = false

  tags = merge(
    {
      "Name" = format("${var.cluster_name}-public-%d", count.index + 1)
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_subnet" "ocp_private" {
  count      = length(var.availability_zones)
  vpc_id     = aws_vpc.ocp.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = format(
    "${var.region}%s",
    element(var.availability_zones, count.index),
  )

  tags = merge(
    {
      "Name" = format("${var.cluster_name}-private-%d", count.index + 1)
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

//used fo NATs
resource "aws_eip" "ocp" {
  count = length(var.availability_zones)
  vpc   = "true"

  tags = merge(
    {
      "Name" = "${var.cluster_name}-%d"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_internet_gateway" "ocp" {
  vpc_id = aws_vpc.ocp.id
}

resource "aws_nat_gateway" "ocp" {
  count         = length(var.availability_zones)
  allocation_id = element(aws_eip.ocp.*.id, count.index)
  subnet_id     = element(aws_subnet.ocp_public.*.id, count.index)

  tags = merge(
    {
      "Name" = var.cluster_name
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )

  depends_on = [aws_internet_gateway.ocp]
}

resource "aws_route_table" "ocp_private_network" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.ocp.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ocp.*.id, count.index)
  }

  tags = merge(
    {
      "Name" = format("${var.cluster_name}-private-%1d", count.index + 1)
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_route_table" "ocp_public_network" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.ocp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_internet_gateway.ocp.*.id, count.index)
  }

  tags = merge(
    {
      "Name" = format("${var.cluster_name}-public-%1d", count.index + 1)
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_route_table_association" "a_private" {
  count          = length(var.availability_zones)
  subnet_id      = element(aws_subnet.ocp_private.*.id, count.index)
  route_table_id = element(aws_route_table.ocp_private_network.*.id, count.index)
}

resource "aws_route_table_association" "a_public" {
  count          = length(var.availability_zones)
  subnet_id      = element(aws_subnet.ocp_public.*.id, count.index)
  route_table_id = element(aws_route_table.ocp_public_network.*.id, count.index)
}

data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.ocp.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.availability_zones)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.ocp_private_network.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count           = length(var.availability_zones)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.ocp_public_network.*.id, count.index)
}

resource "aws_lb" "ocp_internal" {
  name                             = "${var.cluster_name}-int"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = aws_subnet.ocp_private.*.id
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "apps_internal" {
  name                 = "${var.cluster_name}-apps-int"
  port                 = 443
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = aws_vpc.ocp.id
}

resource "aws_lb_listener" "apps_internal" {
  load_balancer_arn = aws_lb.ocp_internal.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apps_internal.arn
  }
}

resource "aws_lb_target_group" "api_internal" {
  name                 = "${var.cluster_name}-api-int"
  port                 = 6443
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = aws_vpc.ocp.id
}

resource "aws_lb_listener" "api_internal" {
  load_balancer_arn = aws_lb.ocp_internal.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_internal.arn
  }
}

resource "aws_lb_listener" "config_internal" {
  load_balancer_arn = aws_lb.ocp_internal.arn
  port              = 22623
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_internal.arn
  }
}

resource "aws_lb_target_group" "config_internal" {
  name                 = "${var.cluster_name}-config-int"
  port                 = 22623
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = aws_vpc.ocp.id
}

resource "aws_lb" "ocp_external" {
  depends_on = [aws_internet_gateway.ocp]

  name                             = "${var.cluster_name}-ext"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = aws_subnet.ocp_public.*.id
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "api_external" {
  name                 = "${var.cluster_name}-api-ext"
  port                 = 6443
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = aws_vpc.ocp.id
}

resource "aws_lb_listener" "api_external" {
  load_balancer_arn = aws_lb.ocp_external.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_external.arn
  }
}

resource "aws_lb_target_group" "apps_external" {
  name                 = "${var.cluster_name}-apps-ext"
  port                 = 443
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 60
  vpc_id               = aws_vpc.ocp.id
}

resource "aws_lb_listener" "apps_external" {
  load_balancer_arn = aws_lb.ocp_external.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apps_external.arn
  }
}

data "aws_route53_zone" "public" {
  name = var.domain_name
}

resource "aws_route53_record" "api_public" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "api.${var.cluster_name}."
  type    = "A"

  alias {
    name                   = aws_lb.ocp_external.dns_name
    zone_id                = aws_lb.ocp_external.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apps_public" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "*.apps.${var.cluster_name}."
  type    = "A"

  alias {
    name                   = aws_lb.ocp_external.dns_name
    zone_id                = aws_lb.ocp_external.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_zone" "cluster" {
  name          = "${var.cluster_name}.${var.domain_name}"
  force_destroy = "true"

  vpc {
    vpc_id = aws_vpc.ocp.id
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "api."
  type    = "A"

  alias {
    name                   = aws_lb.ocp_internal.dns_name
    zone_id                = aws_lb.ocp_internal.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_int" {
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "api-int."
  type    = "A"

  alias {
    name                   = aws_lb.ocp_internal.dns_name
    zone_id                = aws_lb.ocp_internal.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apps_private" {
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "*.apps."
  type    = "A"

  alias {
    name                   = aws_lb.ocp_internal.dns_name
    zone_id                = aws_lb.ocp_internal.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "default" {
  vpc_id = aws_vpc.ocp.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-default"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
}

resource "aws_security_group" "master" {
  name   = "${var.cluster_name}-master"
  vpc_id = aws_vpc.ocp.id

  ingress {
    from_port = 10250
    to_port   = 10259
    protocol  = "tcp"
    self      = true

    security_groups = [
      aws_security_group.worker.id,
    ]
  }

  ingress {
    from_port = 30000
    to_port   = 32767
    protocol  = "tcp"
    self      = true

    security_groups = [
      aws_security_group.worker.id,
    ]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 22623
    to_port     = 22623
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port = 9000
    to_port   = 9999
    protocol  = "tcp"
    self      = true

    security_groups = [
      aws_security_group.worker.id,
    ]
  }

  ingress {
    from_port = 4789
    to_port   = 4789
    protocol  = "udp"
    self      = true

    security_groups = [
      aws_security_group.worker.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-master"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_security_group" "worker" {
  name   = "${var.cluster_name}-worker"
  vpc_id = aws_vpc.ocp.id

  tags = merge(
    {
      "Name" = "${var.cluster_name}-worker"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_security_group_rule" "worker_10250" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "worker_10250_self" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "worker_30000-32767" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "worker_30000-32767_self" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "worker_22" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "worker_443" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "worker_80" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "worker_0" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 0
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "worker_9000-9999" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  from_port                = 9000
  to_port                  = 9999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "worker_30000-9999_self" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 9000
  to_port           = 9999
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "worker_4789" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  from_port                = 4789
  to_port                  = 4789
  protocol                 = "udp"
  source_security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "worker_4789_self" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id
  from_port         = 4789
  to_port           = 4789
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "worker_all" {
  type              = "egress"
  security_group_id = aws_security_group.worker.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "bootstrap" {
  name   = "${var.cluster_name}-bootstrap"
  vpc_id = aws_vpc.ocp.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 19531
    to_port     = 19531
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-bootstrap"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

resource "aws_security_group" "bastion" {
  name   = "${var.cluster_name}-bastion"
  vpc_id = aws_vpc.ocp.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_name}-bastion"
    },
    {
      "kubernetes.io/cluster/${var.cluster_name} " = "owned"
    },
  )
}

