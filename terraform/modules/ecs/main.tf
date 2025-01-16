variable "environment_name" {}
variable "container_image" {}
variable "container_port" {
  type = number
}
variable "db_host" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "vpc_id" {}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}

###########################
# ECS Cluster
###########################
resource "aws_ecs_cluster" "this" {
  name = "${var.environment_name}-ecs-cluster"
}

###########################
# IAM Roles for ECS Tasks
###########################
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.environment_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###########################
# ALB
###########################
resource "aws_lb" "this" {
  name               = "${var.environment_name}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.environment_name}-alb"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment_name}-alb-sg"
  description = "SG for the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP inbound"
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

resource "aws_lb_target_group" "this" {
  name        = "${var.environment_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/metadata"
    port = "${var.container_port}"
    protocol           = "HTTP"
    matcher            = "200"
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "${var.environment_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

###########################
# Security Group for ECS tasks
###########################
resource "aws_security_group" "ecs_sg" {
  name        = "${var.environment_name}-ecs-sg"
  description = "SG for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow inbound from ALB"
    from_port        = var.container_port
    to_port          = var.container_port
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###########################
# ECS Task Definition
###########################
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.environment_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile(
    "${path.module}/../../container_definitions.json", 
    {
      IMAGE_URL      = var.container_image
      CONTAINER_PORT = var.container_port
      DB_HOST        = var.db_host
      DB_NAME        = var.db_name
      DB_USER        = var.db_user
      DB_PASSWORD    = var.db_password
    }
  )
}

###########################
# ECS Service
###########################
resource "aws_ecs_service" "this" {
  name            = "${var.environment_name}-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "ipfs-app"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}

###########################
# Outputs
###########################
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
