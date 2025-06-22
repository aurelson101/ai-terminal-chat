#!/usr/bin/env python3
"""
Windows Helper Module for AI Terminal Chat
Provides Windows-specific functionality and path handling
"""

import os
import platform
from pathlib import Path

def is_windows():
    """Check if running on Windows"""
    return platform.system() == "Windows"

def get_config_directory():
    """Get the appropriate configuration directory for the platform"""
    if is_windows():
        # Use LOCALAPPDATA on Windows
        local_appdata = os.environ.get('LOCALAPPDATA')
        if local_appdata:
            return Path(local_appdata) / "ai_terminal_chat"
        else:
            # Fallback to USERPROFILE
            return Path(os.environ['USERPROFILE']) / "ai_terminal_chat"
    else:
        # Unix/Linux
        return Path.home() / ".ai_terminal_chat"

def get_system_info():
    """Get system information for debugging"""
    info = {
        "platform": platform.system(),
        "version": platform.version(),
        "machine": platform.machine(),
        "python_version": platform.python_version()
    }
    
    if is_windows():
        info["windows_version"] = platform.win32_ver()
        info["localappdata"] = os.environ.get('LOCALAPPDATA', 'Not set')
        info["userprofile"] = os.environ.get('USERPROFILE', 'Not set')
    
    return info

def get_clipboard_command():
    """Get the appropriate clipboard command for the platform"""
    if is_windows():
        return "clip"  # Windows built-in clipboard
    else:
        # Linux - will use pyperclip as fallback
        return None

def get_terminal_info():
    """Get information about the terminal environment"""
    info = {}
    
    if is_windows():
        # Check for Windows Terminal
        if os.environ.get('WT_SESSION'):
            info["terminal"] = "Windows Terminal"
        elif os.environ.get('ConEmuPID'):
            info["terminal"] = "ConEmu"
        elif "POWERSHELL" in os.environ.get('PROMPT', '').upper():
            info["terminal"] = "PowerShell"
        else:
            info["terminal"] = "Command Prompt"
        
        info["powershell_version"] = os.environ.get('PSVersionTable', 'Unknown')
    else:
        info["terminal"] = os.environ.get('TERM', 'Unknown')
        info["shell"] = os.environ.get('SHELL', 'Unknown')
    
    return info

def show_windows_specific_help():
    """Show Windows-specific help and tips"""
    if not is_windows():
        return
    
    print("\n🖥️  Conseils spécifiques Windows:")
    print("━" * 40)
    print("💡 Terminal recommandé: Windows Terminal")
    print("💡 PowerShell: Version 7+ recommandée")
    print("💡 Raccourci: Win+X puis I pour PowerShell Admin")
    print("💡 Configuration: %LOCALAPPDATA%\\ai_terminal_chat")
    
    terminal_info = get_terminal_info()
    print(f"📊 Terminal actuel: {terminal_info.get('terminal', 'Inconnu')}")

def check_windows_dependencies():
    """Check Windows-specific dependencies and configurations"""
    if not is_windows():
        return True
    
    issues = []
    
    # Check Python installation
    try:
        import sys
        if sys.version_info < (3, 7):
            issues.append("Python 3.7+ recommandé")
    except:
        issues.append("Impossible de vérifier la version Python")
    
    # Check if LOCALAPPDATA is available
    if not os.environ.get('LOCALAPPDATA'):
        issues.append("Variable LOCALAPPDATA non définie")
    
    # Check execution policy (if in PowerShell)
    if os.environ.get('PSExecutionPolicyPreference'):
        try:
            import subprocess
            result = subprocess.run(['powershell', '-Command', 'Get-ExecutionPolicy'], 
                                  capture_output=True, text=True)
            if result.returncode == 0 and 'Restricted' in result.stdout:
                issues.append("Politique d'exécution PowerShell restrictive")
        except:
            pass
    
    return len(issues) == 0, issues
