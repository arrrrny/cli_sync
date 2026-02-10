#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/mcp_sync_configs"
BACKUP_DIR="${CONFIG_DIR}/backups"
MASTER_CONFIG="${CONFIG_DIR}/master_mcp_servers.json"

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

ZED_CONFIG="${HOME}/.config/zed/settings.json"
AMP_CONFIG="${HOME}/.config/amp/settings.json"
TRAE_CONFIG="${HOME}/Library/Application Support/Trae/User/mcp.json"
CLAUDE_CONFIG="${HOME}/.claude/settings.json"
KILO_CONFIG="${HOME}/Library/Application Support/Trae/User/globalStorage/kilocode.kilo-code/settings/mcp_settings.json"
FACTORY_CONFIG="/Users/arrrrny/.factory/mcp.json"
OPENCODE_CONFIG="/Users/arrrrny/.config/opencode/opencode.json"
VIBE_CONFIG="/Users/arrrrny/.vibe/config.toml"
QWEN_CONFIG="${HOME}/.qwen/settings.json"

KIRO_BIN="/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

backup() {
  local file=$1 name=$2
  [[ -f "$file" ]] && cp "$file" "${BACKUP_DIR}/${name}_${TIMESTAMP}.json"
}

render_config() {
  python3 - "$MASTER_CONFIG" "$SCRIPT_DIR/.env" << 'PYTHON'
import sys, json, re, os

master_path = sys.argv[1]
env_path = sys.argv[2] if len(sys.argv) > 2 else None

replacements = {
    "Z_AI_API_KEY": "",
    "TRELLO_TOKEN": "",
    "TRELLO_API_KEY": "",
    "GITHUB_PERSONAL_ACCESS_TOKEN": "",
    "QDRANT_URL": "http://localhost:6333",
    "QDRANT_API_KEY": "",
    "CONTEXT7_API_KEY":""
}

zshrc_path = os.path.expanduser("~/.zshrc")
for line in open(zshrc_path):
    line = line.strip()
    if not line.startswith("export "):
        continue
    match = re.match(r'export (\w+)=(.+)', line)
    if match:
        key, value = match.groups()
        value = value.strip('"\'')
        if key in replacements and value and not value.startswith("${"):
            replacements[key] = value

if env_path and os.path.exists(env_path):
    for line in open(env_path):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r'(\w+)=(.+)', line)
        if match:
            key, value = match.groups()
            if key in replacements:
                replacements[key] = value.strip()

content = open(master_path).read()
for key, value in replacements.items():
    content = content.replace("${" + key + "}", value)

data = json.loads(content)
print(json.dumps(data, indent=2))
PYTHON
}

sync_zed() {
  log_info "Syncing Zed..."
  backup "$ZED_CONFIG" "zed"
  render_config > "${MASTER_CONFIG}.rendered"
  python3 - "$ZED_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
zed_path, master_path = sys.argv[1], sys.argv[2]
with open(zed_path) as f: zed = json.load(f)
with open(master_path) as f: mcp = json.load(f)
zed['context_servers'] = mcp
json.dump(zed, open(zed_path, 'w'), indent=2)
PYTHON
  rm -f "${MASTER_CONFIG}.rendered"
  log_success "Zed synced"
}

sync_amp() {
  log_info "Syncing Amp..."
  backup "$AMP_CONFIG" "amp"
  render_config > "${MASTER_CONFIG}.rendered"
  python3 - "$AMP_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
amp_path, master_path = sys.argv[1], sys.argv[2]
with open(amp_path) as f: amp = json.load(f)
with open(master_path) as f: mcp = json.load(f)

amp['amp.mcpServers'] = {}
for name, config in mcp.items():
    cmd = config.get("command", "")
    args = config.get("args", [])
    env = config.get("env", {})
    amp['amp.mcpServers'][name] = {
        "command": cmd,
        "args": args if args else [],
        "env": env,
        "enabled": True
    }

json.dump(amp, open(amp_path, 'w'), indent=2)
PYTHON
  rm -f "${MASTER_CONFIG}.rendered"
  log_success "Amp synced"
}

sync_claude() {
  log_info "Syncing Claude..."
  backup "$CLAUDE_CONFIG" "claude"
  render_config > "${MASTER_CONFIG}.rendered"
  python3 - "$CLAUDE_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
claude_path, master_path = sys.argv[1], sys.argv[2]
with open(claude_path) as f: claude = json.load(f)
with open(master_path) as f: mcp = json.load(f)
claude['mcpServers'] = mcp
json.dump(claude, open(claude_path, 'w'), indent=2)
PYTHON
  rm -f "${MASTER_CONFIG}.rendered"
  log_success "Claude synced"
}

sync_kiro() {
  log_info "Syncing Kiro CLI..."
  if [[ -x "$KIRO_BIN" ]]; then
    render_config > "${MASTER_CONFIG}.rendered"
    current=$("$KIRO_BIN" mcp list 2>/dev/null | grep -E '^[a-zA-Z]' | awk '{print $1}' || true)
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      cmd=$(jq -r ".[\"$name\"].command // empty" "${MASTER_CONFIG}.rendered" 2>/dev/null)
      args=$(jq -r ".[\"$name\"].args // [] | join(\" \")" "${MASTER_CONFIG}.rendered" 2>/dev/null || echo "")
      if [[ -n "$cmd" && "$cmd" != "null" ]]; then
        if echo "$current" | grep -q "^${name}$"; then
          log_info "Kiro already has $name"
        else
          log_info "Adding $name to Kiro..."
          "$KIRO_BIN" mcp add "$name" "$cmd" $args 2>/dev/null || true
        fi
      fi
    done < <(jq -r 'keys[]' "${MASTER_CONFIG}.rendered" 2>/dev/null || echo "")
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "Kiro synced"
  else
    log_info "Kiro CLI not found"
  fi
}

sync_kilo() {
  log_info "Syncing Kilo-code..."
  backup "$KILO_CONFIG" "kilo"
  render_config > "${MASTER_CONFIG}.rendered"
  python3 - "$KILO_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
kilo_path, master_path = sys.argv[1], sys.argv[2]
with open(master_path) as f: mcp = json.load(f)
output = {"mcpServers": {}}
for k, v in mcp.items():
    output["mcpServers"][k] = {
        "command": v.get("command"),
        "args": v.get("args", []),
        "env": v.get("env", {})
    }
json.dump(output, open(kilo_path, 'w'), indent=2)
PYTHON
  rm -f "${MASTER_CONFIG}.rendered"
  log_success "Kilo synced"
}

sync_factory() {
  log_info "Syncing Factory-droid..."
  if [[ -f "$FACTORY_CONFIG" ]]; then
    backup "$FACTORY_CONFIG" "factory"
    render_config > "${MASTER_CONFIG}.rendered"
    python3 - "$FACTORY_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
factory_path, master_path = sys.argv[1], sys.argv[2]
with open(master_path) as f: mcp = json.load(f)
json.dump(mcp, open(factory_path, 'w'), indent=2)
PYTHON
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "Factory-droid synced"
  else
    log_info "Factory-droid config not found"
  fi
}

sync_trae() {
  log_info "Syncing Trae..."
  if [[ -f "$TRAE_CONFIG" ]]; then
    backup "$TRAE_CONFIG" "trae"
    render_config > "${MASTER_CONFIG}.rendered"
    python3 - "$TRAE_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
trae_path, master_path = sys.argv[1], sys.argv[2]
with open(trae_path) as f: trae = json.load(f)
with open(master_path) as f: mcp = json.load(f)

trae['mcpServers'] = {}
for name, config in mcp.items():
    cmd = config.get("command", "")
    args = config.get("args", [])
    env = config.get("env", {})
    trae['mcpServers'][name] = {
        "command": cmd,
        "args": args if args else [],
        "env": env,
        "enabled": True
    }

json.dump(trae, open(trae_path, 'w'), indent=2)
PYTHON
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "Trae synced"
  else
    log_info "Trae config not found"
  fi
}

sync_qwen() {
  log_info "Syncing Qwen..."
  if [[ -f "$QWEN_CONFIG" ]]; then
    backup "$QWEN_CONFIG" "qwen"
    render_config > "${MASTER_CONFIG}.rendered"
    python3 - "$QWEN_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json
qwen_path, master_path = sys.argv[1], sys.argv[2]
with open(qwen_path) as f: qwen = json.load(f)
with open(master_path) as f: mcp = json.load(f)

qwen['mcpServers'] = {}
for name, config in mcp.items():
    cmd = config.get("command", "")
    args = config.get("args", [])
    env = config.get("env", {})
    qwen['mcpServers'][name] = {
        "command": cmd,
        "args": args if args else [],
        "env": env
    }

json.dump(qwen, open(qwen_path, 'w'), indent=2)
PYTHON
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "Qwen synced"
  else
    log_info "Qwen config not found"
  fi
}

sync_opencode() {
  log_info "Syncing OpenCode..."
  if [[ -f "$OPENCODE_CONFIG" ]]; then
    backup "$OPENCODE_CONFIG" "opencode"
    render_config > "${MASTER_CONFIG}.rendered"
    python3 - "$OPENCODE_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json, re

opencode_path = sys.argv[1]
master_path = sys.argv[2]

with open(opencode_path) as f:
    content = f.read()

content = re.sub(r',\s*([}\]])', r'\1', content)
opencode = json.loads(content)

with open(master_path) as f: mcp = json.load(f)

opencode['mcp'] = {}
for name, config in mcp.items():
    cmd = config.get("command", "")
    args = config.get("args", [])
    opencode['mcp'][name] = {
        "command": [cmd] + args if args else [cmd],
        "enabled": True,
        "type": "local"
    }

json.dump(opencode, open(opencode_path, 'w'), indent=2, separators=(',', ': '))
PYTHON
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "OpenCode synced"
  else
    log_info "OpenCode config not found"
  fi
}

sync_vibe() {
  log_info "Syncing Mistral Vibe..."
  if [[ -f "$VIBE_CONFIG" ]]; then
    backup "$VIBE_CONFIG" "vibe"
    render_config > "${MASTER_CONFIG}.rendered"
    python3 - "$VIBE_CONFIG" "${MASTER_CONFIG}.rendered" << 'PYTHON'
import sys, json

config_path = sys.argv[1]
master_path = sys.argv[2]

with open(master_path) as f: mcp = json.load(f)

servers_toml = []
for name, config in mcp.items():
    server_toml = f'[[mcp_servers]]\nname = "{name}"\ntransport = "stdio"\n'
    server_toml += f'command = "{config.get("command", "")}"\n'
    args = config.get("args", [])
    if args:
        server_toml += 'args = [' + ', '.join(f'"{a}"' for a in args) + ']\n'
    env = config.get("env", {})
    if env:
        server_toml += 'env = { ' + ', '.join(f'{k} = "{v}"' for k, v in env.items()) + ' }\n'
    servers_toml.append(server_toml)

with open(config_path) as f:
    content = f.read()

header = content.split("[[mcp_servers]]")[0].strip()
new_content = header + "\n" + "\n".join(servers_toml) + "\n"

with open(config_path, 'w') as f:
    f.write(new_content)
PYTHON
    rm -f "${MASTER_CONFIG}.rendered"
    log_success "Vibe synced"
  else
    log_info "Vibe config not found"
  fi
}

status() {
  echo -e "${BLUE}=== MCP Status ===${NC}\n"

  echo -e "${BLUE}Zed:${NC} $(python3 -c "import json; print(len(json.load(open('$ZED_CONFIG'))['context_servers']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$ZED_CONFIG'))['context_servers'].keys()]))" 2>/dev/null
  echo ""

  echo -e "${BLUE}Claude:${NC} $(python3 -c "import json; print(len(json.load(open('$CLAUDE_CONFIG'))['mcpServers']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$CLAUDE_CONFIG'))['mcpServers'].keys()]))" 2>/dev/null
  echo ""

  echo -e "${BLUE}Amp:${NC} $(python3 -c "import json; print(len(json.load(open('$AMP_CONFIG'))['amp.mcpServers']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$AMP_CONFIG'))['amp.mcpServers'].keys()]))" 2>/dev/null
  echo ""

  echo -e "${BLUE}Kilo-code:${NC} $(python3 -c "import json; print(len(json.load(open('$KILO_CONFIG'))['mcpServers']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$KILO_CONFIG'))['mcpServers'].keys()]))" 2>/dev/null
  echo ""

  echo -e "${BLUE}Qwen:${NC} $(python3 -c "import json; print(len(json.load(open('$QWEN_CONFIG'))['mcpServers']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$QWEN_CONFIG'))['mcpServers'].keys()]))" 2>/dev/null
  echo ""

  echo -e "${BLUE}OpenCode:${NC} $(python3 -c "import json; print(len(json.load(open('$OPENCODE_CONFIG'))['mcp']))" 2>/dev/null || echo 0) servers"
  python3 -c "import json; print('\\n'.join(['  - ' + k for k in json.load(open('$OPENCODE_CONFIG'))['mcp'].keys()]))" 2>/dev/null
}

clear_backups() {
  if [[ -d "$BACKUP_DIR" ]]; then
    count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    if [[ "$count" -gt 0 ]]; then
      rm -rf "$BACKUP_DIR"/*
      mkdir -p "$BACKUP_DIR"
      log_success "Cleared $count backup files"
    else
      log_info "No backups to clear"
    fi
  else
    log_info "No backup directory exists"
  fi
}

case "$1" in
  sync)
    sync_zed
    sync_amp
    sync_claude
    sync_kiro
    sync_kilo
    sync_factory
    sync_trae
    sync_qwen
    sync_opencode
    sync_vibe
    log_success "Done!"
    ;;
  status) status ;;
  backup)
    backup "$ZED_CONFIG" zed
    backup "$AMP_CONFIG" amp
    backup "$CLAUDE_CONFIG" claude
    backup "$KILO_CONFIG" kilo
    backup "$QWEN_CONFIG" qwen
    backup "$VIBE_CONFIG" vibe
    ;;
  clear-backups|clear)
    clear_backups
    ;;
  help|--help|-h)
    echo "Usage: $0 [sync|status|backup|clear-backups]"
    ;;
  *)
    echo "Usage: $0 [sync|status|backup|clear-backups]"
    exit 1
    ;;
esac
