# AI Terminal Chat - Security Validation Script for Windows
# PowerShell script for validating security configuration

param(
    [switch]$Detailed = $false,
    [switch]$FixIssues = $false
)

Write-Host "🛡️  AI Terminal Chat - Validation de Sécurité" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray

# Security check functions
function Test-PythonSecurity {
    Write-Host "🔍 Vérification de la sécurité Python..." -ForegroundColor Blue
    
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "   ✅ Python version: $pythonVersion" -ForegroundColor Green
        
        # Check for known vulnerable Python versions
        if ($pythonVersion -match "Python (\d+)\.(\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2] 
            $patch = [int]$matches[3]
            
            # Check for known vulnerabilities
            $vulnerableVersions = @(
                @{Major=3; Minor=7; Patch=0; Issue="CVE-2021-3737"},
                @{Major=3; Minor=8; Patch=0; Issue="CVE-2021-3737"}
            )
            
            foreach ($vuln in $vulnerableVersions) {
                if ($major -eq $vuln.Major -and $minor -eq $vuln.Minor -and $patch -le $vuln.Patch) {
                    Write-Host "   ⚠️  Version Python potentiellement vulnérable: $($vuln.Issue)" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host "   ❌ Python non trouvé ou inaccessible" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Test-PackageSecurity {
    Write-Host "🔍 Vérification de la sécurité des packages..." -ForegroundColor Blue
    
    try {
        # Check for security-related packages
        $securityPackages = @("cryptography", "requests")
        
        foreach ($package in $securityPackages) {
            $result = python -c "import $package; print('$package:', $package.__version__)" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ $result" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Package $package non installé ou version problématique" -ForegroundColor Yellow
                if ($FixIssues) {
                    Write-Host "   🔧 Installation de $package..." -ForegroundColor Blue
                    python -m pip install --user --upgrade $package
                }
            }
        }
        
        # Check for known vulnerable packages
        $vulnCheck = python -c "
import sys
try:
    import requests
    version = requests.__version__
    # Check for known vulnerable requests versions
    vulnerable_versions = ['2.20.0', '2.19.1', '2.18.4']
    if version in vulnerable_versions:
        print('WARNING: requests version', version, 'has known vulnerabilities')
    else:
        print('OK: requests version', version, 'appears secure')
except ImportError:
    print('ERROR: requests not installed')
" 2>&1
        
        if ($vulnCheck -match "WARNING") {
            Write-Host "   ⚠️  $vulnCheck" -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ $vulnCheck" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "   ❌ Erreur lors de la vérification des packages" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Test-FilePermissions {
    Write-Host "🔍 Vérification des permissions de fichiers..." -ForegroundColor Blue
    
    $installDir = "$env:LOCALAPPDATA\ai_terminal_chat"
    $scriptsDir = "$env:USERPROFILE\ai_terminal_chat_scripts"
    
    foreach ($dir in @($installDir, $scriptsDir)) {
        if (Test-Path $dir) {
            try {
                $acl = Get-Acl -Path $dir
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $owner = $acl.Owner
                
                if ($owner -eq $currentUser) {
                    Write-Host "   ✅ Propriétaire correct pour: $dir" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠️  Propriétaire inattendu pour: $dir" -ForegroundColor Yellow
                    Write-Host "      Actuel: $owner, Attendu: $currentUser" -ForegroundColor Gray
                }
                
                # Check for world-writable permissions (Windows equivalent)
                $accessRules = $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
                foreach ($rule in $accessRules) {
                    if ($rule.IdentityReference.Value -eq "S-1-1-0" -and $rule.FileSystemRights -match "Write") {
                        Write-Host "   ⚠️  Permissions trop permissives détectées: $dir" -ForegroundColor Yellow
                    }
                }
                
            } catch {
                Write-Host "   ❌ Erreur lors de la vérification des permissions: $dir" -ForegroundColor Red
            }
        } else {
            Write-Host "   ⚠️  Répertoire non trouvé: $dir" -ForegroundColor Yellow
        }
    }
}

function Test-ConfigSecurity {
    Write-Host "🔍 Vérification de la sécurité des configurations..." -ForegroundColor Blue
    
    $configDir = "$env:LOCALAPPDATA\ai_terminal_chat"
    $configFiles = @(
        "config.json",
        "secure_config.json", 
        "rate_limits.json",
        "audit.log"
    )
    
    foreach ($configFile in $configFiles) {
        $filePath = Join-Path $configDir $configFile
        if (Test-Path $filePath) {
            try {
                # Check if config contains plaintext API keys
                if ($configFile -eq "config.json") {
                    $content = Get-Content $filePath -Raw
                    if ($content -match '"api_key":\s*"[^"]*"' -and $content -notmatch '"api_key_encrypted"') {
                        Write-Host "   ⚠️  Clé API en texte clair détectée dans $configFile" -ForegroundColor Yellow
                        Write-Host "      Recommandation: Utilisez le mode sécurisé pour chiffrer les clés" -ForegroundColor Gray
                    } else {
                        Write-Host "   ✅ Configuration sécurisée: $configFile" -ForegroundColor Green
                    }
                }
                
                # Check file size for potential issues
                $fileSize = (Get-Item $filePath).Length
                if ($fileSize -gt 1MB) {
                    Write-Host "   ⚠️  Fichier de configuration volumineux: $configFile ($fileSize bytes)" -ForegroundColor Yellow
                }
                
            } catch {
                Write-Host "   ❌ Erreur lors de l'analyse de $configFile" -ForegroundColor Red
            }
        } else {
            Write-Host "   ℹ️  Fichier de configuration non trouvé: $configFile" -ForegroundColor Gray
        }
    }
}

function Test-NetworkSecurity {
    Write-Host "🔍 Vérification de la sécurité réseau..." -ForegroundColor Blue
    
    # Test common API endpoints with basic security checks
    $endpoints = @(
        @{Name="OpenAI"; URL="https://api.openai.com/v1/models"; ExpectedStatus=401},
        @{Name="Anthropic"; URL="https://api.anthropic.com/v1/messages"; ExpectedStatus=401},
        @{Name="Groq"; URL="https://api.groq.com/openai/v1/models"; ExpectedStatus=401}
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.URL -Method GET -TimeoutSec 10 -ErrorAction SilentlyContinue
            Write-Host "   ℹ️  $($endpoint.Name): Endpoint accessible" -ForegroundColor Blue
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq $endpoint.ExpectedStatus) {
                Write-Host "   ✅ $($endpoint.Name): Endpoint sécurisé (Status $statusCode)" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  $($endpoint.Name): Status inattendu ($statusCode)" -ForegroundColor Yellow
            }
        }
    }
}

function Show-SecuritySummary {
    Write-Host "`n📊 Résumé de Sécurité:" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Gray
    
    Write-Host "🔐 Recommandations de sécurité:" -ForegroundColor Yellow
    Write-Host "   1. Utilisez toujours le mode sécurisé: chat --secure-mode" -ForegroundColor White
    Write-Host "   2. Chiffrez vos clés API avec un mot de passe fort" -ForegroundColor White
    Write-Host "   3. Surveillez les logs d'audit régulièrement" -ForegroundColor White
    Write-Host "   4. Mettez à jour les dépendances Python régulièrement" -ForegroundColor White
    Write-Host "   5. Limitez les permissions des fichiers de configuration" -ForegroundColor White
    
    Write-Host "`n🛡️  Fonctionnalités de sécurité disponibles:" -ForegroundColor Cyan
    Write-Host "   • Validation des entrées utilisateur" -ForegroundColor White
    Write-Host "   • Limitation du taux de requêtes API" -ForegroundColor White
    Write-Host "   • Chiffrement des données sensibles" -ForegroundColor White
    Write-Host "   • Logging sécurisé des activités" -ForegroundColor White
    Write-Host "   • Protection contre l'injection de commandes" -ForegroundColor White
}

# Main execution
try {
    $pythonOk = Test-PythonSecurity
    $packagesOk = Test-PackageSecurity
    Test-FilePermissions
    Test-ConfigSecurity
    Test-NetworkSecurity
    
    if ($Detailed) {
        Show-SecuritySummary
    }
    
    Write-Host "`n🎉 Validation de sécurité terminée!" -ForegroundColor Green
    
    if (-not $pythonOk -or -not $packagesOk) {
        Write-Host "⚠️  Des problèmes de sécurité ont été détectés." -ForegroundColor Yellow
        Write-Host "💡 Exécutez ce script avec -FixIssues pour tenter de les corriger." -ForegroundColor Cyan
        exit 1
    }
    
} catch {
    Write-Host "❌ Erreur lors de la validation de sécurité: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
