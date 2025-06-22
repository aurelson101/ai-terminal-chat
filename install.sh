#!/bin/bash

# Installation script pour AI Terminal Chat
echo "🤖 Installation de AI Terminal Chat..."

# Vérifier si Python 3 est installé
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si pip est installé
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Créer les répertoires nécessaires
INSTALL_DIR="$HOME/.local/bin"
CHAT_DIR="$HOME/.ai_terminal_chat"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CHAT_DIR"

# Copier tous les scripts nécessaires
echo "📂 Copie des fichiers dans $CHAT_DIR..."
cp ai_chat.py "$CHAT_DIR/"
cp ai_chat_fr.py "$CHAT_DIR/"
cp ai_chat_en.py "$CHAT_DIR/"
cp requirements.txt "$CHAT_DIR/"

# Rendre tous les scripts exécutables
chmod +x "$CHAT_DIR/ai_chat.py"
chmod +x "$CHAT_DIR/ai_chat_fr.py"
chmod +x "$CHAT_DIR/ai_chat_en.py"

# Installer les dépendances Python depuis le bon répertoire
echo "📦 Installation des dépendances Python..."
pip3 install --user -r "$CHAT_DIR/requirements.txt"

# Créer la commande 'chat'
echo "🔗 Création de la commande 'chat'..."

# Créer le script wrapper
cat > "$INSTALL_DIR/chat" << EOF
#!/bin/bash
python3 "$CHAT_DIR/ai_chat.py" "\$@"
EOF

chmod +x "$INSTALL_DIR/chat"

# Vérifier si ~/.local/bin est dans le PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "⚠️  Ajout de ~/.local/bin au PATH..."
    
    # Détecter le shell et ajouter au bon fichier de config
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        echo "✅ Ajouté à ~/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "✅ Ajouté à ~/.bashrc"
    else
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
        echo "✅ Ajouté à ~/.profile"
    fi
    
    echo "🔄 Rechargez votre terminal ou exécutez: source ~/.bashrc (ou ~/.zshrc)"
fi

echo ""
echo "🎉 Installation terminée!"
echo ""
echo "📋 Pour utiliser AI Terminal Chat:"
echo "   1. Ouvrez un nouveau terminal (ou rechargez avec 'source ~/.bashrc')"
echo "   2. Tapez: chat"
echo ""
echo "🔧 Configuration:"
echo "   - Première utilisation: configuration interactive automatique"
echo "   - Reconfigurer: chat --config"
echo ""
echo "💡 Fonctionnalités:"
echo "   - Markdown et coloration syntaxique automatique"
echo "   - Copie dans le presse-papiers avec 'copy'"
echo "   - Support de tous les LLM populaires"
echo ""
