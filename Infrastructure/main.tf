# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.87.0"
    }
  }
  #   This storage account is created outside this provisioning to manage the desiered state of the infrastructure.
  backend "azurerm" {
    resource_group_name  = "rg-weathman-infrastate"
    storage_account_name = "weathermantfstate"
    container_name       = "terraform-state"
    key                  = "weatherman.tfstate"
  }

  required_version = "~> 1.0.11"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


variable "webappName" {
  type        = string
  default     = "weatherMan"
  description = "The name of which your resources should start with."
  validation {
    condition     = can(regex("^[0-9A-Za-z]+$", var.webappName))
    error_message = "Only a-z, A-Z and 0-9 are allowed to match Azure storage naming restrictions."
  }
}

variable "region" {
  type        = string
  default     = "UK South"
  description = "The Azure Region where the Resource Group should exist."
}

variable "owner" {
  type        = string
  default     = "WeatherForcastTeam"
  description = "Used in created by tags to identify the owner of the resources."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Sets the environment for the resources and used to set ASPNETCORE_ENVIRONMENT env variable"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment value should be either dev or prod."
  }
}

variable "weatherApiKey" {
  type        = string
  description = "API Key to access the weather API"
  sensitive   = true
}
variable "weatherApiBaseURL" {
  type        = string
  description = "Weather api base url"
  default     = "http://dataservice.accuweather.com"
}


variable "kv-secret-permissions-optimal" {
  type        = list(any)
  description = "List of optimal secret permissions for this deployment"
  default     = ["get", "list", "set","delete"]
}

variable "kv-secret-permissions-read" {
  type        = list(any)
  description = "Required secret permissions for read operation for this deplpyment; get and list "
  default     = ["get", "list"]
}


### End of variables

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "CreatedBy"   = var.owner
    "Environment" = var.environment
  }
}

data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}-${var.webappName}"
  location = var.region
}


# Create Azure Key Vault to store sensitive app settings
resource "azurerm_key_vault" "kvweatherman" {
  name                = "kv-weatherman"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  tags                            = local.common_tags
}


# Access Policy to allow permission to the current service account to create secret
resource "azurerm_key_vault_access_policy" "kvsecretpermission" {
  key_vault_id = azurerm_key_vault.kvweatherman.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  object_id = data.azurerm_client_config.current.object_id

  #   lifecycle {
  #     create_before_destroy = true
  #   }
  secret_permissions = var.kv-secret-permissions-optimal
}

# Secret - for weather api key - Add the secrets directly to KV.
# WebApp will reference this secret directly from appsettings.
resource "azurerm_key_vault_secret" "weathApiKeySecret" {
  name         = "weatherApiKey"
  value        = ""
  key_vault_id = azurerm_key_vault.kvweatherman.id

  lifecycle {
    ignore_changes = [value, version]
  }
  depends_on = [
    azurerm_key_vault.kvweatherman,
    azurerm_key_vault_access_policy.kvsecretpermission,
  ]
}


# Create app service plan
resource "azurerm_app_service_plan" "plan" {
  name                = "asp-${var.environment}-${var.webappName}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Windows"

  sku {
    tier = "Basic"
    size = "B1"
  }

  tags = local.common_tags
}

# Create application insights
resource "azurerm_application_insights" "appinsights" {
  name                = "ai-${var.environment}-${var.webappName}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  tags = local.common_tags
}

# Create app service
resource "azurerm_app_service" "weatherManApp" {
  name                = "${var.environment}-${var.webappName}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  tags = local.common_tags

  site_config {
    always_on = true
    # app_command_line         = "dotnet BradyWeather.Blazor.Server.dll"
    dotnet_framework_version = "v4.0"
  }
  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                = var.environment == "dev" ? "DEVELOPMENT" : "PRODUCTION"
    "Web:WeatherApi:BaseAddress"            = var.weatherApiBaseURL
    "Web:WeatherApi:ApiKey"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.weathApiKeySecret.versionless_id})"
    "WEBSITE_RUN_FROM_PACKAGE"              = 0
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
  }
}



# Access Policy to allow webapp to access keyvault
resource "azurerm_key_vault_access_policy" "kvapweatherManApp" {
  key_vault_id = azurerm_key_vault.kvweatherman.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  object_id = azurerm_app_service.weatherManApp.identity.0.principal_id

  secret_permissions = var.kv-secret-permissions-read
}

output "test" {
  value = "Test output"
}
