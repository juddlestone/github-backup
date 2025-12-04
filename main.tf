resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  tags = {
    environment = "production"
  }
}

resource "azurerm_role_definition" "main" {
  name        = "Github Backup"
  scope       = azurerm_storage_account.main.id
  description = "This role allows GitHub to backup data to the storage account."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
    ]
  }

  assignable_scopes = [
    azurerm_storage_account.main.id
  ]
}

resource "azurerm_role_assignment" "github_backup" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = azurerm_role_definition.main.name
  principal_id         = data.azurerm_client_config.current.object_id
}

# resource "azurerm_storage_management_policy" "main" {
#   storage_account_id = azurerm_storage_account.main.id

#   rule {
#     name    = "rule1"
#     enabled = true
#     filters {
#       prefix_match = ["container1/prefix1"]
#       blob_types   = ["blockBlob"]
#       match_blob_index_tag {
#         name      = "tag1"
#         operation = "=="
#         value     = "val1"
#       }
#     }
#     actions {
#       base_blob {
#         tier_to_cool_after_days_since_modification_greater_than    = 10
#         tier_to_archive_after_days_since_modification_greater_than = 50
#         delete_after_days_since_modification_greater_than          = 100
#       }
#       snapshot {
#         delete_after_days_since_creation_greater_than = 30
#       }
#     }
#   }
# }

