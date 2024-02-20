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