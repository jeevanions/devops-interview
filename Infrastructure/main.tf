# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.87.0"
    }
  }
  
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


variable "webappName" {
  type = string
  default = "weatherMan"
  description = "The name of which your resources should start with."
  validation {
    condition = can(regex("^[0-9A-Za-z]+$", var.webappName))
    error_message = "Only a-z, A-Z and 0-9 are allowed to match Azure storage naming restrictions."
  }
}

variable "region" {
  type = string
  default = "UK South"
  description = "The Azure Region where the Resource Group should exist."
}

variable "owner" {
  type = string
  default = "WeatherForcastTeam"
  description = "Used in created by tags to identify the owner of the resources."
}

variable "weatherApiKey" {
  type = string
  description = "API Key to access the weather API"
  sensitive = true
}
variable "weatherApiBaseURL" {
    type = string
    description = "Weather api base url"
    default = "http://dataservice.accuweather.com"
}


### End of variables

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    "CreatedBy"   = var.owner
    "Environment" = var.environment
  }
}


# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}-${var.webappName}"
  location = var.region
}


output "test" {
  value = "Test output"
}
