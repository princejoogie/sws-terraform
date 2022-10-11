provider "aws" {
  region = "ap-southeast-1"
}

# --- Creating an EC2 instance
# resource "aws_instance" "test-server" {
#   ami           = "ami-07651f0c4c315a529"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "ubuntu-server"
#   }
# }

# --- Creating a VPC and Subnet
# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "production"
#   }
# }
#
# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"
#   tags = {
#     Name = "prod-subnet"
#   }
# }

# --- Simple Web Server
# 1. Create a VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "prod-gateway" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.prod-gateway.id
  }

  tags = {
    Name = "production"
  }
}

# 4. Create a Subnet
variable "subnet_prefix" {
  description = "CIDR Block for the Subnet"
  type = string
}

resource "aws_subnet" "prod-subnet" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "prod-rt-assoc" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create Network Interface
resource "aws_network_interface" "prod-network-interface" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Create Elastic IP
resource "aws_eip" "prod-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.prod-network-interface.id
  associate_with_private_ip = "10.0.1.50" # from step 7
  depends_on                = [aws_internet_gateway.prod-gateway]

  tags = {
    Name: "prod-eip"
  }
}

output "server_public_ip" {
  value = aws_eip.prod-eip.public_ip
}

# 9. Create EC2 Instance
resource "aws_instance" "prod-server" {
  ami               = "ami-07651f0c4c315a529"
  instance_type     = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name          = "prod-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.prod-network-interface.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo prod server running > /var/www/html/index.html"
              EOF

  tags = {
    Name = "ubuntu-server"
  }
}

# 10. Associate EIP to EC2
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.prod-server.id
  allocation_id = aws_eip.prod-eip.id
}
