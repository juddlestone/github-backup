locals {
  common_tags = merge({
    Environment = "Production"
  }, data.azurerm_resource_group.this.tags)
}
