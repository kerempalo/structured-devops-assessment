  resource "aws_security_group" "lb_allow_http_https" {
    name        = "lb_allow_http_https"
    description = "Allow HTTP and HTTPS inbound traffic"
    vpc_id      = aws_vpc.main.id
  
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port   = 443
      to_port     = 443
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
  
resource "aws_lb" "test" {
    name               = "tf-test-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb_allow_http_https.id]
    subnets            = [aws_subnet.subnet.id, aws_subnet.subnet1.id]
  }
  
resource "aws_lb_target_group" "test" {
    name     = "tf-example-lb-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id
  }
  
  resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.test.arn
    port              = "80"
    protocol          = "HTTP"
  
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.test.arn
    }
  }

    resource "aws_lb_target_group_attachment" "test" {
    count            = 2
    target_group_arn = aws_lb_target_group.test.arn
    target_id        = aws_instance.web[count.index].id
    port             = 80
  }