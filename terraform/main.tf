provider "aws" {
  region = "ap-southeast-1"
}

# Creating an EC2 instance
# resource "aws_instance" "test-server" {
#   ami           = "ami-07651f0c4c315a529"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "ubuntu-server"
#   }
# }

resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "prod-subnet"
  }
}
