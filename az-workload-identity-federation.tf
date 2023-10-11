#################
## Data Blocks:-
#################

data "azuredevops_project" "az-devops-project" {
  name  = var.devops-proj-name
}

# data "azurerm_subscription" "current" {
# }

data "azurerm_storage_account" "az-sa" {
  name                = var.sa-name
  resource_group_name = var.rg-name
}

#############################################
## App Registration and Service Principal:-
#############################################

resource  "azuread_application"  "aad-app" {
display_name  =  var.app-name
}

resource  "azuread_service_principal"  "aad-app-sp" {
application_id  =  azuread_application.aad-app.application_id
}

################################################
## App Registration and Federated Credentials:-
################################################

resource "azuread_application_federated_identity_credential" "aad-app-federated" {
  application_object_id = azuread_application.aad-app.object_id
  display_name          = "${var.app-name}-federated-credential"
  description           = "Managed by Terraform"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = azuredevops_serviceendpoint_azurerm.az-devops-serviceendpoint.workload_identity_federation_issuer
  subject               = azuredevops_serviceendpoint_azurerm.az-devops-serviceendpoint.workload_identity_federation_subject
}

########################################
## Service Connection in Azure Devops:-
########################################
resource "azuredevops_serviceendpoint_azurerm" "az-devops-serviceendpoint" {
  project_id                             = data.azuredevops_project.az-devops-project.project_id
  service_endpoint_name                  = var.app-name
  description                            = "Service Connection Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azuread_service_principal.aad-app-sp.application_id
  }
  azurerm_spn_tenantid      = var.tenantID
  azurerm_subscription_id   = var.subsID 
  azurerm_subscription_name = var.subsName
}

#####################################
## Grant Access to all Pipelines:-
####################################
resource "azuredevops_resource_authorization" "az-devops-serviceendpoint-auth" {
  project_id  = data.azuredevops_project.az-devops-project.project_id
  resource_id = azuredevops_serviceendpoint_azurerm.az-devops-serviceendpoint.id
  authorized  = true
}

############################################################
## Role Based Access Control (RBAC):-
## Subscription = Contributor, User Access Administrator
## Storage Account = Storage Blob Data Contributor
############################################################

resource "azurerm_role_assignment" "az-rbac-subs-contrib" {
  scope                = "/subscriptions/${var.subsID}/"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aad-app-sp.object_id
}

resource "azurerm_role_assignment" "az-rbac-subs-usraccessadmin" {
  scope                = "/subscriptions/${var.subsID}/"
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.aad-app-sp.object_id
}
resource "azurerm_role_assignment" "az-rbac-sa-blobcontrib" {
  scope                = data.azurerm_storage_account.az-sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.aad-app-sp.object_id
}