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