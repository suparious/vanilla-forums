#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Vanilla Forums to Kubernetes

.DESCRIPTION
    Deploys or uninstalls Vanilla Forums on srt-hq-k8s cluster.
    Includes MySQL database initialization and validation.

.PARAMETER Build
    Build Docker image before deploying

.PARAMETER Push
    Push Docker image to registry (implies -Build)

.PARAMETER Uninstall
    Remove Vanilla Forums from cluster

.PARAMETER SkipDatabase
    Skip MySQL database and user creation

.EXAMPLE
    .\deploy.ps1
    Deploy using existing image

.EXAMPLE
    .\deploy.ps1 -Build -Push
    Build, push, and deploy

.EXAMPLE
    .\deploy.ps1 -Uninstall
    Remove from cluster

.NOTES
    Author: Claude Code
    Requires: kubectl, Docker (if -Build/-Push)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Build,

    [Parameter()]
    [switch]$Push,

    [Parameter()]
    [switch]$Uninstall,

    [Parameter()]
    [switch]$SkipDatabase
)

#region Configuration
$ErrorActionPreference = "Stop"
$Namespace = "vanilla-forums"
$AppName = "vanilla-forums"

# Color output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
#endregion

#region Functions
function Initialize-Database {
    Write-ColorOutput "`nInitializing MySQL database..." "Cyan"

    # Database credentials from secret
    $DbName = "vanilla"
    $DbUser = "vanilla"
    $DbPassword = "vanilla_user_password_2025"
    $RootPassword = "mysql_platform_root_password_2025"

    Write-ColorOutput "Creating database and user..." "Yellow"

    $SqlCommands = @"
CREATE DATABASE IF NOT EXISTS $DbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DbUser'@'%' IDENTIFIED BY '$DbPassword';
GRANT ALL PRIVILEGES ON $DbName.* TO '$DbUser'@'%';
FLUSH PRIVILEGES;
SELECT 'Database initialization complete!' AS status;
"@

    # Execute SQL commands
    kubectl run -i --rm mysql-init --image=mysql:8.0 --restart=Never -- `
        mysql -h mysql.data-platform.svc.cluster.local -u root -p$RootPassword -e "$SqlCommands"

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Database initialized successfully!" "Green"
    } else {
        Write-ColorOutput "Warning: Database initialization may have failed (check if already exists)" "Yellow"
    }
}
#endregion

#region Main Script
if ($Uninstall) {
    Write-ColorOutput "`n=== Uninstalling Vanilla Forums ===" "Cyan"

    Write-ColorOutput "Removing Kubernetes resources..." "Yellow"
    kubectl delete -f k8s/ --ignore-not-found=true

    Write-ColorOutput "`nVanilla Forums uninstalled!" "Green"
    Write-ColorOutput "`nNote: MySQL database 'vanilla' was NOT deleted. To remove:" "Yellow"
    Write-ColorOutput "  kubectl run -it --rm mysql-cleanup --image=mysql:8.0 --restart=Never -- \\" "White"
    Write-ColorOutput "    mysql -h mysql.data-platform.svc.cluster.local -u root -p<password> -e 'DROP DATABASE vanilla; DROP USER vanilla;'" "White"
    exit 0
}

Write-ColorOutput "`n=== Deploying Vanilla Forums ===" "Cyan"

# Build and push if requested
if ($Push) { $Build = $true }

if ($Build) {
    Write-ColorOutput "`nBuilding Docker image..." "Cyan"
    $BuildArgs = @()
    if ($Push) { $BuildArgs += "-Push" }

    & ./build-and-push.ps1 @BuildArgs

    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Build failed!" "Red"
        exit 1
    }
}

# Initialize database
if (-not $SkipDatabase) {
    Initialize-Database
}

# Apply Kubernetes manifests
Write-ColorOutput "`nApplying Kubernetes manifests..." "Cyan"
kubectl apply -f k8s/

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Failed to apply manifests!" "Red"
    exit 1
}

# Wait for rollout
Write-ColorOutput "`nWaiting for deployment to complete..." "Cyan"
kubectl rollout status deployment/$AppName -n $Namespace --timeout=5m

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Deployment rollout failed or timed out!" "Red"
    Write-ColorOutput "Check logs: kubectl logs -n $Namespace -l app=$AppName -c php-fpm --tail=50" "Yellow"
    exit 1
}

# Display status
Write-ColorOutput "`n=== Deployment Status ===" "Cyan"

Write-ColorOutput "`nPods:" "Yellow"
kubectl get pods -n $Namespace -l app=$AppName

Write-ColorOutput "`nServices:" "Yellow"
kubectl get svc -n $Namespace

Write-ColorOutput "`nIngress:" "Yellow"
kubectl get ingress -n $Namespace

Write-ColorOutput "`nCertificate:" "Yellow"
kubectl get certificate -n $Namespace

Write-ColorOutput "`nPersistent Volumes:" "Yellow"
kubectl get pvc -n $Namespace

# Summary
Write-ColorOutput "`n=== Deployment Complete! ===" "Green"
Write-ColorOutput "`nAccess Vanilla Forums:" "Cyan"
Write-ColorOutput "  URL: https://vanilla.lab.hq.solidrust.net" "White"
Write-ColorOutput "`nUseful Commands:" "Cyan"
Write-ColorOutput "  Logs (PHP):   kubectl logs -n $Namespace -l app=$AppName -c php-fpm -f" "White"
Write-ColorOutput "  Logs (Nginx): kubectl logs -n $Namespace -l app=$AppName -c nginx -f" "White"
Write-ColorOutput "  Shell (PHP):  kubectl exec -it -n $Namespace deployment/$AppName -c php-fpm -- sh" "White"
Write-ColorOutput "  Status:       kubectl get all,certificate,ingress,pvc -n $Namespace" "White"
Write-ColorOutput "  Uninstall:    .\deploy.ps1 -Uninstall" "White"

Write-ColorOutput "`nFirst-time setup:" "Yellow"
Write-ColorOutput "  1. Wait for certificate to be ready (may take 1-2 minutes)" "White"
Write-ColorOutput "  2. Navigate to https://vanilla.lab.hq.solidrust.net" "White"
Write-ColorOutput "  3. Complete Vanilla Forums installation wizard" "White"
Write-ColorOutput "  4. Database connection should be auto-configured from environment variables" "White"

Write-ColorOutput "`nDone!" "Green"
#endregion
