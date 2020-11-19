output "rgname" {
    value = azurerm_resource_group.rg.name
    description = "The Resource Group Name"
}

output "aksname" {
    value = azurerm_kubernetes_cluster.aks.name
    description = "The name of the Azure Kubernetes Cluster"
}

output "acrname" {
    value = azurerm_container_registry.acr.name
    description = "The name of the Azure Container Registry"
}

output "cosmosdbname" {
    value = azurerm_cosmosdb_account.db.name
    description = "The name of the Azure Cosmos Database"
}

output "akvname" {
    value = azurerm_key_vault.akv.name
    description = "The Azure Key Vault Name"
}

output "cosmosdbprimary_key" {
    value = azurerm_cosmosdb_account.db.primary_key
    description = "The cosmosdb host used in a connection string"
}

output "cosmosdbprimary_master_key" {
    value = azurerm_cosmosdb_account.db.primary_master_key
    description = "The cosmosdb host used in a connection string"
}

output "cosmosdbread_endpoints" {
    value = azurerm_cosmosdb_account.db.read_endpoints
    description = "The cosmosdb host used in a connection string"
}


