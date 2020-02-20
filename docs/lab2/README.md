# Lab 2: Terraform

> This lab is build using Terraform 0.12, for Terraform 0.11 and earlier see [0.11 Configuration Language](https://www.terraform.io/docs/configuration-0-11/index.html) for syntax differences.

## Introduction

This lab will create a basic Terraform configuration to demonstrate the use of Terraform remote state with Azure storage accounts, and explore the use of environment variables for passing secure strings.

This lab will provide the foundation that will enable Terraform to be deployed securely in a build pipeline.

During this lab we will explore:

- Terraform remote state using Azure storage. This removes reliance on a local state to allows collaboration between with a team or use by a build agent. 
- How to use environment variables with Terraform.
- How to use secrets with Terraform.

## Terraform remote state

### What is Terraform state?

Terraform maintains a record of resources that have been deployed, configured, modified or removed by Terraform so that it can understand and process changes efficiently. By default the state is stored locally to the Terraform directory that holds the configuration, usually in a `terraform.tfstate` file. 
> *"This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures."*

See [Terraform Docs: State](https://www.terraform.io/docs/state/index.html) for more information.

### Why use remote state?

In order to scale Terraform to work across multiple workstations in a team environment, and to be able to deploy through a build agent, a remote state must be used.

A remote state moves the Terraform state file to a central location, such as Azure blob storage, that can be accessed by other agents.

This ensures that the Terraform state is accessible by and updated by deployments made from any location.

> Caution: If a remote state is NOT used and Terraform configuration is copied to another agent, the local state file may not be present or accessible. This can cause major issues if Terraform is not aware of existing configuration, such as failure to deploy or even deletion of resources.

See [Terraform Docs: Remote State](https://www.terraform.io/docs/state/remote.html) for more information.

### Configuring Terraform backend

To configure a basic blob storage backend, add the following to the `main.tf`.

```hcl
terraform {
  backend "azurerm" {
    storage_account_name  = "lufusselcicdtfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}
```

Where:

| Variable                | Description                                                                     |
| ----------------------- | ------------------------------------------------------------------------------- |
| `storage_account_name`  | Name of the storage account that contains the remote state                      |
| `container_name`        | Name of the container within the storage account that contains the remote state |
| `key`                   | Name of the Terrform state file such as `terraform.tfstate`                     |

An access key, sas token or Managed Service Identity must be used to authenticate with the storage account. 

> Rather than defining the keys within the configuration, these variables should be sourced from environment variables. This process is described in the lab below.

| Key variables (use environment variables) | Description                                                  |
| ----------------------------------------- | ------------------------------------------------------------ |
| `access_key`                              | A storage account access key to access the storage account   |
| `sas_token`                               | A sas token to access the storage account                    |
| `use_msi`, `subscription_id`, `tenant_id` | Use a Managed Service Identity to access the storage account |

See [Terraform Docs: Standard Backends / azurerm](https://www.terraform.io/docs/backends/types/azurerm.html) for more information.

## Using Terraform remote state

1. Azure Cloud Shell has Terraform installed by default. Log in to Azure Cloud Shell at https://shell.azure.com/.

2. Check that Terraform is available and the version with `terraform -v`

3. Create a working directory to create some Terraform files.
```bash
mkdir ./terraform-lab2/ && cd ./terraform-lab2/
```

### Create a simple main.tf

4. Create an empty file within the working directory `touch main.tf`

5. Open the file with your favourite text editor (`code main.tf` for VS Code) and copy/paste the following configuration which uses a **local state**:

```hcl
terraform {
  required_version = ">= 0.12"
}

resource "azurerm_resource_group" "terraform-lab" {
  name      = "cicd-terraform-rg"
  location  = "uksouth"
}

resource "azurerm_storage_account" "terraform-lab" {
  name                      = "lufusselcicdterraform"
  resource_group_name       = azurerm_resource_group.terraform-lab.name
  location                  = "westeurope"
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}
```

6. Deploy the Azure resources with Terraform. Note the storage account name must be globally unique so you'll need to change it in the `main.tf`.

```bash
# Initialise the working directory
terraform init && terraform validate

# Confirm the resources which will be deployed
terraform plan

# Confirm and input 'yes' to deploy the resources
terraform apply
```

> An introduction to Terraform is outside of the scope of this workshop. For a getting started guide, see [Azure Citadel](https://azurecitadel.com/automation/terraform/) or [Microsoft Docs](https://docs.microsoft.com/en-us/azure/terraform/terraform-create-configuration).

7. Confirm that the resources have deployed successfully

### Configuring and moving to a remote state

8. We will now modify the configuration to use remote state. Open the `main.tf` with your favourite text editor (`code main.tf` for VS Code) and add the `backend` block which uses a **rewmote state**. This must be an available storage account such as the account created in [Lab 1: Environment](../lab1).

```hcl
terraform {
  required_version = ">= 0.12"
}

terraform {
  backend "azurerm" {
    storage_account_name  = "lufusselcicdtfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "terraform-lab" {
  name      = "cicd-terraform-rg"
  location  = "uksouth"
}

resource "azurerm_storage_account" "terraform-lab" {
  name                      = "lufusselcicdterraform"
  resource_group_name       = azurerm_resource_group.terraform-lab.name
  location                  = "westeurope"
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}
```

9. This configuration is not yet valid as we must authenticate with the storage account in order to create and then read the remote state. To do this environment variables should be used in order to avoid writing secrets into configuration files.

10. Terraform uses the environment variable `ARM_ACCESS_KEY` to define the storage account key to access the azurerm remote state. We will use Azure CLI to get the key and set the environment variable to match the storage account create in [Lab 1: Environment](../lab1).

```bash
# Input variables
RESOURCE_GROUP_NAME="cicd-environment-rg"
STORAGE_ACCOUNT_NAME="lufusselcicdtfstate"

# Get the storage account key from Azure CLI
STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Set the environment variable to the storage account key
export ARM_ACCESS_KEY=$STORAGE_ACCOUNT_KEY
```
11. Deploy the Azure resources with Terraform. Note that the state is migrated from the local state to remote state as part of this process.

```bash
terraform init && terraform validate

terraform plan

terraform apply
```

12. Check the storage account for the `terraform.tfstate` file to confirm that remote state is used.

## Using environment variables from key vault

13. When storing code and configurations, secrets should not be stored in plain text. Ideally we will be able to access the storage account key and any other secrets from Azure key vault. This will enable the secrets to be referenced from and not stored in the code and configuration, and for build agent to have restricted permissions.

14. To set the `ARM_ACCESS_KEY` environment variable from key vault.

```bash
# Input variables
KEYVAULT_NAME="cicd-keyvault"

# Set the environment variable to the storage account key from key vault
export ARM_ACCESS_KEY=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name "arm-access-key" --output tsv --query value)
```

> To access secrets from key vault, permissions must be granted to the user or service principal initiating the connection.
