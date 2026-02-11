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
CODEBUDDY_CONFIG="${HOME}/.codebuddy/.mcp.json"

KIRO_BIN="/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

backup() {
  local file=$1 name=$2
  [[ -f "$file" ]] && cp "$file" "${BACKUP_DIR}/${name}_${TIMESTAMP}.json"
}

strip_json_comments() {
  sed -e 's|//.*$||g' -e 's|/\*.*\*/||g' "$1"
}

sync_zed() {
  log_info "Syncing Zed..."
  backup "$ZED_CONFIG" "zed"
  
  local zed_content
  zed_content=$(strip_json_comments "$ZED_CONFIG")
  
  jq -s '.[0] * {context_servers: .[1]}' <(echo "$zed_content") "$MASTER_CONFIG" 2>/dev/null > "$ZED_CONFIG.tmp" && mv "$ZED_CONFIG.tmp" "$ZED_CONFIG"
  
  log_success "Zed synced"
}

sync_amp() {
  log_info "Syncing Amp..."
  backup "$AMP_CONFIG" "amp"
  
  jq -s '.[0] * {".mcpServers": .[1] | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}' "$AMP_CONFIG" "$MASTER_CONFIG" > "$AMP_CONFIG.tmp" && mv "$AMP_CONFIG.tmp" "$AMP_CONFIG"
  
  log_success "Amp synced"
}

sync_claude() {
  log_info "Syncing Claude..."
  backup "$CLAUDE_CONFIG" "claude"
  
  jq -s '.[0] * {mcpServers: .[1]}' "$CLAUDE_CONFIG" "$MASTER_CONFIG" > "$CLAUDE_CONFIG.tmp" && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"
  
  log_success "Claude synced"
}

sync_kiro() {
  log_info "Syncing Kiro CLI..."
  if [[ -x "$KIRO_BIN" ]]; then
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      cmd=$(jq -r ".[\"$name\"].command // empty" "$MASTER_CONFIG" 2>/dev/null)
      args=$(jq -r ".[\"$name\"].args | join(\" \") // \"\"" "$MASTER_CONFIG" 2>/dev/null || echo "")
      if [[ -n "$cmd" && "$cmd" != "null" ]]; then
        if ! "$KIRO_BIN" mcp list 2>/dev/null | grep -q "^${name}$"; then
          log_info "Adding $name to Kiro..."
          timeout 5 "$KIRO_BIN" mcp add "$name" "$cmd" $args 2>/dev/null || true
        fi
      fi
    done < <(jq -r 'keys[]' "$MASTER_CONFIG" 2>/dev/null || echo "")
    log_success "Kiro synced"
  else
    log_info "Kiro CLI not found"
  fi
}

sync_kilo() {
  log_info "Syncing Kilo-code..."
  backup "$KILO_CONFIG" "kilo"
  
  jq -s '.[0] as $kilo | .[1] as $mcp | if $kilo.mcpServers == null then $kilo * {mcpServers: $mcp} else $kilo * {mcpServers: $mcp} end' "$KILO_CONFIG" "$MASTER_CONFIG" > "$KILO_CONFIG.tmp" && mv "$KILO_CONFIG.tmp" "$KILO_CONFIG"
  
  log_success "Kilo synced"
}

sync_factory() {
  log_info "Syncing Factory-droid..."
  if [[ -f "$FACTORY_CONFIG" ]]; then
    backup "$FACTORY_CONFIG" "factory"
    cp "$MASTER_CONFIG" "$FACTORY_CONFIG"
    log_success "Factory-droid synced"
  else
    log_info "Factory-droid config not found"
  fi
}

sync_trae() {
  log_info "Syncing Trae..."
  if [[ -f "$TRAE_CONFIG" ]]; then
    backup "$TRAE_CONFIG" "trae"
    
    jq -s '.[0] * {mcpServers: .[1] | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}' "$TRAE_CONFIG" "$MASTER_CONFIG" > "$TRAE_CONFIG.tmp" && mv "$TRAE_CONFIG.tmp" "$TRAE_CONFIG"
    
    log_success "Trae synced"
  else
    log_info "Trae config not found"
  fi
}

sync_qwen() {
  log_info "Syncing Qwen..."
  if [[ -f "$QWEN_CONFIG" ]]; then
    backup "$QWEN_CONFIG" "qwen"
    
    jq -s '.[0] * {mcpServers: .[1]}' "$QWEN_CONFIG" "$MASTER_CONFIG" > "$QWEN_CONFIG.tmp" && mv "$QWEN_CONFIG.tmp" "$QWEN_CONFIG"
    
    log_success "Qwen synced"
  else
    log_info "Qwen config not found"
  fi
}

sync_opencode() {
  log_info "Syncing OpenCode..."
  if [[ -f "$OPENCODE_CONFIG" ]]; then
    backup "$OPENCODE_CONFIG" "opencode"
    
    local opencode_mcp
    opencode_mcp=$(jq -r '
      to_entries | map({
        key: .key,
        value: (.value + {enabled: true, type: "local"} | 
        .command = (if .command | type == "string" then ([.command] + (.args // [])) else .command end) |
        del(.args))
      }) | from_entries
    ' "$MASTER_CONFIG")
    
    jq --argjson mcp "$opencode_mcp" '. * {$mcp}' "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" && mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"
    
    log_success "OpenCode synced"
  else
    log_info "OpenCode config not found"
  fi
}

sync_codebuddy() {
  log_info "Syncing Codebuddy..."
  if [[ -f "$CODEBUDDY_CONFIG" ]]; then
    backup "$CODEBUDDY_CONFIG" "codebuddy"
    
    jq -s '.[0] * {mcpServers: .[1]}' "$CODEBUDDY_CONFIG" "$MASTER_CONFIG" > "$CODEBUDDY_CONFIG.tmp" && mv "$CODEBUDDY_CONFIG.tmp" "$CODEBUDDY_CONFIG"
    
    log_success "Codebuddy synced"
  else
    log_info "Codebuddy config not found"
  fi
}

sync_vibe() {
  log_info "Syncing Mistral Vibe..."
  if [[ -f "$VIBE_CONFIG" ]]; then
    backup "$VIBE_CONFIG" "vibe"
    
    local header
    header=$(sed -n '/^\[\[mcp_servers\]\]/p;1,/^[[mcp_servers]]/p' "$VIBE_CONFIG" | head -1)
    [[ -z "$header" ]] && header=$(grep -v '^$' "$VIBE_CONFIG" | head -1 || echo "")
    
    {
      echo "$header"
      jq -r '.[] | "[[mcp_servers]]\nname = \"\(.key)\"\ntransport = \"stdio\"\ncommand = \"\(.value.command)\"\n\(.value.args | if length > 0 then "args = [" + (map("\"\(.)\"") | join(", ")) + "]\n" else "" end)\(.value.env | if type == "object" then "env = { " + (to_entries | map("\(.key) = \"\(.value)\"") | join(", ") + " }\n" else "" end)"' "$MASTER_CONFIG" 2>/dev/null || true
    } > "$VIBE_CONFIG.tmp" && mv "$VIBE_CONFIG.tmp" "$VIBE_CONFIG"
    
    log_success "Vibe synced"
  else
    log_info "Vibe config not found"
  fi
}

status() {
  echo -e "${BLUE}=== MCP Status ===${NC}\n"

  echo -e "${BLUE}Zed:${NC} $(jq '(.context_servers // {}) | length' "$ZED_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.context_servers // {}) | keys[] | "  - \(.)"' "$ZED_CONFIG" 2>/dev/null || true
  echo ""

  echo -e "${BLUE}Claude:${NC} $(jq '(.mcpServers // {}) | length' "$CLAUDE_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.mcpServers // {}) | keys[] | "  - \(.)"' "$CLAUDE_CONFIG" 2>/dev/null || true
  echo ""

  echo -e "${BLUE}Amp:${NC} $(jq '(.["amp.mcpServers"] // {}) | length' "$AMP_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.["amp.mcpServers"] // {}) | keys[] | "  - \(.)"' "$AMP_CONFIG" 2>/dev/null || true
  echo ""

  echo -e "${BLUE}Kilo-code:${NC} $(jq '(.mcpServers // {}) | length' "$KILO_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.mcpServers // {}) | keys[] | "  - \(.)"' "$KILO_CONFIG" 2>/dev/null || true
  echo ""

  echo -e "${BLUE}Qwen:${NC} $(jq '(.mcpServers // {}) | length' "$QWEN_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.mcpServers // {}) | keys[] | "  - \(.)"' "$QWEN_CONFIG" 2>/dev/null || true
  echo ""

  echo -e "${BLUE}OpenCode:${NC} $(jq '(.mcp // {}) | length' "$OPENCODE_CONFIG" 2>/dev/null || echo 0) servers"
  jq -r '(.mcp // {}) | keys[] | "  - \(.)"' "$OPENCODE_CONFIG" 2>/dev/null || true
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
    sync_codebuddy
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
    backup "$CODEBUDDY_CONFIG" codebuddy
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
