variable "business_resource_group_name" {
  type    = string
  default = "BUSINESS-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "business_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}


