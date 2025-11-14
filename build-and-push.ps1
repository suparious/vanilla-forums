#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build and push Vanilla Forums Docker image

.DESCRIPTION
    Builds the Vanilla Forums multi-stage Docker image and optionally pushes to Docker Hub.
    Supports cross-platform paths (WSL2 + Windows).

.PARAMETER Login
    Authenticate to Docker Hub before building

.PARAMETER Push
    Push the built image to Docker Hub

.PARAMETER Tag
    Custom tag for the image (default: latest)

.EXAMPLE
    .\build-and-push.ps1
    Build image locally

.EXAMPLE
    .\build-and-push.ps1 -Login -Push
    Build and push to Docker Hub

.NOTES
    Author: Claude Code
    Requires: Docker, docker-compose
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Login,

    [Parameter()]
    [switch]$Push,

    [Parameter()]
    [string]$Tag = "latest"
)

#region Configuration
$ErrorActionPreference = "Stop"
$ImageName = "suparious/vanilla-forums"
$ImageTag = "${ImageName}:${Tag}"

# Color output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
#endregion

#region Main Script
Write-ColorOutput "`n=== Vanilla Forums Docker Build ===" "Cyan"
Write-ColorOutput "Image: $ImageTag`n" "Yellow"

# Docker Hub login
if ($Login) {
    Write-ColorOutput "Logging in to Docker Hub..." "Cyan"
    docker login
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Docker login failed!" "Red"
        exit 1
    }
    Write-ColorOutput "Login successful`n" "Green"
}

# Build image
Write-ColorOutput "Building Docker image..." "Cyan"
Write-ColorOutput "This will take several minutes (Node + PHP + Composer dependencies)`n" "Yellow"

$BuildStart = Get-Date

docker build -t $ImageTag .

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "`nBuild failed!" "Red"
    exit 1
}

$BuildDuration = (Get-Date) - $BuildStart
Write-ColorOutput "`nBuild successful! (Duration: $($BuildDuration.TotalMinutes.ToString('F1')) minutes)" "Green"

# Check image size
$ImageSize = docker images $ImageTag --format "{{.Size}}"
Write-ColorOutput "Image size: $ImageSize" "Yellow"

# Push to Docker Hub
if ($Push) {
    Write-ColorOutput "`nPushing to Docker Hub..." "Cyan"
    docker push $ImageTag

    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Push failed!" "Red"
        exit 1
    }

    Write-ColorOutput "Push successful!" "Green"
}

# Summary
Write-ColorOutput "`n=== Build Summary ===" "Cyan"
Write-ColorOutput "Image: $ImageTag" "White"
Write-ColorOutput "Size: $ImageSize" "White"
Write-ColorOutput "Pushed: $(if ($Push) { 'Yes' } else { 'No (use -Push to push)' })" "White"

Write-ColorOutput "`nNext steps:" "Cyan"
if (-not $Push) {
    Write-ColorOutput "  1. Test locally: docker run --rm -p 8080:80 $ImageTag" "Yellow"
    Write-ColorOutput "  2. Push to registry: .\build-and-push.ps1 -Push" "Yellow"
    Write-ColorOutput "  3. Deploy to K8s: .\deploy.ps1 -Build -Push" "Yellow"
} else {
    Write-ColorOutput "  1. Deploy to K8s: .\deploy.ps1" "Yellow"
    Write-ColorOutput "  2. Check status: kubectl get all -n vanilla-forums" "Yellow"
}

Write-ColorOutput "`nDone!" "Green"
#endregion
