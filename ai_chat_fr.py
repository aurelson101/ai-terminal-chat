#!/usr/bin/env python3
"""
Terminal AI Chat - Un clone de Warp pour Linux
Permet d'utiliser différents LLM (locaux ou API) directement dans le terminal
"""

import sys
import json
import requests
import subprocess
import argparse
from pathlib import Path
from typing import Dict, Any
import shutil
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel
from rich.prompt import Prompt
from rich.table import Table
import pyperclip

def safe_prompt(prompt_text, **kwargs):
    """Prompt sécurisé avec gestion des interruptions clavier et EOF"""
    try:
        return Prompt.ask(prompt_text, **kwargs)
    except KeyboardInterrupt:
        print("\n\n⚠️  Configuration annulée par l'utilisateur.")
        print("💡 Vous pouvez relancer la configuration plus tard avec: chat --config")
        sys.exit(0)
    except EOFError:
        print("\n\n⚠️  Flux d'entrée fermé de manière inattendue.")
        print("💡 Veuillez lancer la configuration dans un terminal interactif: chat --config")
        sys.exit(0)

class AITerminalChat:
    def __init__(self):
        self.console = Console()
        self.config_dir = Path.home() / ".ai_terminal_chat"
        self.config_file = self.config_dir / "config.json"
        self.config = self.load_config()
        
    def load_config(self) -> Dict[str, Any]:
        """Charge la configuration ou crée une configuration par défaut"""
        if not self.config_dir.exists():
            self.config_dir.mkdir(parents=True)
            
        if not self.config_file.exists():
            return self.setup_initial_config()
        
        try:
            with open(self.config_file, 'r') as f:
                content = f.read().strip()
                if not content:  # Fichier vide
                    self.console.print("[dim]Fichier de configuration vide, création d'une nouvelle configuration...[/dim]")
                    return self.setup_initial_config()
                return json.loads(content)
        except (json.JSONDecodeError, FileNotFoundError) as e:
            self.console.print(f"[bold]Fichier de configuration corrompu ({e}), création d'une nouvelle configuration...[/bold]")
            # Sauvegarder l'ancien fichier corrompu
            if self.config_file.exists():
                backup_file = self.config_file.with_suffix('.json.backup')
                self.config_file.rename(backup_file)
                self.console.print(f"[dim]Ancien fichier sauvegardé en tant que {backup_file}[/dim]")
            return self.setup_initial_config()
        except Exception as e:
            self.console.print(f"[bold]Erreur lors du chargement de la config: {e}[/bold]")
            return self.setup_initial_config()
    
    def save_config(self):
        """Sauvegarde la configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            self.console.print(f"[bold]Erreur lors de la sauvegarde de la configuration: {e}[/bold]")
    
    def setup_initial_config(self) -> Dict[str, Any]:
        """Configuration initiale interactive"""
        self.console.print(Panel.fit("🤖 Configuration initiale de AI Terminal Chat", style="bold"))
        
        # Types de LLM disponibles
        llm_types = {
            "1": {"name": "Ollama (Local)", "type": "ollama"},
            "2": {"name": "LM Studio (Local)", "type": "lmstudio"},
            "3": {"name": "OpenAI API", "type": "openai"},
            "4": {"name": "OpenRouter API", "type": "openrouter"},
            "5": {"name": "Anthropic API", "type": "anthropic"},
            "6": {"name": "Groq API", "type": "groq"}
        }
        
        # Affichage des options
        table = Table(title="Types de LLM disponibles")
        table.add_column("Option", style="bold")
        table.add_column("Description", style="default")
        table.add_column("Type", style="dim")
        
        for key, value in llm_types.items():
            table.add_row(key, value["name"], value["type"])
        
        self.console.print(table)
        
        try:
            choice = safe_prompt("Choisissez votre type de LLM", choices=list(llm_types.keys()))
        except KeyboardInterrupt:
            print("\n\n⚠️  Configuration annulée par l'utilisateur.")
            print("💡 Vous pouvez relancer la configuration plus tard avec: chat --config")
            sys.exit(0)
        
        selected_llm = llm_types[choice]
        
        config = {
            "llm_type": selected_llm["type"],
            "llm_name": selected_llm["name"]
        }
        
        # Configuration spécifique selon le type
        if selected_llm["type"] == "ollama":
            config.update(self.setup_ollama())
        elif selected_llm["type"] == "lmstudio":
            config.update(self.setup_lmstudio())
        elif selected_llm["type"] == "openai":
            config.update(self.setup_openai())
        elif selected_llm["type"] == "openrouter":
            config.update(self.setup_openrouter())
        elif selected_llm["type"] == "anthropic":
            config.update(self.setup_anthropic())
        elif selected_llm["type"] == "groq":
            config.update(self.setup_groq())
        
        # Assigner la config avant de sauvegarder
        self.config = config
        
        # Sauvegarder la config
        self.save_config()
        return config
    
    def setup_ollama(self) -> Dict[str, Any]:
        """Configuration Ollama"""
        self.console.print("[bold]Configuration Ollama[/bold]")
        
        # Vérifier si Ollama est installé
        if not shutil.which("ollama"):
            self.console.print("[bold]Ollama n'est pas installé. Installez-le depuis https://ollama.ai[/bold]")
            sys.exit(1)
        
        # Lister les modèles disponibles
        try:
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
            if result.returncode == 0:
                self.console.print("[bold]Modèles Ollama disponibles:[/bold]")
                self.console.print(result.stdout)
            else:
                self.console.print("[dim]Aucun modèle Ollama trouvé.[/dim]")
        except Exception:
            pass
        
        model = safe_prompt("Modèle Ollama à utiliser", default="llama2")
        base_url = safe_prompt("URL de base Ollama", default="http://localhost:11434")
        
        return {
            "model": model,
            "base_url": base_url
        }
    
    def setup_lmstudio(self) -> Dict[str, Any]:
        """Configuration LM Studio"""
        self.console.print("[bold]Configuration LM Studio[/bold]")
        
        model = safe_prompt("Nom du modèle LM Studio", default="local-model")
        base_url = safe_prompt("URL de base LM Studio", default="http://localhost:1234")
        
        return {
            "model": model,
            "base_url": base_url
        }
    
    def setup_openai(self) -> Dict[str, Any]:
        """Configuration OpenAI"""
        self.console.print("[bold]Configuration OpenAI[/bold]")
        
        # Modèles recommandés
        models = {
            "1": "gpt-4o-mini (Recommandé pour le code)",
            "2": "gpt-4o (Plus puissant)",
            "3": "gpt-3.5-turbo (Économique)",
            "4": "Autre (saisie manuelle)"
        }
        
        table = Table(title="Modèles OpenAI")
        table.add_column("Option", style="bold")
        table.add_column("Modèle", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choisissez un modèle", choices=list(models.keys()))
        
        if choice == "1":
            model = "gpt-4o-mini"
        elif choice == "2":
            model = "gpt-4o"
        elif choice == "3":
            model = "gpt-3.5-turbo"
        else:
            model = safe_prompt("Nom du modèle")
        
        api_key = safe_prompt("Clé API OpenAI", password=True)
        
        return {
            "model": model,
            "api_key": api_key,
            "base_url": "https://api.openai.com/v1"
        }
    
    def setup_openrouter(self) -> Dict[str, Any]:
        """Configuration OpenRouter"""
        self.console.print("[bold]Configuration OpenRouter[/bold]")
        
        # Modèles gratuits et payants
        free_models = {
            "1": "microsoft/phi-4-reasoning-plus:free (Gratuit - Nouveau ! Excellent pour le code)",
            "2": "google/gemma-2-9b-it:free (Gratuit - Général)",
            "3": "meta-llama/llama-3.1-8b-instruct:free (Gratuit - Général)"
        }
        
        paid_models = {
            "4": "anthropic/claude-3.5-sonnet (Payant - Excellent pour le code)",
            "5": "openai/gpt-4o (Payant - Très bon pour le code)",
            "6": "google/gemini-pro-1.5 (Payant - Bon pour le code)",
            "7": "meta-llama/llama-3.1-70b-instruct (Payant - Bon pour le code)",
            "8": "Autre (saisie manuelle)"
        }
        
        # Affichage des modèles gratuits
        table_free = Table(title="Modèles OpenRouter GRATUITS")
        table_free.add_column("Option", style="bold")
        table_free.add_column("Modèle", style="default")
        
        for key, value in free_models.items():
            table_free.add_row(key, value)
        
        self.console.print(table_free)
        
        # Affichage des modèles payants
        table_paid = Table(title="Modèles OpenRouter PAYANTS (Performance supérieure)")
        table_paid.add_column("Option", style="bold")
        table_paid.add_column("Modèle", style="dim")
        
        for key, value in paid_models.items():
            table_paid.add_row(key, value)
        
        self.console.print(table_paid)
        
        all_models = {**free_models, **paid_models}
        choice = safe_prompt("Choisissez un modèle", choices=list(all_models.keys()))
        
        model_mapping = {
            "1": "microsoft/phi-4-reasoning-plus:free",
            "2": "microsoft/phi-3-mini-128k-instruct:free",
            "3": "google/gemma-2-9b-it:free", 
            "4": "meta-llama/llama-3.1-8b-instruct:free",
            "5": "anthropic/claude-3.5-sonnet",
            "6": "openai/gpt-4o",
            "7": "google/gemini-pro-1.5",
            "8": "meta-llama/llama-3.1-70b-instruct"
        }
        
        if choice in model_mapping:
            model = model_mapping[choice]
        else:
            model = safe_prompt("Nom du modèle")
        
        api_key = safe_prompt("Clé API OpenRouter", password=True)
        
        return {
            "model": model,
            "api_key": api_key,
            "base_url": "https://openrouter.ai/api/v1"
        }
    
    def setup_anthropic(self) -> Dict[str, Any]:
        """Configuration Anthropic"""
        self.console.print("[bold]Configuration Anthropic[/bold]")
        
        models = {
            "1": "claude-3-5-sonnet-20241022 (Recommandé pour le code)",
            "2": "claude-3-haiku-20240307 (Plus rapide)",
            "3": "Autre (saisie manuelle)"
        }
        
        table = Table(title="Modèles Anthropic")
        table.add_column("Option", style="bold")
        table.add_column("Modèle", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choisissez un modèle", choices=list(models.keys()))
        
        if choice == "1":
            model = "claude-3-5-sonnet-20241022"
        elif choice == "2":
            model = "claude-3-haiku-20240307"
        else:
            model = safe_prompt("Nom du modèle")
        
        api_key = safe_prompt("Clé API Anthropic", password=True)
        
        return {
            "model": model,
            "api_key": api_key,
            "base_url": "https://api.anthropic.com"
        }
    
    def setup_groq(self) -> Dict[str, Any]:
        """Configuration Groq"""
        self.console.print("[bold]Configuration Groq[/bold]")
        
        models = {
            "1": "llama-3.1-70b-versatile (Gratuit - Excellent pour le code)",
            "2": "llama-3.1-8b-instant (Gratuit - Rapide)",
            "3": "mixtral-8x7b-32768 (Gratuit - Bon pour le code)",
            "4": "Autre (saisie manuelle)"
        }
        
        table = Table(title="Modèles Groq (API gratuite avec limites)")
        table.add_column("Option", style="bold")
        table.add_column("Modèle", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choisissez un modèle", choices=list(models.keys()))
        
        if choice == "1":
            model = "llama-3.1-70b-versatile"
        elif choice == "2":
            model = "llama-3.1-8b-instant"
        elif choice == "3":
            model = "mixtral-8x7b-32768"
        else:
            model = safe_prompt("Nom du modèle")
        
        api_key = safe_prompt("Clé API Groq", password=True)
        
        return {
            "model": model,
            "api_key": api_key,
            "base_url": "https://api.groq.com/openai/v1"
        }
    
    def send_message(self, message: str) -> str:
        """Envoie un message au LLM configuré"""
        try:
            if self.config["llm_type"] in ["ollama", "lmstudio"]:
                return self.send_to_local_llm(message)
            else:
                return self.send_to_api_llm(message)
        except requests.exceptions.HTTPError as e:
            # Erreur HTTP spécifique
            if e.response.status_code == 404:
                return f"❌ Erreur 404: Endpoint API non trouvé. Vérifiez la configuration de votre LLM.\nURL utilisée: {e.response.url}\nType LLM: {self.config['llm_type']}"
            elif e.response.status_code == 401:
                return f"❌ Erreur 401: Clé API invalide ou expirée pour {self.config['llm_type']}"
            elif e.response.status_code == 429:
                return f"❌ Erreur 429: Limite de taux dépassée pour {self.config['llm_type']}. Attendez un moment."
            else:
                return f"❌ Erreur HTTP {e.response.status_code}: {e.response.text}"
        except requests.exceptions.ConnectionError:
            return f"❌ Erreur de connexion. Vérifiez votre connexion internet et l'URL de base: {self.config.get('base_url', 'non configurée')}"
        except requests.exceptions.Timeout:
            return f"❌ Timeout: Le LLM {self.config['llm_type']} met trop de temps à répondre"
        except KeyError as e:
            return f"❌ Erreur de configuration: clé manquante {e}. Utilisez 'config' pour reconfigurer."
        except Exception as e:
            return f"❌ Erreur lors de l'envoi du message: {str(e)}"
    
    def send_to_local_llm(self, message: str) -> str:
        """Envoi vers un LLM local (Ollama/LMStudio)"""
        url = f"{self.config['base_url']}/api/generate"
        
        data = {
            "model": self.config["model"],
            "prompt": message,
            "stream": False
        }
        
        response = requests.post(url, json=data, timeout=120)
        response.raise_for_status()
        
        if self.config["llm_type"] == "ollama":
            return response.json()["response"]
        else:  # LMStudio
            return response.json()["choices"][0]["text"]
    
    def send_to_api_llm(self, message: str) -> str:
        """Envoi vers une API externe"""
        headers = {
            "Content-Type": "application/json"
        }
        
        if self.config["llm_type"] == "anthropic":
            headers["x-api-key"] = self.config["api_key"]
            headers["anthropic-version"] = "2023-06-01"
            
            data = {
                "model": self.config["model"],
                "max_tokens": 4096,
                "messages": [{"role": "user", "content": message}]
            }
            
            response = requests.post(
                f"{self.config['base_url']}/v1/messages",
                headers=headers,
                json=data,
                timeout=120
            )
            response.raise_for_status()
            return response.json()["content"][0]["text"]
        
        else:  # OpenAI, OpenRouter, Groq (compatible OpenAI)
            headers["Authorization"] = f"Bearer {self.config['api_key']}"
            
            # Ajouter des en-têtes spécifiques pour OpenRouter (SELON LA DOC OFFICIELLE)
            if self.config["llm_type"] == "openrouter":
                headers["HTTP-Referer"] = "https://github.com/ai-terminal-chat"
                headers["X-Title"] = "AI Terminal Chat"
            
            data = {
                "model": self.config["model"],
                "messages": [{"role": "user", "content": message}],
                "max_tokens": 4096,
                "temperature": 0.7
            }
            
            # CORRECTION CLÉE : OpenRouter veut data=json.dumps(), pas json=data
            if self.config["llm_type"] == "openrouter":
                import json
                response = requests.post(
                    f"{self.config['base_url']}/chat/completions",
                    headers=headers,
                    data=json.dumps(data),  # <-- VOICI LA CORRECTION !
                    timeout=120
                )
            else:
                # Groq et OpenAI utilisent json=data normalement
                response = requests.post(
                    f"{self.config['base_url']}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=120
                )
            
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"]
    
    def format_response(self, response: str):
        """Formate la réponse avec Rich (markdown, code, etc.)"""
        try:
            # Détection de code dans la réponse
            if "```" in response:
                self.console.print(Markdown(response))
            else:
                # Affichage simple si pas de markdown
                self.console.print(Panel(response, title="🤖 Réponse IA", style="default"))
        except Exception:
            # Fallback en cas d'erreur de formatage
            self.console.print(response)
    
    def start_chat(self):
        """Démarre le chat interactif"""
        self.console.print(Panel.fit(
            f"🤖 AI Terminal Chat\n"
            f"LLM: {self.config['llm_name']} ({self.config['model']})\n"
            f"Tapez 'quit', 'exit' ou Ctrl+C pour quitter\n"
            f"Tapez 'copy' pour copier la dernière réponse\n"
            f"Tapez 'config' pour reconfigurer",
            style="bold"
        ))
        
        last_response = ""
        
        try:
            while True:
                # Prompt utilisateur
                user_input = safe_prompt("\n[bold]Vous[/bold]")
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    break
                elif user_input.lower() == 'copy':
                    if last_response:
                        try:
                            pyperclip.copy(last_response)
                            self.console.print("[bold]✓ Réponse copiée dans le presse-papiers[/bold]")
                        except Exception:
                            self.console.print("[bold]Erreur: impossible de copier dans le presse-papiers[/bold]")
                    else:
                        self.console.print("[dim]Aucune réponse à copier[/dim]")
                    continue
                elif user_input.lower() == 'config':
                    self.config = self.setup_initial_config()
                    continue
                
                # Indicateur de chargement
                with self.console.status("[bold]🤔 Réflexion en cours..."):
                    response = self.send_message(user_input)
                
                last_response = response
                self.format_response(response)
                
        except KeyboardInterrupt:
            self.console.print("\n[dim]Au revoir! 👋[/dim]")
        except Exception as e:
            self.console.print(f"[bold]Erreur: {e}[/bold]")

def main():
    parser = argparse.ArgumentParser(description="AI Terminal Chat - Clone de Warp pour Linux")
    parser.add_argument("--config", action="store_true", help="Reconfigurer le LLM")
    args = parser.parse_args()
    
    chat = AITerminalChat()
    
    if args.config:
        chat.config = chat.setup_initial_config()
    
    chat.start_chat()

if __name__ == "__main__":
    main()
