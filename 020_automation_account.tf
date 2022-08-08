/*

File:       020_automation_account.tf
Author:     Hank Wojteczko
Created On: 08-August-2022

Purpose:    Creates the Azure Automation Account

*/

/*

Required actions to create an automation account in Azure:

1. Create the automation account within the portal and the RunAs account
2. Create app name in the AZ app registry
3. Import the certificate into azuread_service_principal_certificate
4. Create the service principal
5. Import the certificate into the service principal
6. Get the subscription and tenancy data
7. Create the RBAC assignment
8. Import the certificate into the Azure automation account
9. Create the RunAs account
10. Print output


*/

# 1. Create the automation account

variable "azure_automation_account" {
    type = object({
        name            = string,
        sku_name        = string
    })
    default = {
        name            = "kentcloudsolutionsblueautoact",
        sku_name        = "Basic"
    }
}

resource "azurerm_automation_account" "automation_account" {

    name                  = var.azure_automation_account.name
    location              = azurerm_resource_group.autoactblue.location
    resource_group_name   = azurerm_resource_group.autoactblue.name
    sku_name              = var.azure_automation_account.sku_name

    # choose correct tag when testing or running in production
    tags = var.development_resource_tags
    # tags = var.production_resource_tags

    depends_on = [
        azurerm_resource_group.autoactblue
    ]

}

# 2. Create app name in the AZ app registry
# ----------
# used to create the application name for the Azure RunAs account
# ----------
resource "random_string" "runas_random_string" {
    length  = 16
    special = false
}


# ----------
# date offset for the certificate used to create the Azure automation account RunAs certificate
# ----------
resource "time_offset" "certificate_end_date" {
    offset_hours = 24 * 365
}

# create an application name in the ADD app registry for the subscription within Azure AD
resource "azuread_application" "run_as_account_name" {
    # example at github inaccurate, use display_name, see:
    # https://github.com/hashicorp/terraform-provider-azurerm/issues/4431 
    display_name = format("%s_%s", azurerm_automation_account.automation_account.name, random_string.runas_random_string.result)

}

/*


3. Import the certificate into azuread_service_principal_certificate
Requires that the cert be generated. This action to be performed each time we switch automation accounts
in a blue/green model.
Example for linux systems follows below:

openssl req -x509 -sha256 -nodes -days 730 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
openssl pkcs12 -export -keypbe NONE -certpbe NONE -inkey privateKey.key -in certificate.crt -out certificate.pfx

CAVEAT:     It is important that you store your certificates in a secure way. Our practice is to store sensitive
            files like this in Azure DevOps, and then to push the items to the artifacts directory for the
            build. Note the keys must be visible to the Terraform code or the build will fail. How you
            get the files there and remain secure is up to you. We DO NOT recommend that you store the cert
            in a source code repo such as GitHub.com

CAVEAT:     We have found some Microsoft LSPs tweak with Azure AD and break things related to RBAC in Azure AD.
            You should open an SR with your LSP if this part of the code fails and speak with a developer.
            A level-1 support person will not be of help. Note subsequent code depends on this task.

*/

resource "azuread_application_certificate" "run_as_account_certificate" {
    application_object_id = azuread_application.run_as_account_name.id
    type                  = "AsymmetricX509Cert"
    value                 = file("certificate.crt")
    end_date              = time_offset.certificate_end_date.rfc3339

    depends_on = [
        azuread_application.run_as_account_name
    ]
}

# 4. Create the service principal
resource "azuread_service_principal" "run_as_account" {
    application_id        = azuread_application.run_as_account_name.application_id

    depends_on = [
        azuread_application_certificate.run_as_account_certificate
    ]
}

# 5. Import the certificate into the service principal
resource "azuread_service_principal_certificate" "run_as_account_principal_certificate" {
    service_principal_id  = azuread_service_principal.run_as_account.id
    type                  = "AsymmetricX509Cert"
    value                 = file("certificate.crt")
    end_date             = time_offset.certificate_end_date.rfc3339

    depends_on = [
        azuread_service_principal.run_as_account
    ]
}

# 6. Get the subscription and tenancy data
data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

# 7. Create the RBAC assignment
resource "azurerm_role_assignment" "run_as_account_rbac" {
    scope                 = data.azurerm_subscription.primary.id
    role_definition_name  = "Contributor"
    principal_id          = azuread_service_principal.run_as_account.object_id

    depends_on = [
        azuread_service_principal_certificate.run_as_account_principal_certificate
    ]
}

# 8. Import the certificate into the Azure automation account
resource "azurerm_automation_certificate" "AzureRunAsCertificate" {
    name                    = "AzureRunAsCertificate"
    resource_group_name     = azurerm_resource_group.autoactblue.name
    automation_account_name = azurerm_automation_account.automation_account.name
    base64                  = filebase64("certificate.pfx")

    depends_on = [
        azurerm_automation_account.automation_account
    ]
}

# 9. Create the RunAs account
resource "azurerm_automation_connection_service_principal" "AzureRunAsConnection" {
    name                    = "AzureRunAsConnection"
    resource_group_name     = azurerm_resource_group.autoactblue.name
    automation_account_name = azurerm_automation_account.automation_account.name
    application_id          = azuread_service_principal.run_as_account.application_id
    tenant_id               = data.azurerm_client_config.current.tenant_id
    subscription_id         = data.azurerm_client_config.current.subscription_id
    certificate_thumbprint  = azurerm_automation_certificate.AzureRunAsCertificate.thumbprint

    depends_on = [
        azurerm_automation_account.automation_account
    ]
}


# 10. Print output
output "automation_account" {
    value = azurerm_automation_account.automation_account
}

output "azuread_application_run_as_account_name" {
    value = azuread_application.run_as_account_name
}

output "azuread_service_principal_run_as_account" {
    value = azuread_service_principal.run_as_account
}

output "run_as_account_rbac" {
    value = azurerm_role_assignment.run_as_account_rbac
}

output "AzureRunAsConnection" {
    value = azurerm_automation_connection_service_principal.AzureRunAsConnection
}


/*

references:
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account
https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/offset
https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_certificate
https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_certificate
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_certificate


*/