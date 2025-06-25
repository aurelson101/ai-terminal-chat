# AI Terminal Chat - Uninstall Script for Windows 11
# PowerShell script for removing AI Terminal Chat from Windows

<#
.SYNOPSIS
    Désinstallation complète d'AI Terminal Chat pour Windows

.DESCRIPTION
    Ce script supprime AI Terminal Chat et peut optionnellement désinstaller
    Git et Python s'ils ont été installés par le script d'installation.

.PARAMETER Force
    Force la désinstallation sans demander de confirmation

.PARAMETER RemoveDependencies
    Supprime également Git et Python installés par winget

.PARAMETER Verbose
    Active les logs détaillés

.EXAMPLE
    .\uninstall_windows.ps1
    Désinstallation normale

.EXAMPLE
    .\uninstall_windows.ps1 -RemoveDependencies
    Désinstallation avec suppression des dépendances

.EXAMPLE
    .\uninstall_windows.ps1 -Force
    Désinstallation forcée sans confirmation
#>

param(
    [switch]$Force = $false,
    [switch]$RemoveDependencies = $false,
    [switch]$Verbose = $false
)

Write-Host "🗑️  Désinstallation de AI Terminal Chat pour Windows..." -ForegroundColor Yellow
if ($RemoveDependencies) {
    Write-Host "⚠️  Mode de suppression des dépendances activé" -ForegroundColor Red
}

# Define paths
$InstallDir = "$env:LOCALAPPDATA\ai_terminal_chat"
$ScriptsDir = "$env:USERPROFILE\ai_terminal_chat_scripts"

# Remove scripts directory
if (Test-Path $ScriptsDir) {
    Write-Host "📂 Suppression des scripts..." -ForegroundColor Blue
    Remove-Item -Path $ScriptsDir -Recurse -Force
    Write-Host "✅ Scripts supprimés" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Aucun répertoire de scripts trouvé" -ForegroundColor Gray
}

# Remove configuration directory
if (Test-Path $InstallDir) {
    Write-Host "📂 Suppression de la configuration..." -ForegroundColor Blue
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "✅ Configuration supprimée" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Aucune configuration trouvée" -ForegroundColor Gray
}

# Remove from PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -like "*$ScriptsDir*") {
    Write-Host "🔄 Suppression du PATH..." -ForegroundColor Blue
    try {
        # Create backup of current PATH
        $backupPath = $currentPath
        Write-Host "💾 Sauvegarde du PATH actuel..." -ForegroundColor Gray
        
        # Split PATH into entries and remove the scripts directory
        $pathEntries = $currentPath -split ';' | Where-Object { 
            $_.Trim() -ne '' -and $_.Trim() -ne $ScriptsDir 
        }
        
        $newPath = ($pathEntries | Sort-Object -Unique) -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "✅ PATH mis à jour avec succès" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur lors de la modification du PATH:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "💡 PATH original: $backupPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  Répertoire non trouvé dans le PATH" -ForegroundColor Gray
}

# Ask about Python packages
Write-Host ""
$response = Read-Host "Voulez-vous aussi désinstaller les packages Python (rich, pyperclip, requests) ? (y/N)"
if ($response -eq "y" -or $response -eq "Y" -or $response -eq "yes") {
    Write-Host "📦 Désinstallation des packages Python..." -ForegroundColor Blue
    
    $packages = @("rich", "pyperclip", "requests")
    foreach ($package in $packages) {
        try {
            $result = python -m pip uninstall $package -y 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $package désinstallé avec succès" -ForegroundColor Green
            } else {
                Write-Host "⚠️  $package n'était pas installé ou erreur" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️  Erreur lors de la désinstallation de $package" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "ℹ️  Packages Python conservés" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎉 Désinstallation terminée!" -ForegroundColor Green
Write-Host "💡 Note: Redémarrez votre terminal pour que les changements de PATH prennent effet" -ForegroundColor Cyan
Write-Host ""
