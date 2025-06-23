#!/usr/bin/env python3
"""
Security utilities for AI Terminal Chat
Provides encryption, validation, and rate limiting functionality
"""

import os
import json
import base64
import re
from pathlib import Path
from typing import Dict, Any, Tuple, Optional
from datetime import datetime, timedelta
import logging
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

class SecurityManager:
    """Manages security features for AI Terminal Chat"""
    
    def __init__(self, config_dir: Path):
        self.config_dir = config_dir
        self.security_config_file = config_dir / "security_config.json"
        self.rate_limit_file = config_dir / "rate_limits.json"
        self.audit_log_file = config_dir / "audit.log"
        
        # Setup secure logging
        self.setup_secure_logging()
        
        # Initialize rate limiting
        self.rate_limits = self.load_rate_limits()
        
    def setup_secure_logging(self):
        """Setup secure audit logging"""
        logging.basicConfig(
            filename=str(self.audit_log_file),
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        self.logger = logging.getLogger('ai_chat_security')
        
    def generate_key_from_password(self, password: str, salt: Optional[bytes] = None) -> Tuple[bytes, bytes]:
        """Generate encryption key from password"""
        if salt is None:
            salt = os.urandom(16)
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        return key, salt
    
    def encrypt_sensitive_data(self, data: str, password: str) -> Dict[str, str]:
        """Encrypt sensitive data like API keys"""
        try:
            key, salt = self.generate_key_from_password(password)
            fernet = Fernet(key)
            encrypted_data = fernet.encrypt(data.encode())
            
            return {
                "encrypted_data": base64.urlsafe_b64encode(encrypted_data).decode(),
                "salt": base64.urlsafe_b64encode(salt).decode(),
                "encryption_method": "fernet_pbkdf2"
            }
        except Exception as e:
            self.logger.error(f"Encryption failed: {e}")
            raise
    
    def decrypt_sensitive_data(self, encrypted_data: Dict[str, str], password: str) -> str:
        """Decrypt sensitive data"""
        try:
            salt = base64.urlsafe_b64decode(encrypted_data["salt"])
            key, _ = self.generate_key_from_password(password, salt)
            fernet = Fernet(key)
            
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_data["encrypted_data"])
            decrypted_data = fernet.decrypt(encrypted_bytes)
            
            return decrypted_data.decode()
        except Exception as e:
            self.logger.error(f"Decryption failed: {e}")
            raise
    
    def validate_api_key_format(self, api_key: str, provider: str) -> bool:
        """Validate API key format for different providers"""
        patterns = {
            "openai": r"^sk-[a-zA-Z0-9]{48,}$",
            "anthropic": r"^sk-ant-[a-zA-Z0-9\-]{95,}$",
            "groq": r"^gsk_[a-zA-Z0-9]{52}$",
            "openrouter": r"^sk-or-v1-[a-zA-Z0-9]{64}$"
        }
        
        pattern = patterns.get(provider.lower())
        if not pattern:
            # For unknown providers, just check basic format
            return len(api_key) > 10 and api_key.replace("-", "").replace("_", "").isalnum()
        
        return bool(re.match(pattern, api_key))
    
    def mask_api_key(self, api_key: str) -> str:
        """Mask API key for display"""
        if len(api_key) <= 8:
            return "*" * len(api_key)
        return api_key[:4] + "*" * (len(api_key) - 8) + api_key[-4:]
    
    def validate_input_safety(self, user_input: str) -> bool:
        """Validate user input for potential security issues"""
        # Check for command injection patterns
        dangerous_patterns = [
            r'[;&|`]',  # Command separators
            r'\$\(',    # Command substitution
            r'`[^`]*`', # Backtick execution
            r'eval\s*\(',
            r'exec\s*\(',
            r'subprocess',
            r'os\.system',
            r'shell=True'
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, user_input, re.IGNORECASE):
                self.logger.warning(f"Dangerous pattern detected in input: {pattern}")
                return False
        
        return True
    
    def sanitize_filename(self, filename: str) -> str:
        """Sanitize filename to prevent path traversal"""
        # Remove path separators and dangerous characters
        sanitized = re.sub(r'[<>:"/\\|?*]', '_', filename)
        # Remove leading/trailing dots and spaces
        sanitized = sanitized.strip('. ')
        # Limit length
        sanitized = sanitized[:255]
        return sanitized
    
    def load_rate_limits(self) -> Dict[str, Any]:
        """Load rate limiting data"""
        if self.rate_limit_file.exists():
            try:
                with open(self.rate_limit_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, FileNotFoundError):
                pass
        
        return {
            "requests": [],
            "daily_limit": 1000,
            "hourly_limit": 100,
            "minute_limit": 10
        }
    
    def save_rate_limits(self):
        """Save rate limiting data"""
        try:
            with open(self.rate_limit_file, 'w') as f:
                json.dump(self.rate_limits, f, indent=2)
        except Exception as e:
            self.logger.error(f"Failed to save rate limits: {e}")
    
    def check_rate_limit(self, limit_type: str = "request") -> bool:
        """Check if rate limit is exceeded"""
        now = datetime.now()
        
        # Clean old requests
        self.rate_limits["requests"] = [
            req_time for req_time in self.rate_limits["requests"]
            if datetime.fromisoformat(req_time) > now - timedelta(days=1)
        ]
        
        # Count requests in different time windows
        hour_ago = now - timedelta(hours=1)
        minute_ago = now - timedelta(minutes=1)
        
        recent_requests = [
            datetime.fromisoformat(req_time) 
            for req_time in self.rate_limits["requests"]
        ]
        
        hourly_count = sum(1 for req_time in recent_requests if req_time > hour_ago)
        minute_count = sum(1 for req_time in recent_requests if req_time > minute_ago)
        daily_count = len(recent_requests)
        
        # Check limits
        if daily_count >= self.rate_limits["daily_limit"]:
            self.logger.warning("Daily rate limit exceeded")
            return False
        
        if hourly_count >= self.rate_limits["hourly_limit"]:
            self.logger.warning("Hourly rate limit exceeded")
            return False
        
        if minute_count >= self.rate_limits["minute_limit"]:
            self.logger.warning("Minute rate limit exceeded")
            return False
        
        # Record this request
        self.rate_limits["requests"].append(now.isoformat())
        self.save_rate_limits()
        
        return True
    
    def log_security_event(self, event_type: str, details: Dict[str, Any]):
        """Log security-related events"""
        event = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "details": details
        }
        
        self.logger.info(f"Security event: {json.dumps(event)}")
    
    def verify_config_integrity(self, config_data: Dict[str, Any]) -> bool:
        """Verify configuration file integrity"""
        required_fields = ["llm_type", "model"]
        
        for field in required_fields:
            if field not in config_data:
                self.logger.error(f"Missing required field in config: {field}")
                return False
        
        # Validate LLM type
        valid_llm_types = ["ollama", "lmstudio", "openai", "anthropic", "groq", "openrouter"]
        if config_data["llm_type"] not in valid_llm_types:
            self.logger.error(f"Invalid LLM type: {config_data['llm_type']}")
            return False
        
        return True
    
    def create_secure_backup(self, file_path: Path) -> Optional[Path]:
        """Create a secure backup of a file"""
        if not file_path.exists():
            return None
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = file_path.parent / f"{file_path.stem}_backup_{timestamp}{file_path.suffix}"
        
        try:
            import shutil
            shutil.copy2(file_path, backup_path)
            self.logger.info(f"Secure backup created: {backup_path}")
            return backup_path
        except Exception as e:
            self.logger.error(f"Failed to create backup: {e}")
            return None

class SecureConfigManager:
    """Manages encrypted configuration storage"""
    
    def __init__(self, config_dir: Path, security_manager: SecurityManager):
        self.config_dir = config_dir
        self.security_manager = security_manager
        self.secure_config_file = config_dir / "secure_config.json"
        
    def save_secure_config(self, config: Dict[str, Any], master_password: str):
        """Save configuration with encrypted sensitive data"""
        secure_config = config.copy()
        
        # Encrypt sensitive fields
        sensitive_fields = ["api_key", "password", "token"]
        
        for field in sensitive_fields:
            if field in secure_config and secure_config[field]:
                try:
                    encrypted_data = self.security_manager.encrypt_sensitive_data(
                        secure_config[field], master_password
                    )
                    secure_config[f"{field}_encrypted"] = encrypted_data
                    del secure_config[field]  # Remove plaintext
                except Exception as e:
                    self.security_manager.logger.error(f"Failed to encrypt {field}: {e}")
        
        # Save with timestamp
        secure_config["encrypted_timestamp"] = datetime.now().isoformat()
        
        try:
            with open(self.secure_config_file, 'w') as f:
                json.dump(secure_config, f, indent=2)
            
            self.security_manager.log_security_event("config_encrypted", {
                "fields_encrypted": len([f for f in sensitive_fields if f"{f}_encrypted" in secure_config])
            })
        except Exception as e:
            self.security_manager.logger.error(f"Failed to save secure config: {e}")
            raise
    
    def load_secure_config(self, master_password: str) -> Dict[str, Any]:
        """Load and decrypt configuration"""
        if not self.secure_config_file.exists():
            return {}
        
        try:
            with open(self.secure_config_file, 'r') as f:
                secure_config = json.load(f)
            
            # Decrypt sensitive fields
            sensitive_fields = ["api_key", "password", "token"]
            
            for field in sensitive_fields:
                encrypted_field = f"{field}_encrypted"
                if encrypted_field in secure_config:
                    try:
                        decrypted_data = self.security_manager.decrypt_sensitive_data(
                            secure_config[encrypted_field], master_password
                        )
                        secure_config[field] = decrypted_data
                        del secure_config[encrypted_field]  # Remove encrypted version
                    except Exception as e:
                        self.security_manager.logger.error(f"Failed to decrypt {field}: {e}")
                        # Keep encrypted field for debugging
            
            return secure_config
            
        except Exception as e:
            self.security_manager.logger.error(f"Failed to load secure config: {e}")
            return {}

if __name__ == "__main__":
    import argparse
    import sys
    
    def validate_security_installation():
        """Validate security installation and configuration"""
        print("🔒 AI Terminal Chat - Security Validation")
        print("=" * 50)
        print()
        
        config_dir = Path.home() / ".ai_terminal_chat"
        security_manager = SecurityManager(config_dir)
        
        issues = []
        warnings = []
        
        # Check if config directory exists
        if not config_dir.exists():
            issues.append("Configuration directory does not exist")
        else:
            print("✅ Configuration directory exists")
        
        # Check file permissions
        if config_dir.exists():
            stat_info = config_dir.stat()
            if stat_info.st_mode & 0o077:
                warnings.append(f"Configuration directory permissions too open: {oct(stat_info.st_mode)}")
            else:
                print("✅ Configuration directory permissions are secure")
        
        # Check dependencies
        try:
            import importlib.util
            spec = importlib.util.find_spec("cryptography.fernet")
            if spec is not None:
                print("✅ Cryptography library is available")
            else:
                issues.append("Cryptography library not installed")
        except ImportError:
            issues.append("Cryptography library not installed")
        
        # Check audit log
        if security_manager.audit_log_file.exists():
            print("✅ Audit log file exists")
        else:
            warnings.append("Audit log file does not exist (will be created on first use)")
        
        # Check rate limits file
        if security_manager.rate_limit_file.exists():
            print("✅ Rate limits file exists")
        else:
            warnings.append("Rate limits file does not exist (will be created on first use)")
        
        # Summary
        print()
        print("📊 Security Validation Summary")
        print("-" * 35)
        
        if issues:
            print("❌ Critical Issues:")
            for issue in issues:
                print(f"   • {issue}")
        
        if warnings:
            print("⚠️  Warnings:")
            for warning in warnings:
                print(f"   • {warning}")
        
        if not issues and not warnings:
            print("✅ All security checks passed!")
        elif not issues:
            print("✅ No critical issues found!")
        
        print()
        print("💡 For detailed configuration, run: chat --config --secure-mode")
        
        return len(issues) == 0
    
    parser = argparse.ArgumentParser(description="AI Terminal Chat Security Utilities")
    parser.add_argument("--validate", action="store_true", help="Validate security installation")
    parser.add_argument("--check-integrity", action="store_true", help="Check configuration integrity")
    
    args = parser.parse_args()
    
    if args.validate:
        success = validate_security_installation()
        sys.exit(0 if success else 1)
    elif args.check_integrity:
        print("🔍 Configuration integrity check coming soon...")
        sys.exit(0)
    else:
        parser.print_help()
        sys.exit(0)
