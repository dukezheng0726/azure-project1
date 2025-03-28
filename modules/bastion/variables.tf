variable "bastion_resource_group_name" {
  type    = string
  default = "BASTION-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "vnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

variable "dmz_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

variable "web_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

variable "business_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}
