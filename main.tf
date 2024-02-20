terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
    backend "s3" {
      bucket         = "terraform-remote-state-bucket-188721"
      key            = "terraform-remote-state"
      region         = "ap-southeast-1"
      dynamodb_table = "terraform-remote-state-lock"
      encrypt        = true
    }
  }
  
  provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
  }
  
  resource "aws_key_pair" "deployer" {
    key_name   = "deployer-key"
    public_key = var.ssh_public_key
  }
  
  resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
  }
  
  resource "aws_subnet" "subnet" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-southeast-1a"
  }
  
  resource "aws_subnet" "subnet1" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-southeast-1b"
  }
  
  resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
  }
  
  resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.main.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  }
  
  resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.subnet.id
    route_table_id = aws_route_table.rt.id
  }
  
  resource "aws_route_table_association" "a1" {
    subnet_id      = aws_subnet.subnet1.id
    route_table_id = aws_route_table.rt.id
  }
  
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
  
  resource "aws_security_group" "ec2_allow_http_https" {
    name        = "ec2_allow_http_https"
    description = "Allow HTTP and HTTPS inbound traffic"
    vpc_id      = aws_vpc.main.id
  
    ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      security_groups = [aws_security_group.lb_allow_http_https.id]
    }
  
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  resource "aws_instance" "web" {
    count         = 2
    ami           = "ami-0123c9b6bfb7eb962"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.deployer.key_name
    subnet_id     = aws_subnet.subnet.id
    vpc_security_group_ids = [aws_security_group.ec2_allow_http_https.id]
    associate_public_ip_address = true
    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y python3-pip
                sudo pip3 install flask
                cat > ~/app.py <<EOL
                from flask import Flask
                import requests
                app = Flask(__name__)
                @app.route('/')
                def hello_world():
                    ip = requests.get('http://169.254.169.254/latest/meta-data/local-ipv4').text
                    mac = requests.get('http://169.254.169.254/latest/meta-data/network/interfaces/macs').text
                    cidr = requests.get('http://169.254.169.254/latest/meta-data/network/interfaces/macs/' + mac + '/vpc-ipv4-cidr-block').text
                    cidr_block = cidr.split('/')[1]
                    return '{"ip_address":"' + ip + '",  "subnet_size":"/' + cidr_block + '"}\n' 
                if __name__ == '__main__':
                    app.run(host='0.0.0.0', port=80)
                EOL
                # Install CloudWatch Agent
                curl https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O
                sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
                sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
                # Runn app.py
                sudo python3 /root/app.py &
                EOF
  
    tags = {
      Name = "web-${count.index}"
      Owner = "Kerem"
      Project = "DevOpsTest"
    }
    volume_tags = {
      Name = "web-${count.index}"
      Owner = "Kerem"
      Project = "DevOpsTest"
    }
  }
  
  resource "aws_lb_target_group_attachment" "test" {
    count            = 2
    target_group_arn = aws_lb_target_group.test.arn
    target_id        = aws_instance.web[count.index].id
    port             = 80
  }