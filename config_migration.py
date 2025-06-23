#!/usr/bin/env python3
"""
Configuration Migration Utility for AI Terminal Chat
Automatically fixes configuration issues between versions
"""

import json
from pathlib import Path
from datetime import datetime

def migrate_config():
    """Migrate configuration from old format to new format"""
    config_dir = Path.home() / ".ai_terminal_chat"
    config_file = config_dir / "config.json"
    
    if not config_file.exists():
        print("❌ No configuration file found")
        return False
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        changes_made = False
        
        # Fix base_url -> api_url migration
        if 'base_url' in config:
            config['api_url'] = config['base_url']
            del config['base_url']
            changes_made = True
            print("✅ Migrated base_url → api_url")
        
        # Add default values if missing
        if 'llm_type' not in config:
            config['llm_type'] = 'openrouter'
            changes_made = True
            print("✅ Added default llm_type")
        
        if changes_made:
            # Backup original config
            backup_file = config_dir / f"config_backup_{int(datetime.now().timestamp())}.json"
            with open(backup_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            # Save updated config
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            print("✅ Configuration migrated successfully")
            print(f"📁 Backup saved as: {backup_file.name}")
            return True
        else:
            print("✅ Configuration is already up to date")
            return True
            
    except Exception as e:
        print(f"❌ Error migrating configuration: {e}")
        return False

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="AI Terminal Chat Configuration Migration Utility")
    parser.add_argument("--migrate", action="store_true", help="Migrate configuration to latest format")
    parser.add_argument("--check", action="store_true", help="Check configuration for issues")
    
    args = parser.parse_args()
    
    if args.migrate:
        print("🔧 AI Terminal Chat - Configuration Migration")
        print("=" * 50)
        success = migrate_config()
        exit(0 if success else 1)
    elif args.check:
        print("🔍 AI Terminal Chat - Configuration Check")
        print("=" * 50)
        # Implementation for configuration check
        config_dir = Path.home() / ".ai_terminal_chat"
        config_file = config_dir / "config.json"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                
                print("✅ Configuration file exists and is valid JSON")
                
                # Check for common issues
                issues = []
                if 'base_url' in config:
                    issues.append("Uses deprecated 'base_url' (should be 'api_url')")
                if 'api_url' not in config and 'base_url' not in config:
                    issues.append("Missing API URL configuration")
                if 'api_key' not in config:
                    issues.append("Missing API key")
                
                if issues:
                    print("⚠️  Issues found:")
                    for issue in issues:
                        print(f"   • {issue}")
                    print("\n💡 Run with --migrate to fix these issues")
                else:
                    print("✅ No issues found")
                    
            except json.JSONDecodeError:
                print("❌ Configuration file contains invalid JSON")
            except Exception as e:
                print(f"❌ Error reading configuration: {e}")
        else:
            print("❌ No configuration file found")
    else:
        parser.print_help()
