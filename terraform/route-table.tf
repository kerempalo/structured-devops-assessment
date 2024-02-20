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