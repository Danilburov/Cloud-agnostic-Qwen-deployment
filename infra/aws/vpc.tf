resource "aws_vpc" "sue-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    name = "sue-vpc"
  }
}
resource "aws_internet_gateway" "sue-igw" {
  vpc_id = aws_vpc.sue-vpc.id
  tags = {
    name = "sue-igw"
  }
}
//subnets- I have created 2 private and 2 public subnets
resource "aws_subnet" "sue-subnet-private-1" {
  vpc_id = aws_vpc.sue-vpc.id
  cidr_block = var.cidr_private_subnet_1
  availability_zone = var.az_a
  tags = {
    name = "sue-subnet-private-1"
  }
}
resource "aws_subnet" "sue-subnet-private-2" {
  vpc_id = aws_vpc.sue-vpc.id
  cidr_block = var.cidr_private_subnet_2
  availability_zone = var.az_b
  tags = {
    name = "sue-subnet-private-2"
  }
}
resource "aws_subnet" "sue-subnet-public-1" {
  vpc_id = aws_vpc.sue-vpc.id
  cidr_block = var.cidr_public_subnet_1
  availability_zone = var.az_a
  tags = {
    name = "sue-subnet-public-1"
  }
}
resource "aws_subnet" "sue-subnet-public-2" {
  vpc_id = aws_vpc.sue-vpc.id
  cidr_block = var.cidr_public_subnet_2
  availability_zone = var.az_b
  tags = {
    name = "sue-subnet-public-2"
  }
}
//route table that either directs to the vpc cidr or to the internet gateway
resource "aws_route_table" "sue-public-rt" {
  vpc_id = aws_vpc.sue-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sue-igw.id
  }
  tags = {
    name = "sue-public-rt"
  }
}
//assigning route table with the public subnets
resource "aws_route_table_association" "sue-rta-public-1" {
  subnet_id = aws_subnet.sue-subnet-public-1.id
  route_table_id = aws_route_table.sue-public-rt.id
}
resource "aws_route_table_association" "sue-rta-public-2" {
  subnet_id = aws_subnet.sue-subnet-public-2.id
  route_table_id = aws_route_table.sue-public-rt.id
}
resource "aws_nat_gateway" "sue-nat-gw" {
  allocation_id = aws_eip.sue-nat-eip.id
  subnet_id = aws_subnet.sue-subnet-public-1.id
  tags = {
    name = "sue-nat-gw"
  }
}
//this route table uses the nat gateway to route traffic to the internet and is associated with the private subnets
resource "aws_route_table" "sue-private-rt" {
  vpc_id = aws_vpc.sue-vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sue-nat-gw.id
  }
  tags = {
    name = "sue-private-rt"
  }
}
//same thing, assigning the private route table to the private subnets
resource "aws_route_table_association" "sue-rta-private-1" {
  subnet_id = aws_subnet.sue-subnet-private-1.id
  route_table_id = aws_route_table.sue-private-rt.id
}
resource "aws_route_table_association" "sue-rta-private-2" {
  subnet_id = aws_subnet.sue-subnet-private-2.id
  route_table_id = aws_route_table.sue-private-rt.id  
}