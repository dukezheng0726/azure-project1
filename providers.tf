terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "9eddc527-496a-4bbf-83a1-b1c0b9c0c12c"
}
