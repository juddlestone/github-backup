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
    $backupResults = @()


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
        $status = "❌ Failed"
        $size = "N/A"

        try {
            Write-Output  "Backing up repository: $repositoryName"
            
            git clone $repository $repositoryPath 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Git clone failed"
            }

            $repoContents = Get-ChildItem -Path $repositoryPath -Exclude ".git" -ErrorAction SilentlyContinue
            if ($null -eq $repoContents -or $repoContents.Count -eq 0) {
                Write-Output "Repository $repositoryName is empty, skipping backup"
                $status = "⚠️ Empty"
                $size = "0 MB"
            }
            else {
                # Compress archive
                Compress-Archive -Path $repositoryPath -DestinationPath $destinationPath -Force
                
                # Get size of archive
                $fileInfo = Get-Item $destinationPath
                $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
                $size = "$sizeInMB MB"

                # Upload to Azure
                $backup = @{
                    File             = $destinationPath
                    Container        = $date
                    Blob             = "$repositoryName.zip"
                    Context          = $storageContext
                    StandardBlobTier = 'Hot'
                    Force            = $true
                }
                Set-AzStorageBlobContent @backup | Out-Null
                
                $status = "✅ Success"
                Write-Output "Successfully backed up $repositoryName ($size)"
            }
        }
        catch {
            Write-Error "Failed to backup $repositoryName : $_"
            $status = "❌ Failed"
        }

        # Add result to tracking array
        $backupResults += [PSCustomObject]@{
            Repository = $repositoryName
            Size       = $size
            Status     = $status
        }
    }


    # Clean up temporary directories
    $backupPaths | ForEach-Object {
        try { 
            Remove-Item -Path $_ -Recurse -ErrorAction Stop -Force
            Write-Output "Deleted temporary directory: $_"
        } catch {
            Write-Error "Failed to delete directory : $_"
        }
    }

    # Update README with backup results
    Write-Output "Updating README.md with backup results"
    try {
        $templatePath = Join-Path -Path (Get-Location) -ChildPath "templates/README.md"
        $readmePath = Join-Path -Path (Get-Location) -ChildPath "README.md"
        $readmeContent = Get-Content -Path $templatePath -Raw
        
        # Replace date placeholder
        $readmeContent = $readmeContent -replace '%%DATE%%', $date
        
        # Build backup results table
        $tableRows = $backupResults | ForEach-Object {
            "| $($_.Repository) | $($_.Size) | $($_.Status) |"
        }
        $tableContent = $tableRows -join "`n"
        
        # Replace backup results placeholder
        $readmeContent = $readmeContent -replace '%%BACKUP_RESULTS%%', $tableContent
        
        # Write updated README
        Set-Content -Path $readmePath -Value $readmeContent -NoNewline
        
        Write-Output "Successfully updated README.md"
    }
    catch {
        Write-Error "Failed to update README.md: $_"
    }
}