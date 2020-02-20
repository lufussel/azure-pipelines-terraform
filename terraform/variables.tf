variable "location" {
  default = "westeurope"
  description = "Region to deploy the resources"
}

variable "resource_group_name" {
  default = "cicd-terraform-rg"
  description = "Name of the resource group"
}

variable "storage_account_name" {
  default = "lufusselcicdterraform"
  description = "Name of the storage account"
}

variable "tags" {
  type = "map"
  default = {
    environment = "development"
    application = "terraform-lab"
  }
}