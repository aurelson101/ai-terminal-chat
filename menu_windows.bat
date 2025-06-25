@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: AI Terminal Chat - Menu Principal Windows (Simplifié)
:: Version minimaliste avec support multilingue (FR/EN)
:: Seules les options essentielles : Install, Uninstall, Fix Python, Exit

:: Détection de la langue
set "LANG=EN"

:: Vérifier si le fichier de préférence langue existe
if exist "%~dp0.lang_detected" (
    set /p LANG=< "%~dp0.lang_detected"
) else (
    cls
    echo.
    echo     ╔═══════════════════════════════════════════════════════════╗
    echo     ║                    LANGUAGE / LANGUE                      ║
    echo     ╚═══════════════════════════════════════════════════════════╝
    echo.
    echo     Please select your language / Veuillez choisir votre langue:
    echo.
    echo     [1] English
    echo     [2] Français
    echo.
    set /p lang_choice="     Choose / Choisir (1-2): "
    if "!lang_choice!"=="2" (
        set "LANG=FR"
        echo FR > "%~dp0.lang_detected"
    ) else (
        set "LANG=EN"
        echo EN > "%~dp0.lang_detected"
    )
)

title AI Terminal Chat - Menu Windows
color 0B

:MAIN_MENU
cls
echo.
if "%LANG%"=="FR" (
    echo     ╔═══════════════════════════════════════════════════════════╗
    echo     ║              🤖 AI TERMINAL CHAT - WINDOWS                ║
    echo     ║                     Menu Principal                        ║
    echo     ╚═══════════════════════════════════════════════════════════╝
    echo.
    echo     📋 OPTIONS DISPONIBLES:
    echo.
    echo     [1] 📦 Installer AI Terminal Chat
    echo     [2] 🗑️  Désinstaller AI Terminal Chat  
    echo     [3] 🔧 Corriger le problème Python
    echo     [4] 🚪 Quitter
    echo.
    echo     ═══════════════════════════════════════════════════════════
    echo.
    set /p choice="     👉 Choisissez une option (1-4): "
) else (
    echo     ╔═══════════════════════════════════════════════════════════╗
    echo     ║              🤖 AI TERMINAL CHAT - WINDOWS                ║
    echo     ║                     Main Menu                             ║
    echo     ╚═══════════════════════════════════════════════════════════╝
    echo.
    echo     📋 AVAILABLE OPTIONS:
    echo.
    echo     [1] 📦 Install AI Terminal Chat
    echo     [2] 🗑️  Uninstall AI Terminal Chat  
    echo     [3] 🔧 Fix Python Issue
    echo     [4] 🚪 Exit
    echo.
    echo     ═══════════════════════════════════════════════════════════
    echo.
    set /p choice="     👉 Choose an option (1-4): "
)

if "%choice%"=="1" goto INSTALL
if "%choice%"=="2" goto UNINSTALL
if "%choice%"=="3" goto FIX_PYTHON_STORE
if "%choice%"=="4" goto EXIT
goto INVALID_CHOICE

:INSTALL
cls
if "%LANG%"=="FR" (
    echo     🚀 Installation de AI Terminal Chat...
    echo.
    echo     � Exécution du script d'installation avec mode Bypass...
) else (
    echo      Installing AI Terminal Chat...
    echo.
    echo     � Running installation script with Bypass mode...
)
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0install_windows.ps1" -Force
pause
goto MAIN_MENU

:UNINSTALL
cls
if "%LANG%"=="FR" (
    echo     �️  Désinstallation de AI Terminal Chat...
    echo.
    echo      Exécution du script de désinstallation avec mode Bypass...
) else (
    echo     �️  Uninstalling AI Terminal Chat...
    echo.
    echo     � Running uninstallation script with Bypass mode...
)
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0uninstall_windows.ps1"
pause
goto MAIN_MENU

:FIX_PYTHON_STORE
cls
if "%LANG%"=="FR" (
    echo     � Correction du problème Python Microsoft Store...
    echo.
    echo     📋 Ce script va désactiver l'alias Python du Microsoft Store
    echo     � et configurer correctement votre environnement Python.
) else (
    echo      Fixing Python Microsoft Store issue...
    echo.
    echo     � This script will disable the Microsoft Store Python alias
    echo     📋 and properly configure your Python environment.
)
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0fix_python_store.ps1"
pause
goto MAIN_MENU

:INVALID_CHOICE
cls
if "%LANG%"=="FR" (
    echo.
    echo     ❌ Option invalide! Veuillez choisir une option valide (1-4).
) else (
    echo.
    echo     ❌ Invalid option! Please choose a valid option (1-4).
)
echo.
timeout /t 2 >nul
goto MAIN_MENU

:EXIT
cls
echo.
if "%LANG%"=="FR" (
    echo     ╔═══════════════════════════════════════════════════════════╗
    echo     ║                        � AU REVOIR                       ║
    echo     ╚═══════════════════════════════════════════════════════════╝
    echo.
    echo     🤖 Merci d'avoir utilisé AI Terminal Chat!
    echo.
    echo     � Pour utiliser AI Terminal Chat, tapez: chat
) else (
    echo     ╔═══════════════════════════════════════════════════════════╗
    echo     ║                        👋 GOODBYE                         ║
    echo     ╚═══════════════════════════════════════════════════════════╝
    echo.
    echo     🤖 Thank you for using AI Terminal Chat!
    echo.
    echo     💡 To use AI Terminal Chat, type: chat
)
echo.
timeout /t 3 >nul
exit /b 0
