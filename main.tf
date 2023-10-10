terraform {

  required_version = ">= 1.3.3"
  
  backend "azurerm" {
    resource_group_name  = "tfpipeline-rg"
    storage_account_name = "tfpipelinesa"
    container_name       = "terraform"
    key                  = "WIF/workloadidentityfederation.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.9.0"
    }

    azuread = {
      source = "hashicorp/azuread"
      version = "2.43.0"
    }
  }

}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/arindammitra0251"
  personal_access_token = "XXXXXXXXXXXXXXXXXXXXXXXXXX" 
}