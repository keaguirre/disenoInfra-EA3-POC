provider "aws" {
  region = "us-east-1"
}

##########################
# Identidad de cuenta (para LabRole)
##########################

data "aws_caller_identity" "current" {}

locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

##########################
# VPC y Subred por defecto
##########################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  id = data.aws_subnets.default.ids[0]
}

##########################
# Security Groups
##########################

resource "aws_security_group" "fargate_sg" {
  name        = "fargate-sg"
  description = "Allow traffic on port 5000"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP public access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################
# ECR Repository
##########################

resource "aws_ecr_repository" "pagos" {
  name         = "microservicio-pagos"
  force_delete = true
}

##########################
# Build & Push Docker Image
##########################

resource "null_resource" "build_push_image" {
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/build_and_push.sh && ${path.module}/build_and_push.sh"
  }

  depends_on = [aws_ecr_repository.pagos]
}

##########################
# ECS Cluster & Task
##########################

resource "aws_ecs_cluster" "main" {
  name = "poc-cluster"
}

resource "aws_ecs_task_definition" "pagos" {
  family                   = "pagos-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = local.lab_role_arn
  task_role_arn            = local.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "pagos"
      image     = "${aws_ecr_repository.pagos.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
      }]
    }
  ])
}

##########################
# ALB (HTTP)
##########################

resource "aws_lb" "app" {
  name               = "pagos-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "pagos" {
  name        = "pagos-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pagos.arn
  }
}

##########################
# ECS Service
##########################

resource "aws_ecs_service" "pagos" {
  name            = "pagos-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.pagos.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.selected.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.fargate_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pagos.arn
    container_name   = "pagos"
    container_port   = 5000
  }

  depends_on = [
    null_resource.build_push_image,
    aws_lb_listener.http
  ]
}
