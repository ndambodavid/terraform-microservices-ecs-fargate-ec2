# Note: For production, use an Amazon Linux 2 AMI or an official Ubuntu LTS AMI.
# This user data script is for Ubuntu 22.04 LTS.
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's Owner ID
}

resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  # Startup script to install and configure MongoDB
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y gnupg
              curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
                 sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
                 --dearmor
              echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
                 sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
              sudo apt-get update
              sudo apt-get install -y mongodb-org
              sudo systemctl start mongod
              sudo systemctl enable mongod
              # Change bindIp to 0.0.0.0 to allow connections from within the VPC
              sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
              sudo systemctl restart mongod
              EOF

  tags = {
    Name = "${var.project_name}-mongodb-instance"
  }
}
