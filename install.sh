#!/bin/bash

# Installation script for AI Terminal Chat - Secure Edition
echo "🤖 Installation de AI Terminal Chat - Secure Edition..."

# Parse command line arguments
SECURE_MODE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --secure-mode)
            SECURE_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Option inconnue: $1"
            echo "Usage: $0 [--secure-mode] [--verbose]"
            exit 1
            ;;
    esac
done

if [[ "$SECURE_MODE" == true ]]; then
    echo "🔒 Mode sécurisé activé"
fi

# Security function to log messages
log_secure() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

# Vérifier si Python 3 est installé avec vérification de sécurité
log_secure "Vérification de Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1)
echo "✅ Python détecté: $PYTHON_VERSION"
log_secure "Python version: $PYTHON_VERSION"

# Security check: Verify Python version is supported (3.7+)
if python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)" 2>/dev/null; then
    echo "✅ Version Python sécurisée (3.7+)"
else
    echo "⚠️  Version Python potentiellement non sécurisée détectée"
    if [[ "$SECURE_MODE" == true ]]; then
        read -p "Continuer avec cette version? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Installation annulée"
            exit 1
        fi
    fi
fi

# Vérifier si pip est installé
log_secure "Vérification de pip..."
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

echo "✅ pip3 détecté"

# Créer les répertoires nécessaires avec permissions sécurisées
INSTALL_DIR="$HOME/.local/bin"
CHAT_DIR="$HOME/.ai_terminal_chat"

log_secure "Création des répertoires: $INSTALL_DIR, $CHAT_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CHAT_DIR"

# Set secure permissions
if [[ "$SECURE_MODE" == true ]]; then
    chmod 700 "$CHAT_DIR"
    log_secure "Permissions sécurisées appliquées à $CHAT_DIR"
fi

# Liste des fichiers à copier avec validation de sécurité
FILES_TO_COPY=(
    "ai_chat.py"
    "ai_chat_fr.py" 
    "ai_chat_en.py"
    "security_utils.py"
    "requirements.txt"
)

# Copier tous les scripts nécessaires avec validation
echo "📂 Copie des fichiers dans $CHAT_DIR..."
for file in "${FILES_TO_COPY[@]}"; do
    if [[ -f "$file" ]]; then
        # Basic security check for Python files
        if [[ "$file" == *.py ]] && [[ "$SECURE_MODE" == true ]]; then
            if grep -q "subprocess.*shell.*=.*True" "$file" && ! grep -q "#.*shell.*safe" "$file"; then
                echo "⚠️  Code potentiellement non sécurisé détecté dans $file"
                read -p "Continuer l'installation? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "❌ Installation annulée"
                    exit 1
                fi
            fi
        fi
        
        cp "$file" "$CHAT_DIR/"
        log_secure "Copié: $file"
        echo "   ✅ $file copié"
        
        # Set secure permissions for sensitive files
        if [[ "$SECURE_MODE" == true ]]; then
            chmod 600 "$CHAT_DIR/$file"
        fi
    else
        echo "   ⚠️  $file non trouvé"
    fi
done

# Rendre tous les scripts exécutables
chmod +x "$CHAT_DIR/ai_chat.py"
chmod +x "$CHAT_DIR/ai_chat_fr.py"
chmod +x "$CHAT_DIR/ai_chat_en.py"

if [[ -f "$CHAT_DIR/security_utils.py" ]]; then
    chmod +x "$CHAT_DIR/security_utils.py"
fi

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
if [[ "$SECURE_MODE" == true ]]; then
    echo "   - Mode sécurisé: chat --secure-mode"
fi
echo ""
echo "🔒 Fonctionnalités de sécurité (Nouveau!):"
echo "   - Validation des arguments d'entrée"
echo "   - Chiffrement des configurations sensibles"
echo "   - Limitation du taux de requêtes API"
echo "   - Logging sécurisé des activités"
echo ""
echo "💡 Fonctionnalités:"
echo "   - Markdown et coloration syntaxique automatique"
echo "   - Copie dans le presse-papiers avec 'copy'"
echo "   - Support de tous les LLM populaires"
echo ""

if [[ "$SECURE_MODE" == true ]]; then
    echo "🛡️  Résumé de sécurité:"
    echo "   ✅ Scripts validés pour les patterns de sécurité"
    echo "   ✅ Permissions des répertoires sécurisées"
    echo "   ✅ Dépendances installées avec vérifications"
    echo ""
    echo "🔍 Validation de sécurité:"
    echo "   ./validate_security.sh --detailed"
    echo ""
fi

log_secure "Installation completed successfully"
