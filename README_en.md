# AI Terminal Chat 🤖💬

An intelligent AI assistant for your terminal, inspired by Warp, with support for numerous local and online LLMs.

## ✨ Features

- **Complete LLM support**: Ollama, LM Studio, OpenAI, OpenRouter, Anthropic, Groq
- **Multilingual**: French and English with automatic detection
- **Cross-platform**: Linux and Windows 11 with PowerShell
- **Elegant interface**: Adaptive colors and Rich formatting
- **Simple configuration**: Interactive configuration assistant
- **Global command**: Type `chat` from anywhere

![enter image description here](https://i.ibb.co/W4QMVR5S/chat-ai-menu.png)

![enter image description here](https://i.ibb.co/YBksjB8t/chat-ai-menu-2.png)
## 🚀 Quick Installation

### Linux

```bash
# Clone the project
git clone https://github.com/aurelson101/ai-terminal-chat
cd ai-terminal-chat

# Installation
chmod +x install.sh
./install.sh

# Usage
chat
```

### Windows 11

```powershell
# Clone the project
git clone https://github.com/aurelson101/ai-terminal-chat
cd ai-terminal-chat

# Installation
.\install_windows.ps1

# Usage
chat
```

## 💬 Usage

### Basic commands

```bash
chat                    # Launch chat
chat --lang fr          # Force French
chat --lang en          # Force English
chat --select-lang      # Language selector
chat --config           # Reconfigure LLM
chat --reset-lang       # Reset language
chat --help             # Help
```

### In chat

- `copy`: Copy last response
- `config`: Reconfigure LLM
- `quit`, `exit`, `q`: Quit
- `Ctrl+C`: Quit

## 🔧 LLM Configuration

### Local LLMs (Free)

#### Ollama

```bash
# Installation
curl -fsSL https://ollama.ai/install.sh | sh

# Download a model
ollama pull llama2
ollama pull codellama
ollama pull mistral
```

#### LM Studio

1. Download from [lmstudio.ai](https://lmstudio.ai)
2. Load a model
3. Start local server (port 1234)

### External APIs

#### OpenRouter (Recommended free models)

- `microsoft/phi-4-reasoning-plus:free` - Excellent for code
- `google/gemma-2-9b-it:free` - Good general model
- `meta-llama/llama-3.1-8b-instruct:free` - Versatile

#### Other APIs

- **OpenAI**: GPT models (paid)
- **Anthropic**: Claude (paid)
- **Groq**: Fast models (freemium)

## 🌐 Language Management

The system uses intelligent priority:

1. **Forced language** (`--lang fr/en`) - Maximum priority
2. **Remembered language** - Last chosen language
3. **Auto-detection** - System language

### Examples

```bash
# First usage - automatic detection
chat  # → French if French system

# Force English - will be remembered
chat --lang en

# Next usage - uses preference
chat  # → English (remembered)

# Return to auto-detection
chat --reset-lang
```

## 📁 Structure

```text
├── ai_chat.py              # Linux main script
├── ai_chat_windows.py      # Windows main script
├── ai_chat_fr.py           # French interface
├── ai_chat_en.py           # English interface
├── windows_helper.py       # Windows helper module
├── install.sh              # Linux installation
├── install_windows.ps1     # Windows installation
├── uninstall.sh            # Linux uninstallation
├── uninstall_windows.ps1   # Windows uninstallation
├── requirements.txt        # Python dependencies
├── README.md               # French version
└── README_en.md            # This file
```

## 🛠️ Troubleshooting

### `chat` command not found

```bash
# Linux
source ~/.bashrc
# or restart terminal

# Windows
# Restart PowerShell/Terminal
```

### Python errors

```bash
# Reinstall dependencies
pip install --user rich requests pyperclip
```

### Corrupted configuration

```bash
# Linux
rm -rf ~/.ai_terminal_chat
chat --config

# Windows
Remove-Item -Path "$env:LOCALAPPDATA\ai_terminal_chat" -Recurse -Force
chat --config
```

## 🔄 Update

```bash
git pull
# Linux
./install.sh

# Windows
.\install_windows.ps1
```

## 🗑️ Uninstallation

```bash
# Linux
./uninstall.sh

# Windows
.\uninstall_windows.ps1
```

## 📋 Requirements

- **Python 3.7+** (3.8+ recommended)
- **Linux**: bash, curl
- **Windows**: PowerShell 5.1+, Windows Terminal recommended

## 🤝 Support

- Make sure Python is installed and in PATH
- Use a modern terminal (Windows Terminal, GNOME Terminal, etc.)
- For Windows: PowerShell 7+ recommended

---

## Enjoy AI in your terminal! 🚀
