# Security Group do VPC Público
resource "aws_security_group" "vpc_sg_pub" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# User Data Script for EC2
data "template_file" "user_data" {
  template = file("./modules/compute/scripts/user_data.sh")
  vars = {
    rds_endpoint   = var.rds_endpoint
    rds_dbuser     = var.rds_dbuser
    rds_dbpassword = var.rds_dbpassword
    rds_dbname     = var.rds_dbname
  }
}

# Launch Template for EC2 Instances
resource "aws_launch_template" "ec2_lt" {
  name                   = "${var.ec2_lt_name}-nickolas"
  image_id               = var.ec2_lt_ami
  instance_type          = var.ec2_lt_instance_type
  key_name               = var.ec2_lt_ssh_key_name
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.vpc_sg_pub.id]
}

# Load Balancer
resource "aws_lb" "ec2_lb" {
  name               = "${var.ec2_lb_name}-nickolas"
  load_balancer_type = "application"
  subnets            = [var.vpc_sn_pub_az1_id, var.vpc_sn_pub_az2_id]
  security_groups    = [aws_security_group.vpc_sg_pub.id]
}

# Target Group
resource "aws_lb_target_group" "ec2_lb_tg" {
  name     = "${var.ec2_lb_tg_name}-nickolas"
  protocol = "HTTP"
  port     = 80
  vpc_id   = var.vpc_id

  health_check {
    interval            = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }
}

# Listener
resource "aws_lb_listener" "ec2_lb_listener" {
  protocol          = "HTTP"
  port              = 80
  load_balancer_arn = aws_lb.ec2_lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_lb_tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  name                = "${var.ec2_asg_name}-nickolas"
  desired_capacity    = 2   # antes vinha de variável (ex: 6) -> reduzido
  min_size            = 2   # pelo menos 2 instâncias
  max_size            = 4   # permite escalar até 4
  vpc_zone_identifier = [var.vpc_sn_pub_az1_id, var.vpc_sn_pub_az2_id]
  target_group_arns   = [aws_lb_target_group.ec2_lb_tg.arn]

  wait_for_capacity_timeout = "20m"  # mantém timeout aumentado

  launch_template {
    id      = aws_launch_template.ec2_lt.id
    version = "$Latest"
  }
}
