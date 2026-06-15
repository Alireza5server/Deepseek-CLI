#!/usr/bin/env bash
# DeepSeek CLI Installer with Chat Mode
#
# Usage:
#   curl -fsSL https://your-server.com/install-deepseek.sh | bash

set -euo pipefail

BINARY_NAME="deepseek-cli"

INSTALL_ID=""
INSTALL_STARTED_AT=0
INSTALL_STATUS="started"
INSTALL_TARGET=""
INSTALL_VERSION="latest"
INSTALL_DIR=""
CURRENT_STAGE="bootstrap"
INSTALL_FAILURE_REASON=""
INSTALL_FAILURE_CMD=""
INSTALL_FAILURE_STAGE=""

info() { printf '\033[0;34m%s\033[0m\n' "$*"; }
success() { printf '\033[0;32m%s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m%s\033[0m\n' "$*" >&2; }
error() { printf '\033[0;31merror: %s\033[0m\n' "$*" >&2; exit 1; }

need_cmd() {
  if ! command -v "$1" > /dev/null 2>&1; then
    error "need '$1' (command not found)"
  fi
}

generate_install_id() {
  if command -v uuidgen > /dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    printf '%s-%s-%s' "$(date +%s)" "$$" "$RANDOM"
  fi
}

detect_target() {
  local os arch target
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64) target="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) target="aarch64-unknown-linux-gnu" ;;
        *) error "unsupported Linux architecture: $arch" ;;
      esac ;;
    Darwin)
      case "$arch" in
        x86_64) target="x86_64-apple-darwin" ;;
        arm64|aarch64) target="aarch64-apple-darwin" ;;
        *) error "unsupported macOS architecture: $arch" ;;
      esac ;;
    *) error "unsupported operating system: $os" ;;
  esac
  echo "$target"
}

download_and_install() {
  local version="$1"
  local install_dir="$2"

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  need_cmd curl
  need_cmd python3

  info "Creating DeepSeek CLI with Chat Mode..."
  
  cat > "${tmp_dir}/${BINARY_NAME}" << 'EOF'
#!/usr/bin/env python3
"""
DeepSeek CLI - Full Chat Mode with Conversation History
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict, Tuple
import hashlib

try:
    import requests
except ImportError:
    print("📦 Installing requests library...")
    subprocess.run([sys.executable, "-m", "pip", "install", "requests", "--quiet"])
    import requests

try:
    from rich.console import Console
    from rich.markdown import Markdown
    from rich.table import Table
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

# Configuration
CONFIG_DIR = Path.home() / ".deepseek"
CONFIG_FILE = CONFIG_DIR / "config.json"
CHATS_DIR = CONFIG_DIR / "chats"
CURRENT_CHAT_FILE = CHATS_DIR / "current_chat.json"

class Conversation:
    """Manages conversation history"""
    
    def __init__(self, chat_id: str = None):
        self.chats_dir = CHATS_DIR
        self.chats_dir.mkdir(parents=True, exist_ok=True)
        
        if chat_id:
            self.chat_id = chat_id
            self.load()
        else:
            self.new_chat()
    
    def new_chat(self):
        """Start a new conversation"""
        self.chat_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.messages = []
        self.title = "New Chat"
        self.created_at = datetime.now().isoformat()
        self.save()
    
    def load(self, chat_id: str = None):
        """Load a conversation by ID"""
        if chat_id:
            self.chat_id = chat_id
        chat_file = self.chats_dir / f"{self.chat_id}.json"
        
        if chat_file.exists():
            with open(chat_file) as f:
                data = json.load(f)
                self.messages = data.get("messages", [])
                self.title = data.get("title", "Untitled")
                self.created_at = data.get("created_at", datetime.now().isoformat())
        else:
            self.messages = []
            self.title = "New Chat"
            self.created_at = datetime.now().isoformat()
    
    def save(self):
        """Save conversation to file"""
        chat_file = self.chats_dir / f"{self.chat_id}.json"
        with open(chat_file, "w") as f:
            json.dump({
                "chat_id": self.chat_id,
                "title": self.title,
                "messages": self.messages,
                "created_at": self.created_at,
                "updated_at": datetime.now().isoformat()
            }, f, indent=2)
    
    def add_message(self, role: str, content: str):
        """Add a message to conversation"""
        self.messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })
        
        # Auto-generate title from first user message
        if len(self.messages) == 1 and role == "user":
            self.title = content[:50] + ("..." if len(content) > 50 else "")
        
        self.save()
    
    def get_messages_for_api(self) -> List[Dict]:
        """Get messages in API format (excluding system messages if needed)"""
        return [{"role": msg["role"], "content": msg["content"]} 
                for msg in self.messages if msg["role"] != "system"]
    
    def get_history_summary(self) -> str:
        """Get a summary of conversation history"""
        if not self.messages:
            return "No messages yet"
        
        summary = []
        for msg in self.messages[-6:]:  # Last 6 messages
            role_icon = "👤" if msg["role"] == "user" else "🤖"
            preview = msg["content"][:50] + ("..." if len(msg["content"]) > 50 else "")
            summary.append(f"{role_icon} {preview}")
        
        return "\n".join(summary)
    
    def delete(self):
        """Delete this conversation"""
        chat_file = self.chats_dir / f"{self.chat_id}.json"
        if chat_file.exists():
            chat_file.unlink()
    
    @classmethod
    def list_chats(cls) -> List[Tuple[str, str, str]]:
        """List all saved chats"""
        chats = []
        for chat_file in CHATS_DIR.glob("*.json"):
            if chat_file.name == "current_chat.json":
                continue
            with open(chat_file) as f:
                data = json.load(f)
                chat_id = data.get("chat_id", chat_file.stem)
                title = data.get("title", "Untitled")
                updated = data.get("updated_at", data.get("created_at", "Unknown"))
                chats.append((chat_id, title, updated))
        
        return sorted(chats, key=lambda x: x[2], reverse=True)

class DeepSeekCLI:
    def __init__(self):
        self.config = self.load_config()
        self.api_key = self.config.get("api_key") or os.getenv("DEEPSEEK_API_KEY")
        self.conversation = None
        self.use_rich = RICH_AVAILABLE and self.config.get("use_rich", True)
        
        if self.use_rich:
            self.console = Console()
    
    def load_config(self) -> Dict:
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE) as f:
                return json.load(f)
        return {"model": "deepseek-chat", "temperature": 0.7, "max_tokens": 2000}
    
    def save_config(self):
        CONFIG_DIR.mkdir(exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(self.config, f, indent=2)
        os.chmod(CONFIG_FILE, 0o600)
    
    def set_api_key(self, api_key: str):
        self.config["api_key"] = api_key
        self.api_key = api_key
        self.save_config()
        self.print_success("✅ API key saved successfully!")
    
    def call_deepseek(self, messages: List[Dict], stream: bool = False):
        """Call DeepSeek API with conversation history"""
        if not self.api_key:
            self.print_error("❌ API key not set!")
            self.print_info("   Run: deepseek-cli --set-api-key YOUR_KEY")
            sys.exit(1)
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        # Add system prompt for safety
        system_message = {
            "role": "system",
            "content": """You are a helpful AI assistant. Be safe, ethical, and helpful.
            NEVER suggest destructive commands without warnings.
            For coding questions, provide clear explanations and working code.
            Be conversational and natural, like a human assistant."""
        }
        
        full_messages = [system_message] + messages
        
        data = {
            "model": self.config.get("model", "deepseek-chat"),
            "messages": full_messages,
            "temperature": self.config.get("temperature", 0.7),
            "max_tokens": self.config.get("max_tokens", 2000),
            "stream": stream
        }
        
        try:
            if stream:
                return self._stream_response(headers, data)
            else:
                response = requests.post(
                    "https://api.deepseek.com/v1/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=60
                )
                
                if response.status_code != 200:
                    self.print_error(f"API Error ({response.status_code}): {response.text}")
                    sys.exit(1)
                
                result = response.json()
                return result["choices"][0]["message"]["content"]
        
        except requests.exceptions.RequestException as e:
            self.print_error(f"Network error: {e}")
            sys.exit(1)
    
    def _stream_response(self, headers, data):
        """Handle streaming response"""
        response = requests.post(
            "https://api.deepseek.com/v1/chat/completions",
            headers=headers,
            json=data,
            stream=True,
            timeout=60
        )
        
        full_response = ""
        for line in response.iter_lines():
            if line:
                line = line.decode('utf-8')
                if line.startswith('data: '):
                    data_str = line[6:]
                    if data_str != '[DONE]':
                        try:
                            chunk = json.loads(data_str)
                            if 'choices' in chunk and chunk['choices']:
                                delta = chunk['choices'][0].get('delta', {})
                                content = delta.get('content', '')
                                if content:
                                    print(content, end='', flush=True)
                                    full_response += content
                        except json.JSONDecodeError:
                            pass
        
        print()  # New line after streaming
        return full_response
    
    def chat(self):
        """Interactive chat mode with full conversation history"""
        self.print_header("💬 DeepSeek Chat Mode")
        self.print_info("Commands: /new, /history, /save, /load, /list, /clear, /exit\n")
        
        # Load or create conversation
        if CURRENT_CHAT_FILE.exists():
            try:
                with open(CURRENT_CHAT_FILE) as f:
                    data = json.load(f)
                    self.conversation = Conversation(data.get("chat_id"))
                self.print_success(f"Resuming chat: {self.conversation.title}")
            except:
                self.conversation = Conversation()
        else:
            self.conversation = Conversation()
        
        # Display previous messages if any
        if self.conversation.messages:
            self.print_info(f"Continuing conversation from {self.conversation.created_at}")
            for msg in self.conversation.messages:
                if msg["role"] == "user":
                    self.print_user(msg["content"])
                else:
                    self.print_assistant(msg["content"])
        
        while True:
            try:
                user_input = self.get_user_input()
                
                if not user_input:
                    continue
                
                # Handle commands
                if user_input.startswith('/'):
                    self.handle_command(user_input)
                    continue
                
                # Add user message
                self.conversation.add_message("user", user_input)
                
                # Get response
                self.print_thinking()
                messages = self.conversation.get_messages_for_api()
                response = self.call_deepseek(messages, stream=True)
                
                # Add assistant response
                self.conversation.add_message("assistant", response)
                
                # Save current chat state
                with open(CURRENT_CHAT_FILE, "w") as f:
                    json.dump({"chat_id": self.conversation.chat_id}, f)
                
                print()  # Spacing
                
            except KeyboardInterrupt:
                print("\n")
                self.print_info("👋 Goodbye!")
                break
            except Exception as e:
                self.print_error(f"Error: {e}")
    
    def handle_command(self, cmd: str):
        """Handle slash commands"""
        cmd = cmd.lower().strip()
        
        if cmd == '/new':
            self.conversation = Conversation()
            self.print_success(f"✨ New conversation started: {self.conversation.chat_id}")
        
        elif cmd == '/history':
            self.print_info("\n📜 Recent conversation:")
            print(self.conversation.get_history_summary())
        
        elif cmd == '/list':
            chats = Conversation.list_chats()
            if not chats:
                self.print_info("No saved chats")
                return
            
            self.print_info("\n📁 Saved chats:")
            for i, (chat_id, title, updated) in enumerate(chats[:10], 1):
                print(f"  {i}. {title[:50]} ({chat_id})")
        
        elif cmd.startswith('/load'):
            parts = cmd.split()
            if len(parts) < 2:
                self.print_error("Usage: /load <chat_id>")
                return
            chat_id = parts[1]
            self.conversation = Conversation(chat_id)
            self.print_success(f"Loaded chat: {self.conversation.title}")
            
            # Show last few messages
            for msg in self.conversation.messages[-4:]:
                role = "You" if msg["role"] == "user" else "AI"
                preview = msg["content"][:100]
                print(f"\n{role}: {preview}...")
        
        elif cmd == '/save':
            self.conversation.save()
            self.print_success("Chat saved")
        
        elif cmd == '/clear':
            if Confirm.ask("Clear current conversation?"):
                self.conversation = Conversation()
                self.print_success("Conversation cleared")
        
        elif cmd == '/exit':
            raise KeyboardInterrupt
        
        else:
            self.print_error(f"Unknown command: {cmd}")
    
    def ask(self, question: str, auto_execute: bool = False):
        """Single question mode (non-interactive)"""
        self.print_info(f"🤔 Question: {question}\n")
        
        # Create temporary conversation
        conv = Conversation()
        conv.add_message("user", question)
        
        messages = conv.get_messages_for_api()
        response = self.call_deepseek(messages)
        
        self.print_assistant(response)
        
        # Extract and optionally execute commands
        if auto_execute or self.should_execute_commands(response):
            self.extract_and_execute_commands(response)
    
    def should_execute_commands(self, response: str) -> bool:
        """Ask user if they want to execute commands"""
        if '```' in response:
            return Confirm.ask("\n❓ Execute suggested commands?")
        return False
    
    def extract_and_execute_commands(self, response: str):
        """Extract and execute commands from response"""
        import re
        commands = re.findall(r'```(?:bash|shell|sh)?\n(.*?)```', response, re.DOTALL)
        
        if commands:
            for cmd_block in commands:
                for cmd in cmd_block.strip().split('\n'):
                    if cmd.strip() and not cmd.strip().startswith('#'):
                        print(f"\n▶️ Executing: {cmd}")
                        if Confirm.ask(f"Run this command?", default=False):
                            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                            if result.stdout:
                                print(result.stdout)
                            if result.stderr:
                                print(f"⚠️ {result.stderr}", file=sys.stderr)
    
    # UI Helpers
    def print_header(self, text: str):
        if self.use_rich:
            self.console.print(Panel(text, style="bold blue"))
        else:
            print(f"\n{'='*50}\n{text}\n{'='*50}")
    
    def print_success(self, text: str):
        if self.use_rich:
            self.console.print(f"[green]{text}[/green]")
        else:
            print(f"✅ {text}")
    
    def print_error(self, text: str):
        if self.use_rich:
            self.console.print(f"[red]{text}[/red]")
        else:
            print(f"❌ {text}")
    
    def print_info(self, text: str):
        if self.use_rich:
            self.console.print(f"[cyan]{text}[/cyan]")
        else:
            print(f"ℹ️ {text}")
    
    def print_user(self, text: str):
        if self.use_rich:
            self.console.print(f"[bold blue]You:[/bold blue] {text}")
        else:
            print(f"\n👤 You: {text}")
    
    def print_assistant(self, text: str):
        if self.use_rich and RICH_AVAILABLE:
            self.console.print(Markdown(text))
        else:
            print(f"\n🤖 Assistant:\n{text}")
    
    def print_thinking(self):
        if self.use_rich:
            self.console.print("[yellow]🤔 Thinking...[/yellow]", end=" ")
        else:
            print("\n🤔 Thinking...", end=" ", flush=True)
    
    def get_user_input(self) -> str:
        if self.use_rich:
            return Prompt.ask("\n[bold cyan]You[/bold cyan]")
        else:
            return input("\nYou: ").strip()

def main():
    cli = DeepSeekCLI()
    
    if len(sys.argv) < 2:
        # No arguments - start chat mode
        cli.chat()
    elif sys.argv[1] == "--set-api-key":
        if len(sys.argv) < 3:
            print("❌ Please provide API key")
            sys.exit(1)
        cli.set_api_key(sys.argv[2])
    elif sys.argv[1] == "ask":
        if len(sys.argv) < 3:
            print("❌ Please provide a question")
            sys.exit(1)
        question = " ".join(sys.argv[2:])
        auto_execute = "--yes" in sys.argv or "-y" in sys.argv
        cli.ask(question, auto_execute)
    elif sys.argv[1] == "chat":
        cli.chat()
    elif sys.argv[1] == "--version":
        print("DeepSeek CLI v2.0.0 - Full Chat Mode")
    else:
        print(f"❌ Unknown command: {sys.argv[1]}")
        print("\nUsage:")
        print("  deepseek-cli                 Start interactive chat mode")
        print("  deepseek-cli chat            Same as above")
        print("  deepseek-cli ask 'QUESTION'  Ask a single question")
        print("  deepseek-cli --set-api-key KEY  Set API key")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

  chmod +x "${tmp_dir}/${BINARY_NAME}"
  
  mkdir -p "$install_dir"
  mv "${tmp_dir}/${BINARY_NAME}" "${install_dir}/${BINARY_NAME}"
  rm -rf "${tmp_dir:-}"
  
  success "✅ Installed DeepSeek CLI with Full Chat Mode to ${install_dir}/${BINARY_NAME}"
}

ensure_path() {
  local install_dir="$1"

  case ":$PATH:" in
    *":${install_dir}:"*) return ;;
  esac

  local shell_name
  shell_name="$(basename "${SHELL:-/bin/sh}")"

  local profile_file=""
  case "$shell_name" in
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        profile_file="$HOME/.bashrc"
      elif [ -f "$HOME/.bash_profile" ]; then
        profile_file="$HOME/.bash_profile"
      fi ;;
    zsh)
      profile_file="${ZDOTDIR:-$HOME}/.zshrc" ;;
    *)
      profile_file="$HOME/.profile" ;;
  esac

  if [ -n "$profile_file" ]; then
    if ! grep -qF "$install_dir" "$profile_file" 2>/dev/null; then
      echo "" >> "$profile_file"
      echo "# DeepSeek CLI" >> "$profile_file"
      echo "export PATH=\"$install_dir:\$PATH\"" >> "$profile_file"
      info "Added to PATH in $profile_file"
    fi
  fi

  export PATH="$install_dir:$PATH"
}

main() {
  local install_dir="${DEEPSEEK_INSTALL_DIR:-$HOME/.deepseek/bin}"
  
  need_cmd curl
  need_cmd python3
  
  info "🚀 Installing DeepSeek CLI with Full Chat Mode..."
  
  download_and_install "latest" "$install_dir"
  ensure_path "$install_dir"
  
  echo ""
  success "✨ DeepSeek CLI installed successfully!"
  echo ""
  info "Features:"
  echo "  • Full conversation history"
  echo "  • Multiple chat sessions"
  echo "  • Save/load conversations"
  echo "  • Command execution with confirmation"
  echo ""
  info "Quick start:"
  echo "  1. Get API key from: https://platform.deepseek.com/api_keys"
  echo "  2. Run: deepseek-cli --set-api-key YOUR_KEY"
  echo "  3. Run: deepseek-cli          # Start chat mode"
  echo ""
  info "Chat commands:"
  echo "  /new    - Start new conversation"
  echo "  /list   - List all saved chats"
  echo "  /load   - Load a previous chat"
  echo "  /save   - Save current chat"
  echo "  /clear  - Clear current conversation"
  echo "  /exit   - Exit chat mode"
}

INSTALL_ID="$(generate_install_id)"
INSTALL_STARTED_AT="$(date +%s 2>/dev/null || echo 0)"
main "$@"