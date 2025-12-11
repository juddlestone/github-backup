# Github Backup
This repository contains infrastructure and application code to automatically backup my GitHub repositories to Azure Storage. It provides automated monthly backups, each backup is stored as a compressed archive with retention policies and lifecycle management.

## Infrastructure

The Terraform configuration deploys the following Azure resources:

### Storage Account
- **Name**: Generated using Azure naming conventions 
- **Tier**: Standard with Zone-Redundant Storage (ZRS)
- **Security**: Public access disabled, shared access keys disabled
- **Retention**: 7-day soft delete for blobs and containers
- **Lifecycle**: Destroy protection enabled

### Custom RBAC Role
- **Role**: "Github Backup" with granular permissions
- **Permissions**: Container read/write and blob read/write operations
- **Scope**: Limited to the storage account only

### Role Assignment
- Grants the custom role to the service principal used by GitHub Actions
- Enables secure, keyless authentication via Azure Workload Identity

## How It Works

### Workflow Schedule
The backup process runs automatically on the first of every month at midnight via GitHub Actions. It can also be triggered manually via workflow dispatch.

### Backup Process

1. **Authentication**: GitHub Actions authenticates to Azure using OIDC (OpenID Connect) with a federated identity credential
2. **Container Creation**: Creates a new blob container named with the current date (format: `yyyy-MM-dd`)
3. **Repository Discovery**: Uses GitHub CLI to fetch a list of all accessible repositories
4. **Clone & Archive**: Each repository is:
   - Cloned to a temporary directory
   - Compressed into a ZIP archive
   - Uploaded to Azure Blob Storage
5. **Cleanup**: Temporary directories are removed after successful upload

### Storage Structure
```
Storage Account
└── Container (2025-11-01)
    ├── repo1.zip
    ├── repo2.zip
    └── repo3.zip
└── Container (2025-12-01)
    ├── repo1.zip
    ├── repo2.zip
    └── repo3.zip
```

## Latest Backup Status

**Last Run**: %%DATE%%

| Repository | Size | Status |
|------------|------|--------|
%%BACKUP_RESULTS%%