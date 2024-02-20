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

  resource "aws_key_pair" "deployer" {
    key_name   = "deployer-key"
    public_key = var.ssh_public_key
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