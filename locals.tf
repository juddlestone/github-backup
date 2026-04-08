locals {
  common_tags = merge({
  }, data.azurerm_resource_group.this.tags)
}
