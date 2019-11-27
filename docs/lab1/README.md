# Lab 1: Environment

## Introduction

This lab will create environment resources to be used with automation tools Terraform and Azure DevOps. These resources are used to provide access to resources through secured keys (secrets) and to store state information for Terraform to use with collaborative teams and build agents.

The below process and script will create:

- **Key vault** to store secrets for the automation tools.
- A **service principal** with [contributor permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) to the subscription. This will be used by Terraform to create Azure resources.
- A **storage account** to store Terraform remote state.

## Authenticate to target subscription

As this lab assumes that no existing environment exists, initial pre-requisite resources must be created through tooling outside of the pipeline through tools such as Azure CLI, PowerShell or the Azure Portal.

1. Log in to Azure Cloud Shell at https://shell.azure.com/ or use `az login` to authenticate Azure CLI

2. List available Azure subscriptions
`az account list --output table`

3. Select the subscription to target, use the **SubscriptionId** from the output of step 2
`az account set --subscription replace-with-your-subscription-id`

## Build script

The [build.sh](build.sh) script can be used to skip the following steps and automatically deploy this environment through Azure Cloud Shell or Azure CLI. 
> Note: Modify the **input variables** before executing the script.

## Deploying environment resources

All steps from the build process are detailed below and can be execured from Azure Cloud Shell or Azure CLI.

1. Set input variables for the resources to created

| Variable                       | Description                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| RESOURCE_GROUP_NAME            | Name of the resource group to deploy the resources                                    |
| KEYVAULT_NAME                  | Name of the key vault to store secrets                                                |
| STORAGE_ACCOUNT_NAME           | Name of the storage account to store Terraform state                                  |
| STORAGE_ACCOUNT_CONTAINER_NAME | Name of the container to store Terraform state                                        |
| LOCATION                       | Azure region to deploy resources into                                                 |
| SERVICE_PRINCIPAL_NAME         | Name of the service principal to grant contributor permissions. Must begin "http://". |

```bash
# Input variables
RESOURCE_GROUP_NAME="citadel-cicd-environment-rg"
KEYVAULT_NAME="citadel-cicd-keyvault"
STORAGE_ACCOUNT_NAME="citadelcicdtfstate"
STORAGE_ACCOUNT_CONTAINER_NAME="tfstate"
LOCATION="uksouth"
SERVICE_PRINCIPAL_NAME="http://lufussel-citadel-cicd"
```

2. Create the resource group to deploy the key vault and storage account

```bash
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
```

3. Create the key vault. Key vault will be used to securely store secrets rather than hard code them into files or repositories. 
> Storing secrets as plain text provides a security risk. Secrets should always be stored in a secure service such as key vault, with only references stored within code and repositories.

```bash
# Create key vault
az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION
```

4. Add the subscription ID and tenant ID to key vault. This is used in Hashicorp environment variables **ARM_SUBSCRIPTION_ID** and **ARM_TENANT_ID** as well as other automation tools. We will also use the subscription ID later in this lab. These ID specify the tenant and subscription to target for deployment.
> Multiple subscriptions may be used such as to deploy different applications and to different environments. This lab uses only a single subscription to demonstrate the concept.

```bash
# Get subscription and tenant ids
SUBSCRIPTION_ID=$(az account show --output tsv --query id)
TENANT_ID=$(az account show --output tsv --query tenantId)

# Add subscription and tenant ids to key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-subscription-id" --value $SUBSCRIPTION_ID
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-tenant-id" --value $TENANT_ID
```

5. Create a service principal and add to key vault. This is used in Hashicorp environment variables **ARM_CLIENT_ID** and **ARM_CLIENT_SECRET** as well as other automation tools. The service principal is used to provide create, modify and delete permissions to Azure resources.
> A with step 4, multiple service pricipals can also be used when working with multiple subscriptions and tenants. The service principal must have permissions to the target subscription.

```bash
# Create service principal with contributor role
SERVICE_PRINCIPAL_SECRET=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID" --output tsv --query password)
SERVICE_PRINCIPAL_APP_ID=$(az ad sp list --spn $SERVICE_PRINCIPAL_NAME --output tsv --query [0].appId)

# Add service principal to key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-client-id" --value $SERVICE_PRINCIPAL_APP_ID
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-client-secret" --value $SERVICE_PRINCIPAL_SECRET
```

6. Create a storage account, blob container, and add the storage access key to key vault. The storage access key is used in Hashicorp environment variable **ARM_ACCESS_KEY** to store Terraform remote state.

```bash
# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --kind StorageV2 --sku Standard_LRS --encryption-services blob --https-only true

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $STORAGE_ACCOUNT_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

# Add storage account key to keyvault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-access-key" --value $ACCOUNT_KEY
```






