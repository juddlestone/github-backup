data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = "rg-github-backup-prd"
}
