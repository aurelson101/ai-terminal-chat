
# AI Terminal Chat 🤖💬

  

Un assistant IA intelligent pour votre terminal, inspiré de Warp, avec support de nombreux LLM locaux et en ligne.

  

**🇺🇸 English version: [README_en.md](README_en.md)**

  

## ✨ Fonctionnalités

  

-  **Support LLM complet** : Ollama, LM Studio, OpenAI, OpenRouter, Anthropic, Groq

-  **Multilingue** : Français et anglais avec détection automatique

-  **Multiplateforme** : Linux et Windows 11 avec PowerShell

-  **Interface élégante** : Couleurs adaptatives et mise en forme Rich

-  **Configuration simple** : Assistant de configuration interactif

-  **Commande globale** : Tapez `chat` depuis n'importe où

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

  

```powershell

# Cloner le projet

git clone https://github.com/aurelson101/ai-terminal-chat

cd ai-terminal-chat

  

# Installation

.\install_windows.ps1

  

# Utilisation

chat

```

  

## 💬 Utilisation

  

### Commandes de base

  

```bash

chat  # Lancer le chat

chat  --lang  fr  # Forcer le français

chat  --lang  en  # Forcer l'anglais

chat  --select-lang  # Sélecteur de langue

chat  --config  # Reconfigurer le LLM

chat  --reset-lang  # Réinitialiser la langue

chat  --help  # Aide

```

  

### Dans le chat

  

-  `copy` : Copier la dernière réponse

-  `config` : Reconfigurer le LLM

-  `quit`, `exit`, `q` : Quitter

-  `Ctrl+C` : Quitter

  

## 🔧 Configuration LLM

  

### LLM Locaux (Gratuits)

  

#### Ollama

  

```bash

# Installation

curl  -fsSL  https://ollama.ai/install.sh | sh

  

# Télécharger un modèle

ollama  pull  llama2

ollama  pull  codellama

ollama  pull  mistral

```

  

#### LM Studio

  

1. Télécharger depuis [lmstudio.ai](https://lmstudio.ai)

2. Charger un modèle

3. Démarrer le serveur local (port 1234)

  

### APIs Externes

  

#### OpenRouter (Modèles gratuits recommandés)

  

-  `microsoft/phi-4-reasoning-plus:free` - Excellent pour le code

-  `google/gemma-2-9b-it:free` - Bon modèle général

-  `meta-llama/llama-3.1-8b-instruct:free` - Polyvalent

  

#### Autres APIs

  

-  **OpenAI** : Modèles GPT (payant)

-  **Anthropic** : Claude (payant)

-  **Groq** : Modèles rapides (freemium)

  

## 🌐 Gestion des langues

  

Le système utilise une priorité intelligente :

  

1.  **Langue forcée** (`--lang fr/en`) - Priorité maximale

2.  **Langue mémorisée** - Dernière langue choisie

3.  **Auto-détection** - Langue du système

  

### Exemples

  

```bash

# Premier usage - détection automatique

chat  # → Français si système français

  

# Forcer l'anglais - sera mémorisé

chat  --lang  en

  

# Prochains usages - utilise la préférence

chat  # → Anglais (mémorisé)

  

# Revenir à l'auto-détection

chat  --reset-lang

```

  

## 📁 Structure

  

```text

├── ai_chat.py # Script principal Linux

├── ai_chat_windows.py # Script principal Windows

├── ai_chat_fr.py # Interface française

├── ai_chat_en.py # Interface anglaise

├── windows_helper.py # Module d'aide Windows

├── install.sh # Installation Linux

├── install_windows.ps1 # Installation Windows

├── uninstall.sh # Désinstallation Linux

├── uninstall_windows.ps1 # Désinstallation Windows

├── requirements.txt # Dépendances Python

├── README.md # Ce fichier

└── README_en.md # Version anglaise

```

  

## 🛠️ Dépannage

  

### Commande `chat` non trouvée

  

```bash

# Linux

source  ~/.bashrc

# ou redémarrer le terminal

  

# Windows

# Redémarrer PowerShell/Terminal

```

  

### Erreurs Python

  

```bash

# Réinstaller les dépendances

pip  install  --user  rich  requests  pyperclip

```

  

### Configuration corrompue

  

```bash

# Linux

rm  -rf  ~/.ai_terminal_chat

chat  --config

  

# Windows

Remove-Item  -Path  "$env:LOCALAPPDATA\ai_terminal_chat"  -Recurse  -Force

chat  --config

```

  

## 🔄 Mise à jour

  

```bash

git  pull

# Linux

./install.sh

  

# Windows

.\install_windows.ps1

```

  

## 🗑️ Désinstallation

  

```bash

# Linux

./uninstall.sh

  

# Windows

.\uninstall_windows.ps1

```

  

## 📋 Prérequis

  

-  **Python 3.7+** (3.8+ recommandé)

-  **Linux** : bash, curl

-  **Windows** : PowerShell 5.1+, Windows Terminal recommandé

  

## 🤝 Support

  

- Vérifiez que Python est installé et dans le PATH

- Utilisez un terminal moderne (Windows Terminal, GNOME Terminal, etc.)

- Pour Windows : PowerShell 7+ recommandé

  

---

  

## Profitez de l'IA dans votre terminal ! 🚀