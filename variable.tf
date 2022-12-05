variable "vpc_cidr" {
  type = string
  default = "10.1.0.0/16"
}

variable "access_ip" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
}