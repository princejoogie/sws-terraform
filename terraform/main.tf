provider "aws" {
  region = "ap-southeast-1"
}

# Creating an EC2 instance
resource "aws_instance" "test-server" {
  ami           = "ami-07651f0c4c315a529"
  instance_type = "t2.micro"
  tags = {
    Name = "ubuntu-server"
  }
}
