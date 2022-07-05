# --------------------------------------------------------
# Setup
# --------------------------------------------------------

# Provider block -> please make sure you have added partner id
provider "azurerm" {
  # Whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version         = "~> 2.14.0"
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  #client_id       = var.client_id
  #client_secret   = var.client_secret
  partner_id      = "a79fe048-6869-45ac-8683-7fd2446fc73c"

  features {}
}

provider "azurerm" {
        alias                   = "SIG"
        version                 = "~> 2.14.0"
        features {}
        subscription_id         = var.SIG_SubscriptionID
        tenant_id               = var.tenant_id
        #client_id               = var.client_id
        #client_secret           = var.client_secret
}

# Azure AD Provider
provider "azuread" {
  version         = "0.8.0"
  subscription_id = var.subscription_id
  #client_id       = var.client_id
  #client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "tls" {
  version = "~> 2.2"
}

# Set the terraform backend
terraform {
  required_version = "~> 0.12.20"
  backend "azurerm" {} #Backend variables are initialized through the secret and variable folders
}