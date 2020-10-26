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
  tags = local.common_tags

}



resource "azurerm_cosmosdb_account" "db" {
  name                = var.cosmosdb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
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
