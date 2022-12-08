data "aws_ami" "server_ami" {
    most_recent = true

    owners = ["099720109477"]

    filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}

resource "random_id" "node_id" {
  count = var.main_instance_count
  byte_length = 2
}



resource "aws_instance" "mtg_main_instance" {
  count = var.main_instance_count
  ami           = data.aws_ami.server_ami.id
  instance_type = var.main_instance_type
  key_name = aws_key_pair.mtg_instance_key.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  subnet_id = aws_subnet.mtg_public_subnet[count.index].id
  root_block_device {
    volume_size =   var.main_volume_size
  }

  tags = {
    Name = "mtg_main_instance-${random_id.node_id[count.index].dec}"
  }

  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> ./aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region eu-west-3"
  }

  provisioner "local-exec" {
    when = destroy
    command = "sed -i '/^[0-9]/d' ./aws_hosts"
  }
}

resource "aws_key_pair" "mtg_instance_key" {
 key_name = var.key_name 
 public_key = file(var.public_key_path)
}

# resource "null_resource" "grafana_update" {
#   count = var.main_instance_count
#   connection {
#     type = "ssh"
#     private_key = file("/home/ubuntu/.ssh/mtckey")
#     user = ubuntu
#     host = aws_instance.mtg_main_instance[count.index].public_ip
#   }

#   provisioner "remote-exec" {
#     inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I updated Grafana aplication'>> update.log"]
#   }
# }


resource "null_resource" "grafana_install" {
  depends_on = [aws_instance.mtg_main_instance]
  
  provisioner "local-exec" {
     command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/mtckey playbooks/grafana.yml"
  } 
  
}