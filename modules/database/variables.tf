variable "db_resource_group_name" {
  type    = string
  default = "DB-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "data_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

