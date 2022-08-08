/*

File:       05_variables.tf
Author:     Hank Wojteczko
Created On: 04-January-2022
Purpose:    Declares and sets all variable values that your TF build
            will use.

CAVEAT:     It is our practice to define global vars here, and to define
            local vars in the files where they are locally used in
            an effort to keep the code more maintainable. You should
            choose the style that matches your organization's
            codification standards.

*/



# Your subscription name goes here
variable "subscription_name" {
  type = string
  default = "Azure subscription 1"
}

variable "location" {
  type = string
  description = "Azure region where resources will deploy"
  default = "eastus2"
}

variable "development_resource_tags" {
  type = map
  default = {
    "platform"      = "Managed by Terraform"
    "environment"   = "dev"
    "account_code"  = "ITSD"
  }
}

variable "production_resource_tags" {
  type = map
  default = {
    "platform"      = "Managed by Terraform"
    "environment"   = "prod"
    "account_code"  = "ITSD"
  }
}

/* references

https://www.terraform.io/language/values/variables 

*/