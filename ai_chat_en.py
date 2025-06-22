#!/usr/bin/env python3
"""
Terminal AI Chat - A Warp clone for Linux
Allows using different LLMs (local or API) directly in the terminal
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
    """Safe prompt with keyboard interrupt and EOF handling"""
    try:
        return Prompt.ask(prompt_text, **kwargs)
    except KeyboardInterrupt:
        print("\n\n⚠️  Configuration cancelled by user.")
        print("💡 You can restart configuration later with: chat --config")
        sys.exit(0)
    except EOFError:
        print("\n\n⚠️  Input stream closed unexpectedly.")
        print("💡 Please run the configuration in an interactive terminal: chat --config")
        sys.exit(0)

class AITerminalChat:
    def __init__(self):
        self.console = Console()
        self.config_dir = Path.home() / ".ai_terminal_chat"
        self.config_file = self.config_dir / "config.json"
        self.config = self.load_config()
        
    def load_config(self) -> Dict[str, Any]:
        """Load configuration or create a default configuration"""
        if not self.config_dir.exists():
            self.config_dir.mkdir(parents=True)
            
        if not self.config_file.exists():
            return self.setup_initial_config()
        
        try:
            with open(self.config_file, 'r') as f:
                content = f.read().strip()
                if not content:  # Empty file
                    self.console.print("[bold]Empty configuration file, creating new configuration...[/bold]")
                    return self.setup_initial_config()
                return json.loads(content)
        except (json.JSONDecodeError, FileNotFoundError) as e:
            self.console.print(f"[bold]Corrupted configuration file ({e}), creating new configuration...[/bold]")
            # Backup old corrupted file
            if self.config_file.exists():
                backup_file = self.config_file.with_suffix('.json.backup')
                self.config_file.rename(backup_file)
                self.console.print(f"[dim]Old file backed up as {backup_file}[/dim]")
            return self.setup_initial_config()
        except Exception as e:
            self.console.print(f"[bold]Error loading config: {e}[/bold]")
            return self.setup_initial_config()
    
    def save_config(self):
        """Save configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            self.console.print(f"[bold]Error saving configuration: {e}[/bold]")
    
    def setup_initial_config(self) -> Dict[str, Any]:
        """Interactive initial configuration"""
        self.console.print(Panel.fit("🤖 AI Terminal Chat Initial Configuration", style="bold"))
        
        # Available LLM types
        llm_types = {
            "1": {"name": "Ollama (Local)", "type": "ollama"},
            "2": {"name": "LM Studio (Local)", "type": "lmstudio"},
            "3": {"name": "OpenAI API", "type": "openai"},
            "4": {"name": "OpenRouter API", "type": "openrouter"},
            "5": {"name": "Anthropic API", "type": "anthropic"},
            "6": {"name": "Groq API", "type": "groq"}
        }
        
        # Display options
        table = Table(title="Available LLM Types")
        table.add_column("Option", style="bold")
        table.add_column("Description", style="default")
        table.add_column("Type", style="dim")
        
        for key, value in llm_types.items():
            table.add_row(key, value["name"], value["type"])
        
        self.console.print(table)
        
        try:
            choice = safe_prompt("Choose your LLM type", choices=list(llm_types.keys()))
        except KeyboardInterrupt:
            print("\n\n⚠️  Configuration cancelled by user.")
            print("💡 You can restart configuration later with: chat --config")
            sys.exit(0)
        
        selected_llm = llm_types[choice]
        
        config = {
            "llm_type": selected_llm["type"],
            "llm_name": selected_llm["name"]
        }
        
        # Specific configuration by type
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
        
        self.save_config()
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        return config
    
    def setup_ollama(self) -> Dict[str, Any]:
        """Configure Ollama"""
        self.console.print("[bold]Ollama Configuration[/bold]")
        
        # Check if Ollama is installed
        if not shutil.which("ollama"):
            self.console.print("[bold]Ollama is not installed. Install it from https://ollama.ai[/bold]")
            return {"error": "Ollama not found"}
        
        # List available models
        try:
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
            if result.stdout.strip():
                self.console.print("[bold]Available Ollama models:[/bold]")
                self.console.print(result.stdout)
            else:
                self.console.print("[dim]No Ollama models found.[/dim]")
                self.console.print("Download a model with: ollama pull llama2")
        except Exception:
            pass
        
        model = safe_prompt("Enter model name (e.g., llama2, codellama)")
        url = safe_prompt("Ollama URL", default="http://localhost:11434")
        
        return {
            "model": model,
            "api_url": url,
            "api_key": None
        }
    
    def setup_lmstudio(self) -> Dict[str, Any]:
        """Configure LM Studio"""
        self.console.print("[bold]LM Studio Configuration[/bold]")
        
        model = safe_prompt("Model name (visible in LM Studio)", default="local-model")
        url = safe_prompt("LM Studio URL", default="http://localhost:1234")
        
        return {
            "model": model,
            "api_url": url,
            "api_key": None
        }
    
    def setup_openai(self) -> Dict[str, Any]:
        """Configure OpenAI"""
        self.console.print("[bold]OpenAI Configuration[/bold]")
        
        models = {
            "1": "gpt-4o-mini (Recommended - Good value for code)",
            "2": "gpt-4o (Most powerful)",
            "3": "gpt-3.5-turbo (Cheapest)",
            "4": "Other (manual entry)"
        }
        
        table = Table(title="OpenAI Models")
        table.add_column("Option", style="bold")
        table.add_column("Model", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choose a model", choices=list(models.keys()))
        
        if choice == "4":
            model = safe_prompt("Enter model name")
        else:
            model = models[choice].split(" ")[0]
        
        api_key = safe_prompt("OpenAI API Key", password=True)
        
        return {
            "model": model,
            "api_url": "https://api.openai.com/v1",
            "api_key": api_key
        }
    
    def setup_openrouter(self) -> Dict[str, Any]:
        """Configure OpenRouter"""
        self.console.print("[bold]OpenRouter Configuration[/bold]")
        
        # Free and paid models
        free_models = {
            "1": "microsoft/phi-4-reasoning-plus:free (Free - New! Excellent for code)",
            "2": "google/gemma-2-9b-it:free (Free - General)",
            "3": "meta-llama/llama-3.1-8b-instruct:free (Free - General)"
        }
        
        paid_models = {
            "4": "anthropic/claude-3.5-sonnet (Paid - Excellent for code)",
            "5": "openai/gpt-4o (Paid - Very good for code)",
            "6": "google/gemini-pro-1.5 (Paid - Good for code)",
            "7": "meta-llama/llama-3.1-70b-instruct (Paid - Good for code)",
            "8": "Other (manual entry)"
        }
        
        # Display free models
        table_free = Table(title="FREE OpenRouter Models")
        table_free.add_column("Option", style="bold")
        table_free.add_column("Model", style="default")
        
        for key, value in free_models.items():
            table_free.add_row(key, value)
        
        self.console.print(table_free)
        
        # Display paid models
        table_paid = Table(title="PAID OpenRouter Models (Better Performance)")
        table_paid.add_column("Option", style="bold")
        table_paid.add_column("Model", style="dim")
        
        for key, value in paid_models.items():
            table_paid.add_row(key, value)
        
        self.console.print(table_paid)
        
        all_models = {**free_models, **paid_models}
        choice = safe_prompt("Choose a model", choices=list(all_models.keys()))
        
        if choice == "8":
            model = safe_prompt("Enter model name")
        else:
            model = all_models[choice].split(" ")[0]
        
        api_key = safe_prompt("OpenRouter API Key", password=True)
        
        return {
            "model": model,
            "api_url": "https://openrouter.ai/api/v1",
            "api_key": api_key
        }
    
    def setup_anthropic(self) -> Dict[str, Any]:
        """Configure Anthropic"""
        self.console.print("[bold]Anthropic Configuration[/bold]")
        
        models = {
            "1": "claude-3-5-sonnet-20241022 (Recommended - Excellent for code)",
            "2": "claude-3-5-haiku-20241022 (Fast and cheaper)",
            "3": "claude-3-opus-20240229 (Most powerful)",
            "4": "Other (manual entry)"
        }
        
        table = Table(title="Anthropic Models")
        table.add_column("Option", style="bold")
        table.add_column("Model", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choose a model", choices=list(models.keys()))
        
        if choice == "4":
            model = safe_prompt("Enter model name")
        else:
            model = models[choice].split(" ")[0]
        
        api_key = safe_prompt("Anthropic API Key", password=True)
        
        return {
            "model": model,
            "api_url": "https://api.anthropic.com/v1",
            "api_key": api_key
        }
    
    def setup_groq(self) -> Dict[str, Any]:
        """Configure Groq"""
        self.console.print("[bold]Groq Configuration[/bold]")
        
        models = {
            "1": "llama-3.1-70b-versatile (Free - Excellent for code)",
            "2": "llama-3.1-8b-instant (Free - Very fast)",
            "3": "mixtral-8x7b-32768 (Free - Good for code)",
            "4": "Other (manual entry)"
        }
        
        table = Table(title="Groq Models (Free API with limits)")
        table.add_column("Option", style="bold")
        table.add_column("Model", style="default")
        
        for key, value in models.items():
            table.add_row(key, value)
        
        self.console.print(table)
        
        choice = safe_prompt("Choose a model", choices=list(models.keys()))
        
        if choice == "4":
            model = safe_prompt("Enter model name")
        else:
            model = models[choice].split(" ")[0]
        
        api_key = safe_prompt("Groq API Key", password=True)
        
        return {
            "model": model,
            "api_url": "https://api.groq.com/openai/v1",
            "api_key": api_key
        }
    
    def send_message(self, message: str) -> str:
        """Send message to configured LLM"""
        try:
            if self.config["llm_type"] == "ollama":
                return self.send_ollama(message)
            elif self.config["llm_type"] == "lmstudio":
                return self.send_lmstudio(message)
            elif self.config["llm_type"] in ["openai", "anthropic", "groq"]:
                return self.send_openai_compatible(message)
            elif self.config["llm_type"] == "openrouter":
                return self.send_openrouter(message)
            else:
                return "Error: Unknown LLM type"
        except Exception as e:
            return f"Error: {str(e)}"
    
    def send_ollama(self, message: str) -> str:
        """Send message to Ollama"""
        url = f"{self.config['api_url']}/api/generate"
        data = {
            "model": self.config["model"],
            "prompt": message,
            "stream": False
        }
        response = requests.post(url, json=data)
        response.raise_for_status()
        return response.json()["response"]
    
    def send_lmstudio(self, message: str) -> str:
        """Send message to LM Studio"""
        url = f"{self.config['api_url']}/v1/chat/completions"
        data = {
            "model": self.config["model"],
            "messages": [{"role": "user", "content": message}],
            "temperature": 0.7
        }
        response = requests.post(url, json=data)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    
    def send_openai_compatible(self, message: str) -> str:
        """Send message to OpenAI-compatible API (OpenAI, Anthropic, Groq)"""
        url = f"{self.config['api_url']}/chat/completions"
        headers = {"Authorization": f"Bearer {self.config['api_key']}"}
        
        # Special handling for Anthropic
        if self.config["llm_type"] == "anthropic":
            url = f"{self.config['api_url']}/messages"
            headers = {
                "x-api-key": self.config['api_key'],
                "anthropic-version": "2023-06-01",
                "content-type": "application/json"
            }
            data = {
                "model": self.config["model"],
                "max_tokens": 4096,
                "messages": [{"role": "user", "content": message}]
            }
        else:
            data = {
                "model": self.config["model"],
                "messages": [{"role": "user", "content": message}],
                "temperature": 0.7
            }
        
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        
        if self.config["llm_type"] == "anthropic":
            return response.json()["content"][0]["text"]
        else:
            return response.json()["choices"][0]["message"]["content"]
    
    def send_openrouter(self, message: str) -> str:
        """Send message to OpenRouter"""
        url = f"{self.config['api_url']}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.config['api_key']}",
            "Content-Type": "application/json"
        }
        data = {
            "model": self.config["model"],
            "messages": [{"role": "user", "content": message}],
            "temperature": 0.7
        }
        
        # Use data=json.dumps(data) for OpenRouter compatibility
        response = requests.post(url, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    
    def format_response(self, response: str):
        """Format and display AI response"""
        try:
            # Code detection in response
            if "```" in response:
                self.console.print(Markdown(response))
            else:
                # Simple display if no markdown
                self.console.print(Panel(response, title="🤖 AI Response", style="default"))
        except Exception:
            # Fallback in case of formatting error
            self.console.print(response)
    
    def start_chat(self):
        """Start interactive chat"""
        self.console.print(Panel.fit(
            f"🤖 AI Terminal Chat\n"
            f"LLM: {self.config['llm_name']} ({self.config['model']})\n"
            f"Type 'quit', 'exit' or Ctrl+C to quit\n"
            f"Type 'copy' to copy last response\n"
            f"Type 'config' to reconfigure",
            style="bold"
        ))
        
        last_response = ""
        
        try:
            while True:
                # User prompt
                user_input = safe_prompt("\n[bold]You[/bold]")
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    break
                elif user_input.lower() == 'copy':
                    if last_response:
                        try:
                            pyperclip.copy(last_response)
                            self.console.print("[bold]✓ Response copied to clipboard[/bold]")
                        except Exception:
                            self.console.print("[bold]Error: cannot copy to clipboard[/bold]")
                    else:
                        self.console.print("[dim]No response to copy[/dim]")
                    continue
                elif user_input.lower() == 'config':
                    self.config = self.setup_initial_config()
                    continue
                
                # Loading indicator
                with self.console.status("[bold]🤔 Thinking..."):
                    response = self.send_message(user_input)
                
                last_response = response
                self.format_response(response)
                
        except KeyboardInterrupt:
            self.console.print("\n[dim]Goodbye! 👋[/dim]")
        except Exception as e:
            self.console.print(f"[bold]Error: {e}[/bold]")

def main():
    parser = argparse.ArgumentParser(description="AI Terminal Chat - Warp clone for Linux")
    parser.add_argument("--config", action="store_true", help="Reconfigure LLM")
    args = parser.parse_args()
    
    chat = AITerminalChat()
    
    if args.config:
        chat.config = chat.setup_initial_config()
    
    chat.start_chat()

if __name__ == "__main__":
    main()
