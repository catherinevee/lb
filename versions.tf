terraform {
  required_version = "=1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=6.2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.38.1"
    }
  }
}