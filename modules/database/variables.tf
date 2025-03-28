variable "db_resource_group_name" {
  type    = string
  default = "DB-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "dbserver1" {
  type    = string
  default = "yan-dbserver1"
}

variable "dbserver2" {
  type    = string
  default = "yan-dbserver2"
}

variable "dblocation1" {
  type    = string
  default = "West US 2"
}

variable "dblocation2" {
  type    = string
  default = "West US 3"
}

variable "dblogin" {
  type    = string
  default = "dbadmin"
}

variable "dbpassword" {
  type      = string
  default   = "Db123456"
  sensitive = true
}

variable "dbversion" {
  type    = string
  default = "12.0"
}

