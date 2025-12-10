#! /bin/pwsh

# gh auth --with-token

$backupPath = Join-Path -Path (Get-Location) -ChildPath "backups"
$backupArchivePath = Join-Path -Path (Get-Location) -ChildPath "backup-archives"
$backupPaths = @($backupPath, $backupArchivePath)


$backupPaths | ForEach-Object {
    if (-Not (Test-Path -Path $_)) {
        try { 
            New-Item -ItemType Directory -Path $_ -ErrorAction Stop | Out-Null
            Write-Output "Created directory: $_"
        } catch {
            Write-Error "Failed to create directory $_`: $_"
        }
    }
}


gh repo list --json url | ConvertFrom-Json | ForEach-Object {
    $repository = $_.url
    $repositoryName = [System.IO.Path]::GetFileNameWithoutExtension($repository)
    $repositoryPath = Join-Path -Path $backupPath -ChildPath $repositoryName

    Write-Output "Cloning Repo: '$repositoryName'"
    git clone $repository $repositoryPath | Out-Null
    Compress-Archive -Path $repositoryPath -DestinationPath "$backupArchivePath/$repositoryName.zip" -Force
}


$backupPaths | ForEach-Object {
    try { 
        Remove-Item -Path $_ -Recurse -ErrorAction Stop -Force
        Write-Output "Deleted directory: $_"
    } catch {
        Write-Error "Failed to delete directory : $_"
    }
}