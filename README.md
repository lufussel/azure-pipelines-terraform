# Introduction

This workshop provides an example environment to start using Hashicorp products such as [Terraform](https://www.terraform.io/) and [Packer](https://www.packer.io/) with Azure, including integration with [Azure Pipelines](https://docs.microsoft.com/en-gb/azure/devops/pipelines/) and [Key vault](https://docs.microsoft.com/en-gb/azure/key-vault/).

The aim of this guidance is to provide quick start example for using a CICD automation process to deploy Terraform resources to Azure, while managing secrets with Azure key vault.

## Labs

| Lab | Name                         | Description                                                  |
| --- | ---------------------------- | ------------------------------------------------------------ |
| 1   | [Environment](docs/lab1)     | Creation of service principal, key vault and storage account |
| 2   | [Terraform](docs/lab2)       | Basic Terraform configuration for use with Azure Pipelines   |
| 3   | [Azure Pipelines](docs/lab3) | Example pipeline to deploy Terraform resources               |

## Further resources

The following resources provide great instruction for further reading:

- [Microsoft Docs](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/terraform-create-complete-vm) contains quick starts for deploying Azure resources with Terraform.
- The Terraform Azure provider reference is available at [https://aka.ms/tfref](https://www.terraform.io/docs/providers/azurerm/).
- [Azure Citadel](https://azurecitadel.com/automation/) provides end to end guides for a wide variety of automation technologies.

