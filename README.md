# AI Terminal Chat 🤖💬 - Secure Edition

Un assistant IA intelligent pour votre terminal, inspiré de Warp, avec support de nombreux LLM locaux et en ligne.

**🔒 Version 2.0 avec fonctionnalités de sécurité avancées**
**🇺🇸 English version: [README_en.md](README_en.md)**

## ✨ Fonctionnalités

- **Support LLM complet** : Ollama, LM Studio, OpenAI, OpenRouter, Anthropic, Groq
- **Sécurité renforcée** : Chiffrement des clés API, validation d'entrées, rate limiting
- **Multilingue** : Français et anglais avec détection automatique
- **Multiplateforme** : Linux et Windows 11 avec PowerShell sécurisé
- **Interface élégante** : Couleurs adaptatives et mise en forme Rich
- **Configuration simple** : Assistant de configuration interactif
- **Commande globale** : Tapez `chat` depuis n'importe où
- **Audit et logging** : Traçabilité complète des activités

## 🛡️ Fonctionnalités de Sécurité (Nouveau!)

- **🔐 Chiffrement** : Clés API chiffrées avec AES-256 + PBKDF2
- **⚡ Rate Limiting** : Protection contre l'abus d'API (par minute/heure/jour)
- **🛡️ Validation d'entrées** : Protection contre l'injection de commandes
- **📊 Audit Trail** : Logging sécurisé de toutes les activités
- **🔍 Validation d'intégrité** : Vérification des scripts et configurations
- **🔒 Mode sécurisé** : Activation des protections renforcées

![enter image description here](https://i.ibb.co/W4QMVR5S/chat-ai-menu.png)

![enter image description here](https://i.ibb.co/YBksjB8t/chat-ai-menu-2.png)

## 🚀 Installation rapide

  

### Linux

  

```bash

# Cloner le projet

git  clone  https://github.com/aurelson101/ai-terminal-chat

cd  ai-terminal-chat

  

# Installation

chmod  +x  install.sh

./install.sh

  

# Utilisation

chat

```

  

### Windows 11

**💡 Méthode recommandée : Menu batch interactif**

```batch
# Cloner le projet
git clone https://github.com/aurelson101/ai-terminal-chat
cd ai-terminal-chat

# Lancer le menu interactif (Recommandé)
menu_windows.bat
```

Le menu batch vous propose :
- 🌐 **Sélection de langue** (Français/Anglais) au premier lancement
- 📦 **Installation automatique** avec gestion des dépendances
- 🗑️ **Désinstallation propre**
- 🔧 **Correction des problèmes Python** (Microsoft Store)
- ⚡ **Exécution sécurisée** (mode Bypass automatique)

**Méthode alternative : PowerShell direct**

```powershell
# Installation standard
.\install_windows.ps1

# Installation en mode sécurisé (recommandé)
.\install_windows.ps1 -SecureMode -Verbose

# Validation de sécurité
.\validate_security_windows.ps1 -Detailed

# Utilisation
chat

# Mode sécurisé
chat --secure-mode
```

## 🪟 Guide Windows - Menu Batch Interactif

Le menu batch Windows (`menu_windows.bat`) offre une interface simplifiée et sécurisée pour gérer AI Terminal Chat sur Windows.

### 🚀 Première utilisation

1. **Clonez le projet** et naviguez dans le dossier
2. **Double-cliquez** sur `menu_windows.bat` ou lancez-le depuis PowerShell :
   ```batch
   .\menu_windows.bat
   ```

3. **Sélectionnez votre langue** au premier lancement :
   - `1` pour English
   - `2` pour Français

Votre choix sera mémorisé pour les prochaines utilisations.

### 📋 Options du menu

#### 1. 📦 Installer AI Terminal Chat
- Installation complète automatique
- Détection et installation de Python si nécessaire
- Installation de Git via winget
- Configuration des scripts et alias globaux
- Gestion automatique du PATH

#### 2. 🗑️ Désinstaller AI Terminal Chat
- Suppression propre des scripts
- Suppression des alias et configurations
- Préservation de Python et Git par défaut

#### 3. 🔧 Corriger le problème Python
- Résout le problème courant d'alias Python du Microsoft Store
- Réinitialise la configuration PATH
- Force l'utilisation du Python installé

#### 4. 🚪 Quitter
- Fermeture du menu avec message de confirmation

### ⚡ Avantages du menu batch

- **🔒 Sécurité** : Exécution automatique en mode Bypass
- **🌐 Multilingue** : Interface en français ou anglais
- **🎯 Simplicité** : Seulement 4 options essentielles
- **💾 Mémoire** : Retient vos préférences de langue
- **🛠️ Robustesse** : Gère les problèmes Windows courants

### 🔧 Résolution de problèmes Windows

Si vous rencontrez des problèmes, utilisez l'option 3 du menu qui :
- Supprime les alias Python problématiques du Microsoft Store
- Corrige les variables d'environnement PATH
- Réinstalle Python si nécessaire
- Configure correctement l'environnement

## 🔒 Utilisation Sécurisée (Nouveau!)

### Activation du mode sécurisé

```bash
# Mode sécurisé complet
chat --secure-mode

# Configuration avec chiffrement
chat --config --secure-mode

# Validation de l'installation
# Linux
python3 security_utils.py --validate

# Windows
.\validate_security_windows.ps1 -Detailed -FixIssues
```

### Fonctionnalités sécurisées

- **Chiffrement des clés API** : Saisie de mot de passe maître pour chiffrer les clés
- **Rate limiting intelligent** : Limites par minute (10), heure (100), jour (1000)
- **Validation des entrées** : Blocage automatique des commandes dangereuses
- **Audit trail** : Logs sécurisés dans `~/.ai_terminal_chat/audit.log`

## 🔐 Guide de Sécurité Détaillé

### Activation du Mode Sécurisé

Le mode sécurisé peut être activé de plusieurs façons :

```bash
# Au lancement
chat --secure-mode

# Configuration sécurisée
chat --config --secure-mode

# Installation sécurisée (Windows)
.\install_windows.ps1 -SecureMode -Verbose
```

### Fonctionnalités de Sécurité

#### 🔒 Chiffrement des Données Sensibles

- **Algorithme** : AES-256 + PBKDF2 (100 000 itérations)
- **Clés protégées** : Clés API, mots de passe, tokens
- **Stockage** : Configuration chiffrée dans `secure_config.json`
- **Mot de passe maître** : Requis pour déchiffrer les données

```bash
# Première utilisation en mode sécurisé
chat --secure-mode
# → Demande de création d'un mot de passe maître
# → Chiffrement automatique des clés API
```

#### ⚡ Rate Limiting

Protection contre l'abus d'API avec limites configurables :

- **Par minute** : 10 requêtes max
- **Par heure** : 100 requêtes max  
- **Par jour** : 1000 requêtes max
- **Stockage** : `rate_limits.json` avec horodatage

#### 🛡️ Validation des Entrées

Protection contre l'injection de commandes :

- Détection de caractères dangereux : `;`, `&`, `|`, `` ` ``
- Blocage des tentatives d'exécution : `cmd.exe`, `powershell.exe`
- Prévention de traversée de chemins : `../`, `<`, `>`
- Validation des noms de fichiers

#### 📊 Audit Trail

Logging sécurisé complet :

- **Fichier** : `~/.ai_terminal_chat/audit.log`
- **Format** : JSON structuré avec horodatage
- **Événements** : Requêtes API, erreurs, événements de sécurité
- **Rotation** : Automatic avec taille limitée

### Validation de Sécurité

#### Linux/macOS

```bash
# Validation rapide
python3 security_utils.py --validate

# Validation complète avec rapport
python3 security_utils.py --validate --detailed

# Test d'intégrité des configurations
python3 security_utils.py --check-integrity
```

#### Windows

```powershell
# Validation complète
.\validate_security_windows.ps1 -Detailed

# Correction automatique des problèmes
.\validate_security_windows.ps1 -Detailed -FixIssues

# Rapport de sécurité
.\validate_security_windows.ps1 -SecurityReport
```

### Bonnes Pratiques de Sécurité

#### Protection des Clés API

1. **Utilisez toujours le mode sécurisé** pour les environnements de production
2. **Créez un mot de passe fort** pour le chiffrement (12+ caractères)
3. **Sauvegardez vos configurations chiffrées** régulièrement
4. **Limitez les permissions** des fichiers de configuration

#### Surveillance

1. **Vérifiez les logs d'audit** régulièrement
2. **Surveillez les tentatives de rate limiting**
3. **Validez l'intégrité** des scripts périodiquement
4. **Mettez à jour** les dépendances de sécurité

#### Environnements d'Entreprise

```bash
# Configuration pour entreprise
export AI_CHAT_SECURE_MODE=1
export AI_CHAT_AUDIT_LEVEL=high
export AI_CHAT_RATE_LIMIT_STRICT=1

# Démarrage sécurisé
chat --secure-mode --audit-high
```

### Dépannage Sécurité

#### Problèmes Courants

1. **Cryptography non installé**
   ```bash
   pip install cryptography>=41.0.0
   ```

2. **Permissions incorrectes**
   ```bash
   # Linux/macOS
   chmod 600 ~/.ai_terminal_chat/secure_config.json
   
   # Windows
   icacls "%LOCALAPPDATA%\ai_terminal_chat" /inheritance:r /grant:r "%USERNAME%:F"
   ```

3. **Rate limit dépassé**
   ```bash
   # Réinitialiser les compteurs
   rm ~/.ai_terminal_chat/rate_limits.json
   ```

4. **Configuration corrompue**
   ```bash
   # Restaurer depuis une sauvegarde
   cp ~/.ai_terminal_chat/secure_config_backup_*.json ~/.ai_terminal_chat/secure_config.json
   ```

## 📁 Structure du Projet

```text
├── ai_chat.py                   # Script principal (détection automatique de langue)
├── ai_chat_fr.py                # Interface française
├── ai_chat_en.py                # Interface anglaise
├── ai_chat_windows.py           # Script principal Windows
├── security_utils.py            # Module utilitaires de sécurité
├── config_migration.py          # Utilitaire de migration de configuration
├── windows_helper.py            # Module d'aide Windows
├── install.sh                   # Installation Linux
├── install_windows.ps1          # Installation Windows (sécurisée)
├── uninstall.sh                 # Désinstallation Linux
├── uninstall_windows.ps1        # Désinstallation Windows
├── validate_security.sh         # Validation sécurité Linux
├── validate_security_windows.ps1 # Validation sécurité Windows
├── requirements.txt             # Dépendances Python
├── README.md                    # Ce fichier
└── README_en.md                 # Version anglaise
```

## 🛠️ Dépannage

### Commande `chat` non trouvée

```bash
# Linux
source ~/.bashrc
# ou
source ~/.zshrc

# Vérifier l'installation
which chat
```

### Erreur de configuration

```bash
# Vérifier la configuration
python3 config_migration.py --check

# Corriger automatiquement
python3 config_migration.py --migrate
```

### Problèmes de permissions

```bash
# Linux/macOS
chmod 755 ~/.local/bin/chat
chmod 600 ~/.ai_terminal_chat/config.json

# Réinstaller si nécessaire
./install.sh
```