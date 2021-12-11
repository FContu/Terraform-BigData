variable "region" {
    type = string
    default = "us-east-1"
}

variable "access_key" {
    type = string
    default = ""
}

variable "secret_key" {
    type = string
    default = ""
}

variable "token" {
    type = string
    default = null
}

variable "instance_type" {
    type = string
    default = "t2.medium"               # change instance type if needed
}

variable "ami_image" {
    type = string
    default = "ami-0885b1f6bd170450c"   # ubuntu image
}

variable "key_name" {
    type = string
    default = "localkey"                # key name, see readme
}

variable "key_path" {
    type = string
    default = "."                       # change directory to local .ssh directory e.g. ~/.ssh/
}

variable "aws_key_name" {
    type = string
    default = "amzkey"                  # key name, see readme
}

variable "amz_key_path" {
    type = string
    default = "amzkey.pem"
}

variable "namenode_count" {
    type = number
    default = 1                         # count = 1 = 1 aws EC2
}

variable "datanode_count" {
    type = number
    default = 4                         # count = 3 = 3 aws EC2
}

variable "ips" {
    default = {
        "0" = "172.31.16.241"
        "1" = "172.31.16.242"
	"2" = "172.31.16.243"
	"3" = "172.31.16.244"
	
    }
}

variable "hostnames" {
    default = {
        "0" = "datanode1"
        "1" = "datanode2"
        "2" = "datanode3"
        "3" = "datanode4"
    }
}