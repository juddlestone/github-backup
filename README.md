# Github Backup
This repository contains the infrastructure and application code to automatically backup my GitHub repositories every month in a simple manner, and store them in an Azure Storage Account. 

## Latest Backup Status

**Last Run**: 2025-12-16

| Repository | Size | Status |
|------------|------|--------|
| studying-fastapi | 0 MB | ✅ Success |
| project-onboarder | 0.17 MB | ✅ Success |
| shared-services | 0 MB | ✅ Success |
| entra-spn-vending | 0 MB | ✅ Success |
| github-backup | 0.01 MB | ✅ Success |
| hello.itsjack | 0 MB | ✅ Success |
| resume.itsjack | 0.19 MB | ✅ Success |
| rag-postgres-openai-python | 4.31 MB | ✅ Success |
| azfw-report | 0.01 MB | ✅ Success |
| self-hosted-runners | 0 MB | ✅ Success |
| juddlestone.github | 1.11 MB | ✅ Success |
| resource-graph-queries | 0.02 MB | ✅ Success |
| azure-container-registry | 0 MB | ✅ Success |
| juddlestone | 0 MB | ✅ Success |
| study-notes-azure | 0 MB | ✅ Success |
| itsjack | 0.12 MB | ✅ Success |
| otfencing | 12.04 MB | ✅ Success |
| poster | 0.03 MB | ✅ Success |
| xrp_bot | 0 MB | ✅ Success |

## Infrastructure

I've deployed a three resources via terraform to facilitate this.

### Storage Account
- **Name**: Generated using the Azure naming module. 
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
The backup process runs automatically at midnight on the first of every month through the `github-backup.yml` workflow. Backups can also be triggered ad-hoc via workflow dispatch.

### Backup Process

1. **Authentication**: GitHub Actions authenticates to Azure using OIDC (OpenID Connect) with a federated identity credential
2. **Container Creation**: Creates a new blob container named with the current date (format: `yyyy-MM-dd`)
3. **Repository Discovery**: Uses GitHub CLI to fetch a list of all accessible repositories
4. **Clone & Archive**: Each repository is:
   - Cloned to a temporary directory
   - Compressed into a ZIP archive
   - Uploaded to Azure Blob Storage
5. **Cleanup**: Temporary directories are removed after successful upload