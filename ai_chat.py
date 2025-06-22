#!/usr/bin/env python3
"""
Terminal AI Chat - Multilingual AI terminal chat application
Automatically detects system language and loads appropriate version
"""

import sys
import os
import locale
import subprocess
import argparse
import json
from pathlib import Path

def get_config_dir():
    """Get the configuration directory"""
    return Path.home() / ".ai_terminal_chat"

def save_language_preference(lang):
    """Save the language preference to config file"""
    config_dir = get_config_dir()
    config_dir.mkdir(exist_ok=True)
    
    config_file = config_dir / "language_config.json"
    config = {"preferred_language": lang}
    
    with open(config_file, 'w') as f:
        json.dump(config, f)

def load_language_preference():
    """Load the saved language preference"""
    config_file = get_config_dir() / "language_config.json"
    
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                return config.get("preferred_language")
        except Exception:
            pass
    
    return None

def get_system_language():
    """Detect system language"""
    try:
        # Try to get locale from environment variables
        lang = os.environ.get('LANG', '')
        if lang.startswith('fr'):
            return 'fr'
        elif lang.startswith('en'):
            return 'en'
        
        # Try locale module
        try:
            default_locale = locale.getdefaultlocale()[0]
            if default_locale and default_locale.startswith('fr'):
                return 'fr'
            elif default_locale and default_locale.startswith('en'):
                return 'en'
        except Exception:
            pass
        
        # Default to English if detection fails
        return 'en'
    except Exception:
        return 'en'

def main():
    parser = argparse.ArgumentParser(description="AI Terminal Chat - Multilingual")
    parser.add_argument("--lang", choices=['fr', 'en'], help="Force language (fr/en)")
    parser.add_argument("--config", action="store_true", help="Reconfigure LLM")
    parser.add_argument("--select-lang", action="store_true", help="Show language selection")
    parser.add_argument("--reset-lang", action="store_true", help="Reset language preference")
    args, unknown_args = parser.parse_known_args()
    
    script_dir = Path(__file__).parent
    
    # Reset language preference
    if args.reset_lang:
        config_file = get_config_dir() / "language_config.json"
        if config_file.exists():
            config_file.unlink()
            print("✅ Language preference reset. Will auto-detect on next run.")
        else:
            print("ℹ️  No language preference was set.")
        return
    
    # Language selection mode
    if args.select_lang:
        print("🌐 AI Terminal Chat - Language Selection")
        print("=" * 48)
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
            print("📖 Documentation: README_en.md")
        elif choice == "2":
            lang = "fr"
            save_language_preference(lang)
            print("\n🇫🇷 Démarrage de la version française...")
            print("📖 Documentation: README_fr.md")
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
        subprocess.run(cmd)
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"❌ Error launching script: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
