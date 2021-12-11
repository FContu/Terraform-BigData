locals {
    #  Directories start with "C:..." on Windows; All other OSs use "/" for root.
    is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}

provider "aws" {
    region      = var.region
    access_key  = var.access_key
    secret_key  = var.secret_key
    token       = var.token
}

resource "aws_security_group" "Hadoop_cluster_sc" {
    name = "Hadoop_cluster_sc"

    # inbound internet access
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

# namenode (master)
resource "aws_instance" "Namenode" {
    subnet_id="subnet-016e93047639a61f1"
    count = var.namenode_count
    ami = var.ami_image
    instance_type = var.instance_type
    key_name = var.aws_key_name
    tags = {
        Name = "namenode"
    }
    private_ip = "172.31.16.240"
    vpc_security_group_ids = [aws_security_group.Hadoop_cluster_sc.id]

    provisioner "file" {
        source      = "installer-master.sh"
        destination = "/home/ubuntu/installer-master.sh"

        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }
    }

    provisioner "file" {
        source      = "amzkey.pem"
        destination = "/home/ubuntu/.ssh/amzkey.pem"

        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }
    }

    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name}.pub | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/authorized_keys'"
    # }
    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name}.pub | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa.pub'"
    # }
    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name} | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa'"
    # }

    # execute the configuration scripte
    provisioner "remote-exec" {
        inline = [
            "sudo chmod 755 /home/ubuntu/installer-master.sh",
    	    "sudo sed -i.bak 's|\r$||' /home/ubuntu/installer-master.sh",
            "/bin/bash /home/ubuntu/installer-master.sh",
    	    "sudo chmod 400 /home/ubuntu/.ssh/amzkey.pem",
    	    "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
    	    "sudo chmod 400 /home/ubuntu/.ssh/id_rsa.pub",
	    "wget http://deepyeti.ucsd.edu/jianmo/amazon/categoryFilesSmall/Kindle_Store_5.json.gz",
	    "git clone https://github.com/aleessiap/BigData"
     ]
        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }

    }
}

# datanode (slaves)
resource "aws_instance" "Datanode" {
    subnet_id="subnet-016e93047639a61f1"
    count = var.datanode_count
    ami = var.ami_image
    instance_type = var.instance_type
    key_name = var.aws_key_name
    tags = {
        Name = lookup(var.hostnames, count.index)
    }
    private_ip = lookup(var.ips, count.index)
    vpc_security_group_ids = [aws_security_group.Hadoop_cluster_sc.id]

    # copy the initialization script to the remote machines
    provisioner "file" {
        source      = "installer-slave.sh"
        destination = "/home/ubuntu/installer-slave.sh"

        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }
    }

    provisioner "file" {
        source      = "amzkey.pem"
        destination = "/home/ubuntu/.ssh/amzkey.pem"

        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }
    }

    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name}.pub | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/authorized_keys'"
    # }
    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name}.pub | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa.pub'"
    # }
    # provisioner "local-exec" {
    #     interpreter = local.is_windows ? ["PowerShell"] : []
    #     command = "cat ${var.key_path}/${var.key_name} | ssh -o StrictHostKeyChecking=no -i ${var.amz_key_path}  ubuntu@${self.public_dns} 'cat >> .ssh/id_rsa'"
    # }

    # execute the configuration script
     provisioner "remote-exec" {
         inline = [
    	    "sudo chmod 400 /home/ubuntu/.ssh/amzkey.pem",
            "sudo chmod 755 /home/ubuntu/installer-slave.sh",
    	    "sudo sed -i.bak 's|\r$||' /home/ubuntu/installer-slave.sh",
            "/bin/bash /home/ubuntu/installer-slave.sh"
        ]
        connection {
            host     = self.public_dns
            type     = "ssh"
            user     = "ubuntu"
            private_key = file(var.amz_key_path)
        }

    }
}