terraform {
  required_version  = ">= 0.12"
}

terraform {
  backend "azurerm" {
    storage_account_name  = "lufusselcicdtfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "terraform-lab" {
  name      = var.resource_group_name
  location  = var.location

  tags      = var.tags
}

resource "azurerm_storage_account" "terraform-lab" {
  name                      = var.storage_account_name
  resource_group_name       = azurerm_resource_group.terraform-lab.name
  location                  = "westeurope"
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"

  tags                      = var.tags
}
