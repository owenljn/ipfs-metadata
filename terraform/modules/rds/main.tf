variable "environment_name" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "vpc_security_group_ids" {
  type = list(string)
  default = []
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.environment_name}-db-subnet-grp"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment_name}-db-subnet-grp"
  }
}

# Security Group for the RDS instance
resource "aws_security_group" "db_sg" {
  name   = "${var.environment_name}-db-sg"
  description = "SG for RDS"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name}-db-sg"
  }
}

resource "aws_db_instance" "this" {
  allocated_storage       = 10
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = "db.t3.micro"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
  multi_az                = false

  tags = {
    Name = "${var.environment_name}-rds"
  }
}

output "db_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.this.address
}
