#! /bin/pwsh
function Backup-GithubRepositories {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName
    )


    # Variables
    $backupPath = Join-Path -Path (Get-Location) -ChildPath "backups"
    $backupArchivePath = Join-Path -Path (Get-Location) -ChildPath "backup-archives"
    $backupPaths = @($backupPath, $backupArchivePath)
    $date = Get-Date -Format "yyyy-MM-dd"


    # Ensure backup directories exist, create them if they don't
    $backupPaths | ForEach-Object {
        if (-Not (Test-Path -Path $_)) {
            try { 
                Write-Output "Creating temporary directory: $_"
                New-Item -ItemType Directory -Path $_ -ErrorAction Stop | Out-Null
                Write-Output "Success! Directory '$_`' created."
            } catch {
                Write-Error "Failed to create directory $_`: $_"
            }
        }
    }



    # Configure git to use GitHub token for authentication
    Write-Output "Configuring git to use GitHub token for authentication"
    $ghToken = $env:GH_TOKEN
    git config --global url."https://oauth2:${ghToken}@github.com/".insteadOf "https://github.com/"


    # Create blob container for these dates
    Write-Output "Creating Storage Context"
    $storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    Write-Output "Creating Blob Container: $date"
    $containerName = New-AzStorageContainer -Name $date -Context $storageContext -Permission Off
    Write-Output "Success! Blob Container '$date' created."


    # Fetch list of repositories and back them up
    gh repo list --json url | ConvertFrom-Json | ForEach-Object {
        $repository = $_.url
        $repositoryName = [System.IO.Path]::GetFileNameWithoutExtension($repository)
        $repositoryPath = Join-Path -Path $backupPath -ChildPath $repositoryName
        $destinationPath = "$backupArchivePath/$repositoryName.zip"

        Write-Output  "Backing up repository: $repositoryName"
        git clone $repository $repositoryPath
        Compress-Archive -Path $repositoryPath -DestinationPath $destinationPath -Force


    }


    $backupPaths | ForEach-Object {
        try { 
            Remove-Item -Path $_ -Recurse -ErrorAction Stop -Force
            Write-Output "Deleted temporary directory: $_"
        } catch {
            Write-Error "Failed to delete directory : $_"
        }
    }
}