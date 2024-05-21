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
  user_data = base64encode(local.pse_userdata)
  key_name = var.aws_instance_key
  tags = {
    Name = "${var.aws_vpc_name}-pse"
  }
}

locals {
  pseuserdata = <<PSEUSERDATA
#!/bin/bash 
#Stop the Service Edge service which was auto-started at boot time 
systemctl stop zpa-service-edge 
#Create a file from the Service Edge provisioning key created in the ZPA Admin Portal 
#Make sure that the provisioning key is between double quotes 
echo "${var.azure_pse_provision_key}" > /opt/zscaler/var/service-edge/provision_key
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
