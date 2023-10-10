#################
## Data Blocks:-
#################

data "azuredevops_project" "az-devops-project" {
  name  = var.devops-proj-name
}

# output "project_id" {
#   value = data.azuredevops_projects.az-devops-project.projects.*.project_id
# }

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

resource "azuredevops_serviceendpoint_azurerm" "az-devops-serviceendpoint" {
  project_id                             = data.azuredevops_project.az-devops-project.project_id #"d868d9ec-e5d3-4df0-a1ff-f7e2c686e6c7"
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