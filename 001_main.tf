/*

File:       01_main.tf
Author:     Hank Wojteczko
Created On: 04-January-2022
Purpose:    Pin Terraform module versions, define backend storage  

*/


# 1. Terraform Settings Block
# 2. Provider feature information for Azure


# 1. Terraform Settings Block


terraform {
  # 1. Required Version Terraform
  required_version = ">=1.2.4"

  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "2.38.0"
    }

    azuread = {
        source  = "hashicorp/azuread"
        version = "= 2.26.1"
    }

    local = {
        source  = "hashicorp/local"
        version = "2.2.3"
    }

    random = {
        source  = "hashicorp/random"
        version = "3.3.2"
    }

    time = {
        source   = "hashicorp/time"
        version     = "0.7.2"
    }
    
  }



/*

Replace these values with the storage account of your choice. Make
sure you have created a container name within the storage account.
We also recommend you backup your storage account with ASR to
enable you to recovery the TF state container and files in the
event of corruption of this vital file.

*/
  backend "azurerm" {
      resource_group_name     = "your_resourcegroup_rg"
      storage_account_name    = "yoursatgactnamehere"
      container_name          = "tfstatefiles"
      key                     = "yourblobfile.tfstate"
  }

}

# 2. Provider feature information for Azure, required.
provider "azurerm" {
  features {}
}

