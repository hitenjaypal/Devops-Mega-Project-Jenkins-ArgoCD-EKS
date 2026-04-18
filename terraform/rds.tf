# ─── RDS Variables (self-contained here, no changes needed in variables.tf) ───

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed"
  type        = string
  default     = ""
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group (minimum 2 AZs)"
  type        = list(string)
  default     = []
}

variable "db_instance_class" {
  description = "RDS instance type"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the MySQL database"
  default     = "wanderlust"
}

variable "db_username" {
  description = "Master username for RDS MySQL"
  default     = "wanderlust_user"
}

variable "db_password" {
  description = "Master password for RDS MySQL (set via -var or terraform.tfvars)"
  type        = string
  sensitive   = true
  default     = ""
}

# ─── RDS Resources ────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "wanderlust_db_subnet" {
  name       = "wanderlust-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name    = "wanderlust-db-subnet-group"
    Project = "wanderlust"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "wanderlust-rds-sg"
  description = "Allow MySQL from application layer"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EC2/EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_user_to_connect.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wanderlust-rds-sg"
    Project = "wanderlust"
  }
}

resource "aws_db_instance" "wanderlust_mysql" {
  identifier        = "wanderlust-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.wanderlust_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name    = "wanderlust-mysql"
    Project = "wanderlust"
  }
}

output "rds_endpoint" {
  value       = aws_db_instance.wanderlust_mysql.endpoint
  description = "RDS MySQL endpoint (host:port) — copy this into rds-secret.yaml as MYSQL_HOST"
}

output "rds_port" {
  value       = aws_db_instance.wanderlust_mysql.port
  description = "RDS MySQL port"
}
