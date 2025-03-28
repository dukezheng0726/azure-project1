variable "web_resource_group_name" {
  type    = string
  default = "WEB-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}


variable "web_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

