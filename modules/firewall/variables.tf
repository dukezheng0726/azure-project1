variable "fw_resource_group_name" {
  type    = string
  default = "FW-ResourceGroup"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "dmz_subnet_id" {
  description = "Subnet ID 来自 vnet module"
  type        = string
}