variable "name"  {
  default = "tf-clb-sticky-session"
}

variable "key_name" {}


variable "admin_cidr" {
  default = "0.0.0.0/0"
}


variable "enable_ec2_httpbin" {
  default = "true"
}
