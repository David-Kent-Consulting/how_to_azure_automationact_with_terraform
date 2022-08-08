/*

File:       010_resourcegroup.tf
Author:     Hank Wojteczko
Created On: 08-August-2022
Purpose:    Creates the resource group

Purpose:    Creates a resource group

1. Create the resource group
2. Print the output

*/

# 1. Create the resource group

variable "resource_group_name" {
  type = string
  description = "The name of the resource group"
  default = "kent_autoactblue_rg"
}

resource "azurerm_resource_group" "autoactblue" {
    name = var.resource_group_name
    location = var.location

    # choose correct tag when testing or running in production
    tags = var.development_resource_tags
    # tags = var.production_resource_tags
}

# 2. Print the output
output "automation_rg" {
    value = azurerm_resource_group.autoactblue
}
/*

TF azurerm_resource_group reference:
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group 

*/