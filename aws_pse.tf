# Elastic IPの作成
resource "aws_eip" "pse_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.aws_vpc_name}-pse-eip"
    Tag = var.aws_vpc_name
  }
}

# Elastic IPの割り当て
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.pse.id
  allocation_id = aws_eip.pse_eip.id
}

#PSEの作成
resource "aws_instance" "pse" {
  ami           = var.aws_pse_ami
  instance_type = var.aws_pse_instance_type
  subnet_id = aws_subnet.public_subnet.id
  user_data = base64encode(local.pseuserdata)
  key_name = var.aws_instance_key
  security_groups = [ aws_security_group.pse_sg.id ]
  tags = {
    Name = "${var.aws_vpc_name}-pse"
  }
}

resource "aws_security_group" "pse_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "pse-sg"

  ingress {
    description = "HTTP from PSE"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${azurerm_public_ip.public_ip_natgw.ip_address}/32"]
  }
  ingress {
    description = "HTTPS from PSE"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${azurerm_public_ip.public_ip_natgw.ip_address}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


locals {
  pseuserdata = <<PSEUSERDATA
#!/bin/bash 
#Stop the Service Edge service which was auto-started at boot time 
systemctl stop zpa-service-edge 
#Create a file from the Service Edge provisioning key created in the ZPA Admin Portal 
#Make sure that the provisioning key is between double quotes 
echo "${var.aws_pse_provision_key}" > /opt/zscaler/var/service-edge/provision_key
#Run a yum update to apply the latest patches 
yum update -y 
#Start the Service Edge service to enroll it in the ZPA cloud 
systemctl start zpa-service-edge 
#Wait for the Service Edge to download latest build 
sleep 60 
#Stop and then start the Service Edge for the latest build 
systemctl stop zpa-service-edge 
systemctl start zpa-service-edge
PSEUSERDATA
}
