# main.tf can remain empty or contain common resources, variables, etc.
data "aws_vpc" "selected" {
  vpc_id = "vpc-004016faf33f0991f"
}
# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Allow HTTP and HTTPS traffic"
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

# ALB
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
  load_balancer_type = "application"
}

# Target Group for pt-notification-service
resource "aws_lb_target_group" "pt_notification_tg" {
  name     = "pt-notification-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Target Group for email-sender-service
resource "aws_lb_target_group" "email_sender_tg" {
  name     = "email-sender-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pt_notification_tg.arn
  }
}

# Listener Rule for pt-notification-service
resource "aws_lb_listener_rule" "pt_notification_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pt_notification_tg.arn
  }

  condition {
    host_header {
      values = ["pt-notification.example.com"]
    }
  }
}

# Listener Rule for email-sender-service
resource "aws_lb_listener_rule" "email_sender_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.email_sender_tg.arn
  }

  condition {
    host_header {
      values = ["email-sender.example.com"]
    }
  }
}