terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-xd3"
    key = var.backend_key
    region = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

locals {
  http_port = 80
  ssh_port = 22
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  ssh_protocol = "ssh"
  all_ips = "0.0.0.0/0"
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = local.all_ips
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_subnet" "default1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "default2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table_association" "def1_assoc" {
  subnet_id      = aws_subnet.default1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "def2_assoc" {
  subnet_id      = aws_subnet.default2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "${var.cluster_name}_allow_ssh_http"
  description = "allows ssh and http inbound, allows all outbound"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = local.ssh_port
  ip_protocol       = local.tcp_protocol
  to_port           = local.ssh_port
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port           = local.http_port
  ip_protocol       = local.tcp_protocol
  to_port           = local.http_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = local.all_ips
  ip_protocol       = local.any_protocol
}

resource "aws_launch_template" "server" {
  image_id               = "ami-0ecb62995f68bb549"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = local.http_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }))

  lifecycle {
    create_before_destroy = true
  }
} 

resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.server.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.default1.id, aws_subnet.default2.id]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  max_size = var.max_size
  min_size = var.min_size

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.default1.id, aws_subnet.default2.id]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.all_ips
  ip_protocol       = local.any_protocol
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.all_ips
  from_port         = local.http_port
  ip_protocol       = local.tcp_protocol
  to_port           = local.http_port
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = local.http_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
