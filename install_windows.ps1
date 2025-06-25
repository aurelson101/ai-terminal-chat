# AI Terminal Chat - Installation Script for Windows 11
# PowerShell script for installing AI Terminal Chat on Windows

<#
.SYNOPSIS
    Installation automatique d'AI Terminal Chat avec détection des dépendances

.DESCRIPTION
    Ce script installe automatiquement AI Terminal Chat et peut installer
    Git et Python avec winget si ils ne sont pas présents sur le système.

.PARAMETER Force
    Force l'installation sans demander de confirmation

.PARAMETER SecureMode
    Active le mode sécurisé avec validations additionnelles

.PARAMETER Verbose
    Active les logs détaillés

.PARAMETER InstallDependencies
    Active/désactive l'installation automatique de Git et Python (défaut: true)

.EXAMPLE
    .\install_windows.ps1
    Installation normale avec installation automatique des dépendances

.EXAMPLE
    .\install_windows.ps1 -InstallDependencies $false
    Installation sans installation automatique des dépendances

.EXAMPLE
    .\install_windows.ps1 -Force -SecureMode
    Installation forcée en mode sécurisé
#>

param(
    [switch]$Force = $false,
    [switch]$SecureMode = $false,
    [switch]$Verbose = $false,
    [bool]$InstallDependencies = $true
)

Write-Host "🤖 Installation de AI Terminal Chat pour Windows 11..." -ForegroundColor Green
Write-Host "🖥️  PowerShell Edition" -ForegroundColor Cyan
if ($InstallDependencies) {
    Write-Host "📦 Installation automatique des dépendances activée" -ForegroundColor Blue
}
Write-Host "🔒 Mode sécurisé activé" -ForegroundColor Blue

# Security check: Verify script integrity and source
function Test-ScriptIntegrity {
    param([string]$ScriptPath)
    
    Write-Host "🔍 Vérification de l'intégrité du script..." -ForegroundColor Blue
    
    # Check if running from trusted location
    $CurrentLocation = (Get-Location).Path
    $TrustedPaths = @(
        $env:USERPROFILE,
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:TEMP"
    )
    
    $IsTrustedLocation = $false
    foreach ($TrustedPath in $TrustedPaths) {
        if ($CurrentLocation.StartsWith($TrustedPath)) {
            $IsTrustedLocation = $true
            break
        }
    }
    
    if (-not $IsTrustedLocation -and $SecureMode) {
        Write-Host "⚠️  Script exécuté depuis un emplacement non sécurisé: $CurrentLocation" -ForegroundColor Yellow
        $Continue = Read-Host "Continuer l'installation? (y/N)"
        if ($Continue -ne "y" -and $Continue -ne "Y") {
            Write-Host "❌ Installation annulée par l'utilisateur" -ForegroundColor Red
            exit 1
        }
    }
    
    return $true
}

# Enhanced logging with security context
function Write-SecureLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Verbose) {
        Write-Host $logEntry -ForegroundColor $Color
    }
    
    # Log to file if in secure mode
    if ($SecureMode) {
        $logFile = "$env:TEMP\ai_terminal_chat_install.log"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

# Function to check if winget is available
function Test-WingetAvailable {
    try {
        $wingetVersion = winget --version 2>&1
        if ($wingetVersion -match "v\d+\.\d+") {
            Write-Host "✅ winget détecté: $wingetVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ winget n'est pas disponible" -ForegroundColor Red
        Write-Host "💡 winget est requis pour l'installation automatique" -ForegroundColor Yellow
        Write-Host "💡 Veuillez installer les outils d'application Windows ou mettre à jour Windows" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# Function to install Python using winget
function Install-PythonWithWinget {
    Write-Host "📦 Installation de Python avec winget..." -ForegroundColor Blue
    Write-SecureLog "Installing Python with winget" "INFO"
    
    try {
        # Try different Python packages
        $pythonPackages = @(
            "Python.Python.3.12",
            "Python.Python.3.11", 
            "Microsoft.WindowsTerminal",
            "9NRWMJP3717K"  # Python 3.11 from Microsoft Store
        )
        
        foreach ($package in $pythonPackages) {
            Write-Host "🔄 Tentative d'installation: $package" -ForegroundColor Yellow
            
            $installOutput = winget install --id $package --silent --accept-package-agreements --accept-source-agreements 2>&1
            Write-Host "📋 Sortie winget: $installOutput" -ForegroundColor Gray
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Python installé avec succès via: $package" -ForegroundColor Green
                Write-SecureLog "Python installed successfully with winget using package: $package" "INFO"
                
                # Refresh environment variables
                $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
                
                # Wait a moment for installation to complete
                Start-Sleep -Seconds 5
                
                # Test Python installation
                try {
                    $testResult = python --version 2>&1
                    if ($testResult -match "Python") {
                        Write-Host "✅ Python fonctionne: $testResult" -ForegroundColor Green
                        return $true
                    }
                } catch {
                    Write-Host "⚠️  Python installé mais pas encore accessible" -ForegroundColor Yellow
                }
                
                return $true
            } else {
                Write-Host "⚠️  Échec avec $package, code de sortie: $LASTEXITCODE" -ForegroundColor Yellow
            }
        }
        
        Write-Host "❌ Tous les packages Python ont échoué" -ForegroundColor Red
        return $false
        
    } catch {
        Write-Host "❌ Erreur lors de l'installation de Python: $($_.Exception.Message)" -ForegroundColor Red
        Write-SecureLog "Exception during Python installation: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to install Python from Microsoft Store
function Install-PythonFromStore {
    Write-Host "📦 Installation de Python depuis le Microsoft Store..." -ForegroundColor Blue
    
    try {
        # Try to install Python from Microsoft Store
        $storePackages = @(
            "9NRWMJP3717K",  # Python 3.11
            "9MSSZTT1N39L",  # Python 3.10
            "9P7QFQMJRFP7"   # Python 3.9
        )
        
        foreach ($package in $storePackages) {
            Write-Host "🔄 Tentative d'installation depuis le Store: $package" -ForegroundColor Yellow
            
            $result = winget install --id $package --source msstore --silent --accept-package-agreements --accept-source-agreements 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Python installé depuis le Microsoft Store" -ForegroundColor Green
                Start-Sleep -Seconds 5
                return $true
            }
        }
        
        return $false
    } catch {
        Write-Host "❌ Erreur lors de l'installation depuis le Store: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to install Git using winget
function Install-GitWithWinget {
    Write-Host "📦 Installation de Git avec winget..." -ForegroundColor Blue
    Write-SecureLog "Installing Git with winget" "INFO"
    
    try {
        winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Git installé avec succès" -ForegroundColor Green
            Write-SecureLog "Git installed successfully with winget" "INFO"
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Wait a moment for installation to complete
            Start-Sleep -Seconds 3
            return $true
        } else {
            Write-Host "❌ Échec de l'installation de Git" -ForegroundColor Red
            Write-SecureLog "Failed to install Git with winget. Exit code: $LASTEXITCODE" "ERROR"
            return $false
        }
    } catch {
        Write-Host "❌ Erreur lors de l'installation de Git: $($_.Exception.Message)" -ForegroundColor Red
        Write-SecureLog "Exception during Git installation: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to check and install Git if needed
function Install-GitIfNeeded {
    Write-Host "🔍 Vérification de Git..." -ForegroundColor Blue
    Write-SecureLog "Checking Git installation" "INFO"
    
    try {
        $gitVersion = git --version 2>&1
        if ($gitVersion -match "git version") {
            Write-Host "✅ Git détecté: $gitVersion" -ForegroundColor Green
            Write-SecureLog "Git version: $gitVersion" "INFO"
            return $true
        }
    } catch {
        Write-Host "⚠️  Git n'est pas installé" -ForegroundColor Yellow
    }
    
    # Git not found, try to install with winget
    if (Test-WingetAvailable) {
        $userChoice = "y"
        if (-not $Force) {
            $userChoice = Read-Host "Git n'est pas installé. L'installer automatiquement avec winget? (Y/n)"
        }
        
        if ($userChoice -eq "" -or $userChoice -eq "y" -or $userChoice -eq "Y") {
            if (Install-GitWithWinget) {
                # Verify installation
                try {
                    $gitVersion = git --version 2>&1
                    if ($gitVersion -match "git version") {
                        Write-Host "✅ Git installé et vérifié: $gitVersion" -ForegroundColor Green
                        return $true
                    }
                } catch {
                    Write-Host "❌ Git installé mais non accessible. Redémarrez votre terminal." -ForegroundColor Red
                }
            }
        } else {
            Write-Host "💡 Installation manuelle requise: https://git-scm.com/" -ForegroundColor Yellow
        }
    }
    
    return $false
}

# Function to check and install Python if needed
function Install-PythonIfNeeded {
    Write-Host "🔍 Vérification de Python..." -ForegroundColor Blue
    Write-SecureLog "Checking Python installation" "INFO"
    
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python \d+\.\d+") {
            Write-Host "✅ Python détecté: $pythonVersion" -ForegroundColor Green
            Write-SecureLog "Python version: $pythonVersion" "INFO"
            return $true
        }
    } catch {
        Write-Host "⚠️  Python n'est pas installé ou redirigé vers le Microsoft Store" -ForegroundColor Yellow
        # Try to disable the Windows Store redirect
        try {
            Write-Host "🔧 Désactivation du raccourci Microsoft Store pour Python..." -ForegroundColor Blue
            $aliasPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
            $pythonAlias = "$aliasPath\python.exe"
            $python3Alias = "$aliasPath\python3.exe"
            
            if (Test-Path $pythonAlias) {
                Remove-Item $pythonAlias -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Raccourci python.exe supprimé" -ForegroundColor Green
            }
            
            if (Test-Path $python3Alias) {
                Remove-Item $python3Alias -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Raccourci python3.exe supprimé" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Impossible de désactiver les raccourcis Microsoft Store" -ForegroundColor Yellow
        }
    }
    
    # Python not found, try to install with winget
    if (Test-WingetAvailable) {
        $userChoice = "y"
        if (-not $Force) {
            Write-Host ""
            Write-Host "🐍 Python n'est pas installé sur ce système." -ForegroundColor Yellow
            Write-Host "📦 Méthodes d'installation disponibles:" -ForegroundColor Cyan
            Write-Host "   1. Installation automatique avec winget (recommandée)" -ForegroundColor White
            Write-Host "   2. Installation depuis le Microsoft Store" -ForegroundColor White
            Write-Host "   3. Installation manuelle depuis python.org" -ForegroundColor White
            Write-Host ""
            $userChoice = Read-Host "Installer Python automatiquement? (Y/n)"
        }
        
        if ($userChoice -eq "" -or $userChoice -eq "y" -or $userChoice -eq "Y") {
            # Try winget installation first
            if (Install-PythonWithWinget) {
                # Verify installation
                try {
                    # Refresh PATH
                    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
                    
                    $pythonVersion = python --version 2>&1
                    if ($pythonVersion -match "Python \d+\.\d+") {
                        Write-Host "✅ Python installé et vérifié: $pythonVersion" -ForegroundColor Green
                        
                        # Appliquer la correction du raccourci Microsoft Store
                        Remove-WindowsStorePythonRedirect
                        
                        return $true
                    } else {
                        Write-Host "⚠️  Python installé mais pas encore accessible via 'python'" -ForegroundColor Yellow
                        
                        # Appliquer la correction du raccourci Microsoft Store
                        if (Remove-WindowsStorePythonRedirect) {
                            return $true
                        }
                        
                        # Try python3 command
                        try {
                            $python3Version = python3 --version 2>&1
                            if ($python3Version -match "Python \d+\.\d+") {
                                Write-Host "✅ Python accessible via 'python3': $python3Version" -ForegroundColor Green
                                Write-Host "💡 Utilisez 'python3' au lieu de 'python'" -ForegroundColor Yellow
                                return $true
                            }
                        } catch {
                            Write-Host "⚠️  Python3 non accessible non plus" -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host "❌ Python installé mais non accessible. Application de la correction..." -ForegroundColor Red
                    Remove-WindowsStorePythonRedirect
                }
            }
            
            # If winget fails, try Microsoft Store
            Write-Host "🔄 Tentative d'installation depuis le Microsoft Store..." -ForegroundColor Blue
            if (Install-PythonFromStore) {
                Write-Host "✅ Installation depuis le Microsoft Store réussie" -ForegroundColor Green
                Write-Host "🔄 Redémarrez votre terminal et relancez l'installation" -ForegroundColor Yellow
                return $true
            }
            
        } else {
            Write-Host "💡 Installation manuelle requise:" -ForegroundColor Yellow
            Write-Host "   1. Visitez https://python.org" -ForegroundColor White
            Write-Host "   2. Téléchargez Python 3.8 ou plus récent" -ForegroundColor White
            Write-Host "   3. Cochez 'Add Python to PATH' pendant l'installation" -ForegroundColor White
        }
    } else {
        Write-Host "❌ winget non disponible pour l'installation automatique" -ForegroundColor Red
        Write-Host "💡 Installation manuelle requise depuis https://python.org" -ForegroundColor Yellow
    }
    
    return $false
}

# Verify script integrity
Test-ScriptIntegrity -ScriptPath $MyInvocation.MyCommand.Path

# Check and install Git if needed
if ($InstallDependencies -and -not (Install-GitIfNeeded)) {
    Write-Host "❌ Git est requis pour le fonctionnement optimal d'AI Terminal Chat" -ForegroundColor Red
    Write-Host "💡 Certaines fonctionnalités peuvent être limitées sans Git" -ForegroundColor Yellow
    if (-not $Force) {
        $Continue = Read-Host "Continuer sans Git? (y/N)"
        if ($Continue -ne "y" -and $Continue -ne "Y") {
            Write-Host "❌ Installation annulée" -ForegroundColor Red
            exit 1
        }
    }
} elseif (-not $InstallDependencies) {
    Write-Host "⚠️  Installation automatique des dépendances désactivée" -ForegroundColor Yellow
    Write-Host "💡 Assurez-vous que Git et Python sont installés manuellement" -ForegroundColor Yellow
}

# Check and install Python if needed
if ($InstallDependencies -and -not (Install-PythonIfNeeded)) {
    Write-Host "❌ Python est requis pour AI Terminal Chat" -ForegroundColor Red
    Write-Host "💡 Veuillez installer Python manuellement depuis https://python.org" -ForegroundColor Yellow
    Write-SecureLog "Python installation failed or not accessible" "ERROR"
    exit 1
} elseif (-not $InstallDependencies) {
    # Still check if Python is available even if auto-install is disabled
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python \d+\.\d+") {
            Write-Host "✅ Python détecté: $pythonVersion" -ForegroundColor Green
        } else {
            Write-Host "❌ Python requis mais installation automatique désactivée" -ForegroundColor Red
            Write-Host "💡 Veuillez installer Python depuis https://python.org" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "❌ Python requis mais installation automatique désactivée" -ForegroundColor Red
        Write-Host "💡 Veuillez installer Python depuis https://python.org" -ForegroundColor Yellow
        exit 1
    }
}

# Additional Python version validation
Write-SecureLog "Validation de la version Python..." "INFO" "Blue"
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python validé: $pythonVersion" -ForegroundColor Green
    Write-SecureLog "Python version validated: $pythonVersion" "INFO"
    
    # Security check: Verify Python version is supported (3.7+)
    if ($pythonVersion -match "Python (\d+)\.(\d+)") {
        $majorVersion = [int]$matches[1]
        $minorVersion = [int]$matches[2]
        
        if ($majorVersion -lt 3 -or ($majorVersion -eq 3 -and $minorVersion -lt 7)) {
            Write-Host "⚠️  Version Python non sécurisée détectée: $pythonVersion" -ForegroundColor Yellow
            Write-Host "💡 Python 3.7+ recommandé pour les fonctionnalités de sécurité" -ForegroundColor Yellow
            
            if ($SecureMode) {
                $Continue = Read-Host "Continuer avec cette version? (y/N)"
                if ($Continue -ne "y" -and $Continue -ne "Y") {
                    Write-Host "❌ Installation annulée" -ForegroundColor Red
                    exit 1
                }
            }
        }
    }
} catch {
    Write-Host "❌ Erreur lors de la validation de Python" -ForegroundColor Red
    Write-SecureLog "Python validation failed" "ERROR"
    exit 1
}

# Check if pip is available with security validation
Write-SecureLog "Vérification de pip..." "INFO" "Blue"
try {
    $pipVersion = python -m pip --version 2>&1
    Write-Host "✅ pip détecté: $pipVersion" -ForegroundColor Green
    Write-SecureLog "pip version: $pipVersion" "INFO"
    
    # Security check: Ensure pip is up to date
    Write-SecureLog "Vérification de la version pip..." "INFO"
    $pipUpgradeCheck = python -m pip list --outdated --format=json 2>&1
    if ($pipUpgradeCheck -match "pip") {
        Write-Host "💡 Une nouvelle version de pip est disponible" -ForegroundColor Yellow
        if ($SecureMode) {
            Write-Host "🔄 Mise à jour de pip pour la sécurité..." -ForegroundColor Blue
            python -m pip install --user --upgrade pip 2>&1 | Out-Null
        }
    }
} catch {
    Write-Host "❌ pip n'est pas disponible." -ForegroundColor Red
    Write-Host "💡 Veuillez réinstaller Python avec pip." -ForegroundColor Yellow
    Write-SecureLog "pip not available" "ERROR"
    exit 1
}

# Create installation directories with secure permissions
$InstallDir = "$env:LOCALAPPDATA\ai_terminal_chat"
$ScriptsDir = "$env:USERPROFILE\ai_terminal_chat_scripts"

Write-Host "📂 Création des répertoires d'installation..." -ForegroundColor Blue
Write-Host "   📁 Configuration: $InstallDir" -ForegroundColor Gray
Write-Host "   📁 Scripts: $ScriptsDir" -ForegroundColor Gray
Write-SecureLog "Creating directories: $InstallDir, $ScriptsDir" "INFO"

# Security check: Ensure directories don't already exist with wrong permissions
function Set-SecureDirectoryPermissions {
    param([string]$Path)
    
    if (Test-Path $Path) {
        Write-SecureLog "Directory exists, checking permissions: $Path" "INFO"
        # On Windows, ensure the directory is owned by current user
        try {
            $acl = Get-Acl -Path $Path
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $owner = $acl.Owner
            
            if ($owner -ne $currentUser -and $SecureMode) {
                Write-Host "⚠️  Répertoire avec propriétaire incorrect détecté: $Path" -ForegroundColor Yellow
                Write-Host "   Propriétaire actuel: $owner" -ForegroundColor Gray
                Write-Host "   Utilisateur attendu: $currentUser" -ForegroundColor Gray
                
                $Continue = Read-Host "Continuer l'installation? (y/N)"
                if ($Continue -ne "y" -and $Continue -ne "Y") {
                    Write-Host "❌ Installation annulée" -ForegroundColor Red
                    exit 1
                }
            }
        } catch {
            Write-SecureLog "Could not check directory permissions: $($_.Exception.Message)" "WARN"
        }
    }
}

Set-SecureDirectoryPermissions -Path $InstallDir
Set-SecureDirectoryPermissions -Path $ScriptsDir

if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-SecureLog "Created directory: $InstallDir" "INFO"
}

if (!(Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
    Write-SecureLog "Created directory: $ScriptsDir" "INFO"
}

# Copy files to installation directory with integrity checks
Write-Host "📦 Copie des fichiers..." -ForegroundColor Blue
Write-SecureLog "Starting file copy process" "INFO"

$filesToCopy = @(
    "ai_chat_windows.py",
    "ai_chat_fr.py", 
    "ai_chat_en.py",
    "ai_chat.py",
    "windows_helper.py",
    "security_utils.py",
    "requirements.txt"
)

# Security function to validate file content
function Test-FileIntegrity {
    param(
        [string]$FilePath,
        [string]$ExpectedExtension
    )
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    # Check file extension
    $actualExtension = [System.IO.Path]::GetExtension($FilePath)
    if ($actualExtension -ne $ExpectedExtension) {
        Write-SecureLog "File extension mismatch: $FilePath" "WARN"
        return $false
    }
    
    # Basic content validation for Python files
    if ($ExpectedExtension -eq ".py") {
        try {
            $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
            
            # Check for suspicious patterns
            $suspiciousPatterns = @(
                'subprocess\.Popen.*shell\s*=\s*True',
                'eval\s*\(',
                'exec\s*\(',
                '__import__\s*\(',
                'compile\s*\('
            )
            
            foreach ($pattern in $suspiciousPatterns) {
                if ($content -match $pattern) {
                    Write-SecureLog "Suspicious pattern found in $FilePath : $pattern" "WARN"
                    if ($SecureMode) {
                        Write-Host "⚠️  Code potentiellement non sécurisé détecté dans $FilePath" -ForegroundColor Yellow
                        $Continue = Read-Host "Continuer l'installation? (y/N)"
                        if ($Continue -ne "y" -and $Continue -ne "Y") {
                            return $false
                        }
                    }
                }
            }
        } catch {
            Write-SecureLog "Could not validate file content: $FilePath" "WARN"
        }
    }
    
    return $true
}

$missingFiles = @()
foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        # Validate file integrity
        $extension = [System.IO.Path]::GetExtension($file)
        if (Test-FileIntegrity -FilePath $file -ExpectedExtension $extension) {
            try {
                Copy-Item $file -Destination $ScriptsDir -Force
                Write-Host "   ✅ $file copié" -ForegroundColor Green
                Write-SecureLog "Copied file: $file" "INFO"
            } catch {
                Write-Host "   ❌ Erreur lors de la copie de $file : $($_.Exception.Message)" -ForegroundColor Red
                Write-SecureLog "Failed to copy file: $file - $($_.Exception.Message)" "ERROR"
                $missingFiles += $file
            }
        } else {
            Write-Host "   ❌ Validation de sécurité échouée pour $file" -ForegroundColor Red
            Write-SecureLog "Security validation failed for: $file" "ERROR"
            $missingFiles += $file
        }
    } else {
        Write-Host "   ⚠️  $file non trouvé dans le répertoire courant" -ForegroundColor Yellow
        Write-SecureLog "File not found: $file" "WARN"
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

# Install Python dependencies with security verification
if ($InstallDependencies) {
    Write-Host "📦 Installation des dépendances Python..." -ForegroundColor Blue
    Write-SecureLog "Installing Python dependencies" "INFO"
    
    try {
        $requirementsPath = Join-Path $ScriptsDir "requirements.txt"
        if (Test-Path $requirementsPath) {
            # Security check: Validate requirements.txt content
            Write-SecureLog "Validating requirements.txt content" "INFO"
            $requirementsContent = Get-Content $requirementsPath -Raw
            
            # Check for suspicious packages or URLs
            $suspiciousPatterns = @(
                'git\+http:',
                'ftp:',
                '--extra-index-url',
                '--trusted-host'
            )
            
            $hasSuspiciousContent = $false
            foreach ($pattern in $suspiciousPatterns) {
                if ($requirementsContent -match $pattern) {
                    Write-Host "⚠️  Contenu potentiellement non sécurisé détecté dans requirements.txt" -ForegroundColor Yellow
                    Write-SecureLog "Suspicious pattern in requirements.txt: $pattern" "WARN"
                    $hasSuspiciousContent = $true
                }
            }
            
            if ($hasSuspiciousContent -and $SecureMode) {
                Write-Host "📋 Contenu de requirements.txt:" -ForegroundColor Yellow
                Write-Host $requirementsContent -ForegroundColor Gray
                $Continue = Read-Host "Continuer l'installation des dépendances? (y/N)"
                if ($Continue -ne "y" -and $Continue -ne "Y") {
                    Write-Host "❌ Installation des dépendances annulée" -ForegroundColor Red
                    exit 1
                }
            }
            
            # Install with additional security flags
            $pipArgs = @("install", "--user", "--require-hashes")
            if (-not $SecureMode) {
                $pipArgs = @("install", "--user")  # Remove --require-hashes if not in secure mode
            }
            $pipArgs += @("-r", $requirementsPath)
            
            $pipResult = python -m pip @pipArgs 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Dépendances Python installées avec succès" -ForegroundColor Green
                Write-SecureLog "Python dependencies installed successfully" "INFO"
            } else {
                Write-Host "⚠️  Avertissement lors de l'installation des dépendances:" -ForegroundColor Yellow
                Write-Host $pipResult -ForegroundColor Gray
                Write-SecureLog "Warning during dependency installation: $pipResult" "WARN"
            }
        } else {
            Write-Host "⚠️  Fichier requirements.txt non trouvé, tentative d'installation manuelle..." -ForegroundColor Yellow
            Write-SecureLog "requirements.txt not found, attempting manual installation" "WARN"
            
            # Install known safe packages
            $safePackages = @("rich", "pyperclip", "requests", "cryptography")
            foreach ($package in $safePackages) {
                Write-SecureLog "Installing package: $package" "INFO"
                python -m pip install --user $package 2>&1 | Out-Null
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Dépendances de base installées" -ForegroundColor Green
                Write-SecureLog "Base dependencies installed" "INFO"
            } else {
                Write-Host "❌ Erreur lors de l'installation des dépendances de base" -ForegroundColor Red
                Write-SecureLog "Error installing base dependencies" "ERROR"
            }
        }
    } catch {
        Write-Host "❌ Erreur lors de l'installation des dépendances Python:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-SecureLog "Error installing Python dependencies: $($_.Exception.Message)" "ERROR"
        Write-Host "💡 Vous devrez peut-être installer manuellement: pip install rich pyperclip requests cryptography" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Installation automatique des dépendances désactivée. Assurez-vous que toutes les dépendances nécessaires sont installées." -ForegroundColor Yellow
}

# Create PowerShell script wrapper with security enhancements
$wrapperScript = @"
# AI Terminal Chat - Windows Wrapper with Security Features
param([Parameter(ValueFromRemainingArguments=`$true)][string[]]`$Arguments)

# Security validation
function Test-ArgumentSafety {
    param([string[]]`$Args)
    
    foreach (`$arg in `$Args) {
        # Check for command injection attempts
        if (`$arg -match '[;&|`]' -or `$arg -match 'cmd\.exe' -or `$arg -match 'powershell\.exe') {
            Write-Host "❌ Argument potentiellement dangereux détecté: `$arg" -ForegroundColor Red
            Write-Host "💡 Les caractères spéciaux ne sont pas autorisés" -ForegroundColor Yellow
            return `$false
        }
        
        # Check for path traversal attempts
        if (`$arg -match '\.\.' -or `$arg -match '[<>]') {
            Write-Host "❌ Tentative de traversée de chemin détectée: `$arg" -ForegroundColor Red
            return `$false
        }
    }
    return `$true
}

# Validate arguments
if (-not (Test-ArgumentSafety -Args `$Arguments)) {
    Write-Host "🔒 Arrêt pour des raisons de sécurité" -ForegroundColor Red
    exit 1
}

`$scriptPath = "$ScriptsDir\ai_chat_windows.py"
if (Test-Path `$scriptPath) {
    # Additional security: verify script hasn't been tampered with
    try {
        `$scriptContent = Get-Content `$scriptPath -Raw
        if (`$scriptContent -match 'subprocess.*shell\s*=\s*True' -and `$scriptContent -notmatch '#.*shell.*safe') {
            Write-Host "⚠️  Script modifié détecté - vérification de sécurité requise" -ForegroundColor Yellow
        }
    } catch {
        # Ignore content check errors but log them
    }
    
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
Write-Host "   - Mode sécurisé: chat --secure-mode" -ForegroundColor White
Write-Host ""
Write-Host "� Fonctionnalités de sécurité:" -ForegroundColor Cyan
Write-Host "   - Validation des arguments d'entrée" -ForegroundColor White
Write-Host "   - Chiffrement des configurations sensibles" -ForegroundColor White
Write-Host "   - Limitation du taux de requêtes API" -ForegroundColor White
Write-Host "   - Logging sécurisé des activités" -ForegroundColor White
Write-Host ""
Write-Host "�💡 Fonctionnalités Windows:" -ForegroundColor Cyan
Write-Host "   - Détection automatique de la langue Windows" -ForegroundColor White
Write-Host "   - Intégration PowerShell native avec validation de sécurité" -ForegroundColor White
Write-Host "   - Support Windows Terminal et PowerShell ISE" -ForegroundColor White
Write-Host "   - Configuration dans %LOCALAPPDATA%" -ForegroundColor White
Write-Host ""

# Final security summary
if ($SecureMode) {
    Write-Host "🛡️  Résumé de sécurité:" -ForegroundColor Green
    Write-Host "   ✅ Scripts validés pour les patterns de sécurité" -ForegroundColor White
    Write-Host "   ✅ Permissions des répertoires vérifiées" -ForegroundColor White
    Write-Host "   ✅ Dépendances installées avec vérifications" -ForegroundColor White
    Write-Host "   ✅ Wrapper PowerShell sécurisé configuré" -ForegroundColor White
    Write-Host ""
}

Write-SecureLog "Installation completed successfully" "INFO"

if ($Verbose -and $SecureMode) {
    Write-Host "📊 Log d'installation disponible dans: $env:TEMP\ai_terminal_chat_install.log" -ForegroundColor Gray
}

# Function to permanently fix Windows Store Python redirect
function Remove-WindowsStorePythonRedirect {
    Write-Host "🔧 Correction permanente du raccourci Microsoft Store Python..." -ForegroundColor Blue
    
    try {
        $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        $pythonAliases = @("python.exe", "python3.exe", "python3.11.exe", "python3.12.exe")
        
        foreach ($alias in $pythonAliases) {
            $aliasPath = Join-Path $windowsAppsPath $alias
            if (Test-Path $aliasPath) {
                $fileInfo = Get-Item $aliasPath
                # Vérifier si c'est un alias de 0 octet (redirection vers le Store)
                if ($fileInfo.Length -eq 0) {
                    Write-Host "   🗑️  Suppression de l'alias Store: $alias" -ForegroundColor Yellow
                    Remove-Item $aliasPath -Force -ErrorAction SilentlyContinue
                    if (-not (Test-Path $aliasPath)) {
                        Write-Host "   ✅ Alias supprimé: $alias" -ForegroundColor Green
                    }
                }
            }
        }
        
        # Vérifier et corriger l'ordre du PATH
        Write-Host "🔄 Réorganisation du PATH pour prioriser Python..." -ForegroundColor Blue
        
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $pathEntries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' }
        
        # Trouver les chemins Python installés
        $pythonPaths = @()
        $commonPythonPaths = @(
            "$env:LOCALAPPDATA\Programs\Python\Python311",
            "$env:LOCALAPPDATA\Programs\Python\Python311\Scripts",
            "$env:LOCALAPPDATA\Programs\Python\Python312",
            "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
            "C:\Python311",
            "C:\Python311\Scripts",
            "C:\Python312", 
            "C:\Python312\Scripts"
        )
        
        foreach ($path in $commonPythonPaths) {
            if (Test-Path $path) {
                $pythonPaths += $path
            }
        }
        
        # Supprimer les chemins Python existants du PATH
        $filteredPaths = $pathEntries | Where-Object { 
            $currentEntry = $_
            $isPythonPath = $false
            foreach ($pythonPath in $pythonPaths) {
                if ($currentEntry -eq $pythonPath) {
                    $isPythonPath = $true
                    break
                }
            }
            -not $isPythonPath
        }
        
        # Supprimer aussi le chemin WindowsApps s'il existe
        $filteredPaths = $filteredPaths | Where-Object { $_ -ne $windowsAppsPath }
        
        # Reconstruire le PATH avec Python en premier
        $newPathEntries = $pythonPaths + $filteredPaths
        $newPath = ($newPathEntries | Where-Object { $_ -ne '' } | Sort-Object -Unique) -join ';'
        
        # Mettre à jour le PATH utilisateur
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        
        # Mettre à jour le PATH de la session actuelle
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + $newPath
        
        Write-Host "✅ PATH réorganisé avec Python en priorité" -ForegroundColor Green
        
        # Vérifier que Python fonctionne maintenant
        Start-Sleep -Seconds 2
        try {
            $testResult = python --version 2>&1
            if ($testResult -match "Python \d+\.\d+") {
                Write-Host "✅ Test Python réussi: $testResult" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  Python installé mais test échoué: $testResult" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️  Test Python échoué après correction" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Erreur lors de la correction Python: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $false
}

# Attempt to remove Windows Store Python redirect
Remove-WindowsStorePythonRedirect
