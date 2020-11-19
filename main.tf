resource "random_string" "prefix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = true

}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  # TODO: Add Tag support
  #tags     = local.common_tags
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }
  }

  # TODO: add tag support
  #tags = local.common_tags
}


resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  # TODO: add tag support
  #tags = local.common_tags

}

data "azuread_service_principal" "aks_principal" {
  application_id = var.client_id
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = data.azuread_service_principal.aks_principal.id
  skip_service_principal_aad_check = true
}

resource "azurerm_cosmosdb_account" "db" {
  name                = var.cosmosdb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false

  # May not need this setting in combination with capability "EnableMongo"
  capabilities {
    name = "EnableAggregationPipeline"
  }

  # May not need this setting in combination with capability "EnableMongo"
  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  # May not need this setting in combination with capability "EnableMongo"
  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

# Get the azure config -- TODO: should we use vars from this rather than storing as secrets?
data "azurerm_client_config" "current" {}


resource "azurerm_key_vault" "akv" {
  name                        = "BCAKeyVault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant
  # TODO: I like this method of obtaining the secrets....is it better than using the TF cloud secrets?
  #  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
      "ManageContacts",
    ]

    secret_permissions = [
      "get",
    ]

    storage_permissions = [
      "get",
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  contact {
    email = "example@example.com"
    name  = "example"
    phone = "0123456789"
  }

  #tags     = local.common_tags

}