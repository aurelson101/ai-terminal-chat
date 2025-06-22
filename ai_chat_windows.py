#!/usr/bin/env python3
"""
Terminal AI Chat - Windows 11 Edition
Multilingual AI terminal chat application for Windows with PowerShell support
"""

import sys
import os
import locale
import subprocess
import argparse
import json
import platform
from pathlib import Path

# Import Windows helper if available
try:
    from windows_helper import get_config_directory as windows_get_config_directory
    WINDOWS_HELPER_AVAILABLE = True
except ImportError:
    WINDOWS_HELPER_AVAILABLE = False

def get_config_dir():
    """Get the configuration directory for Windows"""
    if WINDOWS_HELPER_AVAILABLE:
        return windows_get_config_directory()
    else:
        # Fallback implementation
        if platform.system() == "Windows":
            # Use LOCALAPPDATA for Windows
            return Path(os.environ.get('LOCALAPPDATA', os.environ['USERPROFILE'])) / "ai_terminal_chat"
        else:
            return Path.home() / ".ai_terminal_chat"

def get_system_language():
    """Detect system language on Windows"""
    try:
        if platform.system() == "Windows":
            # Try Windows locale detection
            try:
                # Get Windows locale
                default_locale = locale.getdefaultlocale()[0]
                if default_locale:
                    if default_locale.startswith('fr'):
                        return 'fr'
                    elif default_locale.startswith('en'):
                        return 'en'
                
                # Try alternative Windows method with PowerShell
                try:
                    result = subprocess.run(['powershell', '-Command', 
                                           'Get-Culture | Select-Object -ExpandProperty Name'], 
                                          capture_output=True, text=True, timeout=5)
                    if result.returncode == 0 and result.stdout.strip():
                        culture = result.stdout.strip()
                        if culture.startswith('fr'):
                            return 'fr'
                        elif culture.startswith('en'):
                            return 'en'
                except (subprocess.TimeoutExpired, subprocess.SubprocessError, OSError):
                    pass
            except (locale.Error, ValueError):
                pass
        else:
            # Linux/Unix detection
            try:
                lang = os.environ.get('LANG', '')
                if lang.startswith('fr'):
                    return 'fr'
                elif lang.startswith('en'):
                    return 'en'
            except Exception:
                pass
        
        # Default to English
        return 'en'
    except Exception:
        return 'en'

def save_language_preference(lang):
    """Save the language preference to config file"""
    try:
        config_dir = get_config_dir()
        config_dir.mkdir(exist_ok=True)
        
        config_file = config_dir / "language_config.json"
        config = {"preferred_language": lang}
        
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
    except (OSError, PermissionError, json.JSONEncodeError) as e:
        print(f"⚠️  Warning: Could not save language preference: {e}")

def load_language_preference():
    """Load the saved language preference"""
    try:
        config_file = get_config_dir() / "language_config.json"
        
        if config_file.exists():
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                return config.get("preferred_language")
    except (OSError, PermissionError, json.JSONDecodeError):
        pass
    
    return None

def main():
    parser = argparse.ArgumentParser(description="AI Terminal Chat - Windows Edition")
    parser.add_argument("--lang", choices=['fr', 'en'], help="Force language (fr/en)")
    parser.add_argument("--config", action="store_true", help="Reconfigure LLM")
    parser.add_argument("--select-lang", action="store_true", help="Show language selection")
    parser.add_argument("--reset-lang", action="store_true", help="Reset language preference")
    parser.add_argument("--diagnostic", action="store_true", help="Show diagnostic information")
    args, unknown_args = parser.parse_known_args()
    
    script_dir = Path(__file__).parent
    
    # Show diagnostic information
    if args.diagnostic:
        print("🔬 AI Terminal Chat - Windows Diagnostic")
        print("=" * 45)
        print()
        print(f"📋 Platform: {platform.system()} {platform.version()}")
        print(f"📋 Python: {platform.python_version()}")
        print(f"📋 Script location: {script_dir}")
        print(f"📋 Config directory: {get_config_dir()}")
        print(f"📋 Windows helper available: {WINDOWS_HELPER_AVAILABLE}")
        
        # Test language detection
        detected_lang = get_system_language()
        saved_lang = load_language_preference()
        print(f"📋 Detected language: {detected_lang}")
        print(f"📋 Saved preference: {saved_lang}")
        
        # Check script files
        print("\n📁 Available script files:")
        for script_file in ["ai_chat_fr.py", "ai_chat_en.py"]:
            script_path = script_dir / script_file
            if script_path.exists():
                print(f"   ✅ {script_file}")
            else:
                print(f"   ❌ {script_file} (missing)")
        
        print("\n💡 For complete diagnostic, run: validate_windows.ps1")
        return 0
    
    # Reset language preference
    if args.reset_lang:
        try:
            config_file = get_config_dir() / "language_config.json"
            if config_file.exists():
                config_file.unlink()
                print("✅ Language preference reset. Will auto-detect on next run.")
            else:
                print("ℹ️  No language preference was set.")
        except (OSError, PermissionError) as e:
            print(f"❌ Error resetting language preference: {e}")
        return
    
    # Language selection mode
    if args.select_lang:
        print("🌐 AI Terminal Chat - Language Selection (Windows Edition)")
        print("=" * 58)
        print()
        print("Choose your language / Choisissez votre langue :")
        print()
        print("1) 🇺🇸 English")
        print("2) 🇫🇷 Français")
        print()
        
        choice = input("Enter your choice (1 or 2) / Entrez votre choix (1 ou 2): ")
        
        if choice == "1":
            lang = "en"
            save_language_preference(lang)
            print("\n🇺🇸 Starting English version...")
            print("📖 Documentation: README_windows_en.md")
        elif choice == "2":
            lang = "fr"
            save_language_preference(lang)
            print("\n🇫🇷 Démarrage de la version française...")
            print("📖 Documentation: README_windows_fr.md")
        else:
            lang = "fr"  # Default to French
            save_language_preference(lang)
            print("\n🇫🇷 Démarrage par défaut en français...")
    else:
        # Determine language priority: --lang > saved preference > auto-detect
        if args.lang:
            lang = args.lang
            # Save the forced language as preference for next time
            save_language_preference(lang)
        else:
            # Try to load saved preference first
            saved_lang = load_language_preference()
            if saved_lang:
                lang = saved_lang
            else:
                # Fall back to auto-detection
                lang = get_system_language()
    
    # Choose the appropriate script
    if lang == 'fr':
        script_path = script_dir / "ai_chat_fr.py"
        if not script_path.exists():
            print("❌ French version not found, falling back to English")
            script_path = script_dir / "ai_chat_en.py"
    else:
        script_path = script_dir / "ai_chat_en.py"
        if not script_path.exists():
            print("❌ English version not found, falling back to French")
            script_path = script_dir / "ai_chat_fr.py"
    
    if not script_path.exists():
        print("❌ No language version found!")
        print("📁 Available files:")
        for f in script_dir.glob("ai_chat_*.py"):
            print(f"   {f.name}")
        sys.exit(1)
    
    # Prepare command arguments
    cmd = [sys.executable, str(script_path)]
    if args.config:
        cmd.append("--config")
    cmd.extend(unknown_args)
    
    # Execute the appropriate version
    try:
        result = subprocess.run(cmd)
        return result.returncode
    except KeyboardInterrupt:
        print("\n💡 Session interrompue par l'utilisateur")
        return 0
    except FileNotFoundError:
        print(f"❌ Python executable not found: {sys.executable}")
        print("💡 Make sure Python is properly installed and in PATH")
        return 1
    except Exception as e:
        print(f"❌ Error launching script: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
