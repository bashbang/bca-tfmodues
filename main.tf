data "azurerm_client_config" "current" {}

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

resource "azurerm_kubernetes_cluster" "aks" {
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

resource "azurerm_key_vault" "akv" {
  name                        = var.avk_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  #tags     = local.common_tags
}


# Create a Default Azure Key Vault access policy with Admin permissions
# This policy must be kept for a proper run of the "destroy" process
resource "azurerm_key_vault_access_policy" "default_policy" {
  key_vault_id = azurerm_key_vault.akv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  lifecycle {
    create_before_destroy = true
  }

  key_permissions         = ["backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify", "wrapKey"]
  secret_permissions      = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
  certificate_permissions = ["create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "setissuers", "update", "backup", "restore"]
  storage_permissions     = ["backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update"]
}


resource "azurerm_key_vault_secret" "akv-dbuid-secret" {
  name         = "DBUID"
  value        = azurerm_cosmosdb_account.db.name
  key_vault_id = azurerm_key_vault.akv.id
}

resource "azurerm_key_vault_secret" "akv-dbpwd-secret" {
  name         = "DBPWD"
  value        = azurerm_cosmosdb_account.db.primary_key
  key_vault_id = azurerm_key_vault.akv.id
}

resource "azurerm_key_vault_secret" "akv-dbhost-secret" {
  name         = "DBHOST"
  value        = "${azurerm_cosmosdb_account.db.name}.mongo.cosmos.azure.com"
  key_vault_id = azurerm_key_vault.akv.id

  depends_on = [
    azurerm_key_vault.akv,
    azurerm_cosmosdb_account.db,
  ]
}
