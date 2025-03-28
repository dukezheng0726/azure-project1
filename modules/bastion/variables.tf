variable "bastion_resource_group_name" {
  type    = string
  default = "BASTION-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "bastion_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}
