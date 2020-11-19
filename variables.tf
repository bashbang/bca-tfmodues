# General module variables
variable "rg_name" {
  type        = string
  description = "Provide a name to give to the resource group"
}

variable "location" {
  type        = string
  description = "The region/location within Azure that these resources should be stood up."
}


# AKS Variables
variable "aks_cluster_name" {
  type        = string
  description = "The name used for the AKS cluster"
}

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix used within the AKS definition"
}

variable "client_id" {
  type        = string
  description = "The id of the principle client"
}

variable "client_secret" {
  type        = string
  description = "The secret/password for this client_id account"
}

variable "tenant_id" {
  type = string
  description = "The secret for the Azure Tenant ID"
}

# ACR variables
variable acr_name {
  type        = string
  description = "The name used for the Azure Container Registry (ACR)"
}


# Cosomos DB variables
variable cosmosdb_name {
  type        = string
  description = "The name of the CosmosDB"
}

# TODO: will need to add more cosmos variables to support a failover environment and allow for multi database.
# TODO: currently only useing a single database in a single region.

# AKV
variable avk_name {
  type = string
  description = "The globally unique name for the AKV - consider using random string within the name"
}