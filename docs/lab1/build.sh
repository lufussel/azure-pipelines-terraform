#!/bin/bash

# Input variables
RESOURCE_GROUP_NAME="cicd-environment-rg"
KEYVAULT_NAME="cicd-keyvault"
STORAGE_ACCOUNT_NAME="lufusselcicdtfstate"
STORAGE_ACCOUNT_CONTAINER_NAME="tfstate"
LOCATION="uksouth"
SERVICE_PRINCIPAL_NAME="http://lufussel-cicd"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create key vault
az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION

# Get subscription and tenant ids
SUBSCRIPTION_ID=$(az account show --output tsv --query id)
TENANT_ID=$(az account show --output tsv --query tenantId)

# Add subscription and tenant ids to key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-subscription-id" --value $SUBSCRIPTION_ID
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-tenant-id" --value $TENANT_ID

# Create service principal with contributor role
SERVICE_PRINCIPAL_SECRET=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID" --output tsv --query password)
SERVICE_PRINCIPAL_APP_ID=$(az ad sp list --spn $SERVICE_PRINCIPAL_NAME --output tsv --query [0].appId)

# Add service principal to key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-client-id" --value $SERVICE_PRINCIPAL_APP_ID
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-client-secret" --value $SERVICE_PRINCIPAL_SECRET

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --kind StorageV2 --sku Standard_LRS --encryption-services blob --https-only true

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $STORAGE_ACCOUNT_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

# Add storage account key to keyvault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "arm-access-key" --value $ACCOUNT_KEY