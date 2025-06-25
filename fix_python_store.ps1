# Fix Python Microsoft Store Redirect Issue
# PowerShell script to permanently resolve Python command redirection

param(
    [switch]$Verbose = $false
)

Write-Host "🔧 AI Terminal Chat - Correction Python Microsoft Store" -ForegroundColor Green
Write-Host "=" * 55 -ForegroundColor Gray

function Remove-PythonStoreAliases {
    Write-Host "🗑️  Suppression des alias Microsoft Store..." -ForegroundColor Blue
    
    $windowsAppsPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    $aliases = @("python.exe", "python3.exe", "python3.11.exe", "python3.12.exe")
    $removed = 0
    
    foreach ($alias in $aliases) {
        $aliasPath = Join-Path $windowsAppsPath $alias
        if (Test-Path $aliasPath) {
            $fileInfo = Get-Item $aliasPath
            if ($fileInfo.Length -eq 0) {
                try {
                    Remove-Item $aliasPath -Force
                    Write-Host "   ✅ Supprimé: $alias" -ForegroundColor Green
                    $removed++
                } catch {
                    Write-Host "   ⚠️  Impossible de supprimer: $alias" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ℹ️  Conservé (vrai exécutable): $alias" -ForegroundColor Gray
            }
        }
    }
    
    if ($removed -eq 0) {
        Write-Host "   ℹ️  Aucun alias problématique trouvé" -ForegroundColor Gray
    } else {
        Write-Host "   🎉 $removed alias(es) supprimé(s)" -ForegroundColor Green
    }
    
    return $removed -gt 0
}

function Fix-PythonPath {
    Write-Host "🔄 Correction du PATH Python..." -ForegroundColor Blue
    
    # Trouver les installations Python valides
    $pythonPaths = @()
    $searchPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python311",
        "$env:LOCALAPPDATA\Programs\Python\Python311\Scripts", 
        "$env:LOCALAPPDATA\Programs\Python\Python312",
        "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
        "C:\Python311",
        "C:\Python311\Scripts",
        "C:\Python312", 
        "C:\Python312\Scripts",
        "C:\Program Files\Python311",
        "C:\Program Files\Python311\Scripts",
        "C:\Program Files\Python312",
        "C:\Program Files\Python312\Scripts"
    )
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $pythonPaths += $path
            Write-Host "   ✅ Trouvé: $path" -ForegroundColor Green
        }
    }
    
    if ($pythonPaths.Count -eq 0) {
        Write-Host "   ❌ Aucune installation Python trouvée!" -ForegroundColor Red
        return $false
    }
    
    # Reconstruire le PATH utilisateur
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' }
    
    # Supprimer les anciens chemins Python et WindowsApps
    $filteredPaths = $pathEntries | Where-Object { 
        $entry = $_
        $isOldPython = $false
        
        foreach ($pythonPath in $pythonPaths) {
            if ($entry -eq $pythonPath) {
                $isOldPython = $true
                break
            }
        }
        
        $isWindowsApps = $entry -eq "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        
        -not $isOldPython -and -not $isWindowsApps
    }
    
    # Construire le nouveau PATH avec Python en premier
    $newPathEntries = $pythonPaths + $filteredPaths
    $newPath = ($newPathEntries | Where-Object { $_ -ne '' } | Sort-Object -Unique) -join ';'
    
    try {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "   ✅ PATH utilisateur mis à jour" -ForegroundColor Green
        
        # Mettre à jour le PATH de la session actuelle
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $env:PATH = $machinePath + ";" + $newPath
        Write-Host "   ✅ PATH session mis à jour" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "   ❌ Erreur lors de la mise à jour du PATH: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-PythonAccess {
    Write-Host "🧪 Test d'accès à Python..." -ForegroundColor Blue
    
    try {
        $result = python --version 2>&1
        if ($result -match "Python \d+\.\d+") {
            Write-Host "   ✅ Python accessible: $result" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ❌ Python non accessible: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Erreur lors du test Python: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test avec python3
    try {
        $result = python3 --version 2>&1
        if ($result -match "Python \d+\.\d+") {
            Write-Host "   ℹ️  Python3 accessible: $result" -ForegroundColor Yellow
            Write-Host "   💡 Utilisez 'python3' au lieu de 'python'" -ForegroundColor Yellow
            return $true
        }
    } catch {
        # Ignore python3 errors
    }
    
    return $false
}

# Exécution principale
Write-Host ""
Write-Host "🔍 Diagnostic initial..." -ForegroundColor Cyan

$initialTest = Test-PythonAccess
if ($initialTest) {
    Write-Host "✅ Python fonctionne déjà correctement!" -ForegroundColor Green
    Write-Host "💡 Aucune correction nécessaire." -ForegroundColor Blue
} else {
    Write-Host "⚠️  Python non accessible, application des corrections..." -ForegroundColor Yellow
    Write-Host ""
    
    # Étape 1: Supprimer les alias
    $aliasesRemoved = Remove-PythonStoreAliases
    Write-Host ""
    
    # Étape 2: Corriger le PATH
    $pathFixed = Fix-PythonPath
    Write-Host ""
    
    # Étape 3: Test final
    Write-Host "🔍 Test final..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    $finalTest = Test-PythonAccess
    
    Write-Host ""
    Write-Host "=" * 55 -ForegroundColor Gray
    
    if ($finalTest) {
        Write-Host "🎉 SUCCÈS: Python est maintenant accessible!" -ForegroundColor Green
        Write-Host "💡 Vous pouvez maintenant utiliser la commande 'chat'." -ForegroundColor Blue
        Write-Host "⚠️  IMPORTANT: Redémarrez votre terminal pour que 'chat' soit accessible." -ForegroundColor Yellow
    } else {
        Write-Host "❌ ÉCHEC: Python toujours non accessible" -ForegroundColor Red
        Write-Host ""
        Write-Host "🛠️  Solutions manuelles recommandées:" -ForegroundColor Yellow
        Write-Host "   1. Redémarrez votre terminal complètement" -ForegroundColor White
        Write-Host "   2. Réinstallez Python depuis python.org" -ForegroundColor White
        Write-Host "   3. Vérifiez que Python est bien installé dans:" -ForegroundColor White
        Write-Host "      %LOCALAPPDATA%\Programs\Python\" -ForegroundColor Gray
        Write-Host "   4. Contactez le support technique" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📋 Pour plus d'aide, consultez README_BATCH.md" -ForegroundColor Gray
