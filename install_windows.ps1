# AI Terminal Chat - Installation Script for Windows 11
# PowerShell script for installing AI Terminal Chat on Windows

param(
    [switch]$Force = $false
)

Write-Host "🤖 Installation de AI Terminal Chat pour Windows 11..." -ForegroundColor Green
Write-Host "🖥️  PowerShell Edition" -ForegroundColor Cyan

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python détecté: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python n'est pas installé ou non accessible." -ForegroundColor Red
    Write-Host "💡 Veuillez installer Python depuis https://python.org" -ForegroundColor Yellow
    exit 1
}

# Check if pip is available
try {
    $pipVersion = python -m pip --version 2>&1
    Write-Host "✅ pip détecté: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ pip n'est pas disponible." -ForegroundColor Red
    Write-Host "💡 Veuillez réinstaller Python avec pip." -ForegroundColor Yellow
    exit 1
}

# Create installation directories
$InstallDir = "$env:LOCALAPPDATA\ai_terminal_chat"
$ScriptsDir = "$env:USERPROFILE\ai_terminal_chat_scripts"

Write-Host "📂 Création des répertoires d'installation..." -ForegroundColor Blue
Write-Host "   📁 Configuration: $InstallDir" -ForegroundColor Gray
Write-Host "   📁 Scripts: $ScriptsDir" -ForegroundColor Gray

if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

if (!(Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
}

# Copy files to installation directory
Write-Host "📦 Copie des fichiers..." -ForegroundColor Blue

$filesToCopy = @(
    "ai_chat_windows.py",
    "ai_chat_fr.py", 
    "ai_chat_en.py",
    "windows_helper.py",
    "requirements.txt"
)

$missingFiles = @()
foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        try {
            Copy-Item $file -Destination $ScriptsDir -Force
            Write-Host "   ✅ $file copié" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Erreur lors de la copie de $file : $($_.Exception.Message)" -ForegroundColor Red
            $missingFiles += $file
        }
    } else {
        Write-Host "   ⚠️  $file non trouvé dans le répertoire courant" -ForegroundColor Yellow
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Fichiers manquants détectés:" -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "💡 Assurez-vous d'exécuter ce script depuis le répertoire contenant les fichiers AI Terminal Chat" -ForegroundColor Cyan
}

# Install Python dependencies
Write-Host "📦 Installation des dépendances Python..." -ForegroundColor Blue
try {
    $requirementsPath = Join-Path $ScriptsDir "requirements.txt"
    if (Test-Path $requirementsPath) {
        $pipResult = python -m pip install --user -r $requirementsPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Dépendances Python installées avec succès" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Avertissement lors de l'installation des dépendances:" -ForegroundColor Yellow
            Write-Host $pipResult -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Fichier requirements.txt non trouvé, tentative d'installation manuelle..." -ForegroundColor Yellow
        python -m pip install --user rich pyperclip requests 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Dépendances de base installées" -ForegroundColor Green
        } else {
            Write-Host "❌ Erreur lors de l'installation des dépendances de base" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Erreur lors de l'installation des dépendances Python:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "💡 Vous devrez peut-être installer manuellement: pip install rich pyperclip requests" -ForegroundColor Yellow
}

# Create PowerShell script wrapper
$wrapperScript = @"
# AI Terminal Chat - Windows Wrapper
param([Parameter(ValueFromRemainingArguments=`$true)][string[]]`$Arguments)

`$scriptPath = "$ScriptsDir\ai_chat_windows.py"
if (Test-Path `$scriptPath) {
    python `$scriptPath @Arguments
} else {
    Write-Host "❌ AI Terminal Chat non trouvé. Réinstallez le programme." -ForegroundColor Red
}
"@

$wrapperPath = "$ScriptsDir\chat.ps1"
$wrapperScript | Out-File -FilePath $wrapperPath -Encoding UTF8 -Force

Write-Host "🔗 Création de la commande globale 'chat'..." -ForegroundColor Blue

# Create batch file for global access
$batchWrapper = @"
@echo off
powershell -ExecutionPolicy Bypass -File "$wrapperPath" %*
"@

$batchPath = "$ScriptsDir\chat.bat"
$batchWrapper | Out-File -FilePath $batchPath -Encoding ASCII -Force

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$ScriptsDir*") {
    Write-Host "🔄 Ajout au PATH utilisateur..." -ForegroundColor Blue
    try {
        # Clean up any empty entries and normalize separators
        $pathEntries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' }
        $pathEntries += $ScriptsDir
        $newPath = ($pathEntries | Sort-Object -Unique) -join ';'
        
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "✅ PATH mis à jour avec succès" -ForegroundColor Green
        Write-Host "⚠️  Redémarrez votre terminal pour utiliser la commande 'chat'" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Erreur lors de la modification du PATH:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "💡 Vous devrez peut-être ajouter manuellement '$ScriptsDir' à votre PATH" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Répertoire déjà présent dans le PATH" -ForegroundColor Green
}

# Set execution policy for current user if needed
try {
    $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($executionPolicy -eq "Restricted") {
        Write-Host "🔓 Configuration de la politique d'exécution PowerShell..." -ForegroundColor Blue
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✅ Politique d'exécution configurée" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Impossible de modifier la politique d'exécution" -ForegroundColor Yellow
    Write-Host "💡 Vous devrez peut-être exécuter manuellement:" -ForegroundColor Yellow
    Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎉 Installation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Pour utiliser AI Terminal Chat:" -ForegroundColor Cyan
Write-Host "   1. Redémarrez votre terminal (PowerShell, CMD, ou Windows Terminal)" -ForegroundColor White
Write-Host "   2. Tapez: chat" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Configuration:" -ForegroundColor Cyan
Write-Host "   - Première utilisation: configuration interactive automatique" -ForegroundColor White
Write-Host "   - Reconfigurer: chat --config" -ForegroundColor White
Write-Host "   - Sélecteur de langue: chat --select-lang" -ForegroundColor White
Write-Host ""
Write-Host "💡 Fonctionnalités Windows:" -ForegroundColor Cyan
Write-Host "   - Détection automatique de la langue Windows" -ForegroundColor White
Write-Host "   - Intégration PowerShell native" -ForegroundColor White
Write-Host "   - Support Windows Terminal et PowerShell ISE" -ForegroundColor White
Write-Host "   - Configuration dans %LOCALAPPDATA%" -ForegroundColor White
Write-Host ""
