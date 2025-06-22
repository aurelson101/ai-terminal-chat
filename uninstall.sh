#!/bin/bash

# Script de désinstallation pour AI Terminal Chat
echo "🗑️  Désinstallation de AI Terminal Chat..."

# Supprimer la commande globale
if [ -f "$HOME/.local/bin/chat" ]; then
    rm "$HOME/.local/bin/chat"
    echo "✅ Commande 'chat' supprimée"
fi

# Supprimer le répertoire de configuration
if [ -d "$HOME/.ai_terminal_chat" ]; then
    rm -rf "$HOME/.ai_terminal_chat"
    echo "✅ Configuration supprimée"
fi

# Optionnel: désinstaller les packages Python
read -p "Voulez-vous aussi désinstaller les packages Python (rich, pyperclip, requests) ? (y/N): " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    pip3 uninstall -y rich pyperclip requests
    echo "✅ Packages Python désinstallés"
fi

echo ""
echo "🎉 Désinstallation terminée!"
echo "💡 Note: Les modifications du PATH dans ~/.bashrc ou ~/.zshrc restent en place"
