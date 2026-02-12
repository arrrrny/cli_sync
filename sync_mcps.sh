#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/mcp_sync_configs"
BACKUP_DIR="${CONFIG_DIR}/backups"
RAW_MASTER_CONFIG="${CONFIG_DIR}/master_mcp_servers.json"
RENDERED_MASTER_CONFIG="${CONFIG_DIR}/master_mcp_servers.json.rendered"
MASTER_CONFIG="$RAW_MASTER_CONFIG"
[[ -f "$RENDERED_MASTER_CONFIG" ]] && MASTER_CONFIG="$RENDERED_MASTER_CONFIG"

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

ZED_CONFIG="${HOME}/.config/zed/settings.json"
AMP_CONFIG="${HOME}/.config/amp/settings.json"
TRAE_CONFIG="${HOME}/Library/Application Support/Trae/User/mcp.json"
CLAUDE_CONFIG="${HOME}/.claude/settings.json"
KILO_CONFIG="${HOME}/Library/Application Support/Trae/User/globalStorage/kilocode.kilo-code/settings/mcp_settings.json"
FACTORY_CONFIG="/Users/arrrrny/.factory/mcp.json"
OPENCODE_CONFIG="/Users/arrrrny/.config/opencode/opencode.json"
VIBE_CONFIG="${HOME}/.vibe/config.toml"
QWEN_CONFIG="${HOME}/.qwen/settings.json"
CODEBUDDY_CONFIG="${HOME}/.codebuddy/.mcp.json"
ANTIGRAVITY_CONFIG="/Users/arrrrny/.gemini/antigravity/mcp_config.json"
QODER_CONFIG="${HOME}/.qoder.json"
AUGGIE_CONFIG="${HOME}/.augment/settings.json"

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

generate_rendered_config() {
  log_info "Generating rendered config..."
  
  local rendered
  rendered=$(jq '.' "$RAW_MASTER_CONFIG")
  
  local rendered_file
  rendered_file=$(mktemp)
  echo "$rendered" > "$rendered_file"
  
  envsubst < "$rendered_file" > "$RENDERED_MASTER_CONFIG"
  rm "$rendered_file"
  
  MASTER_CONFIG="$RENDERED_MASTER_CONFIG"
  log_success "Rendered config generated"
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

  jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
    . + {"amp.mcpServers": $mcp | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}
  ' "$AMP_CONFIG" > "$AMP_CONFIG.tmp" && mv "$AMP_CONFIG.tmp" "$AMP_CONFIG"

  log_success "Amp synced"
}

sync_claude() {
  log_info "Syncing Claude..."
  backup "$CLAUDE_CONFIG" "claude"

  jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
    . + {mcpServers: $mcp}
  ' "$CLAUDE_CONFIG" > "$CLAUDE_CONFIG.tmp" && mv "$CLAUDE_CONFIG.tmp" "$CLAUDE_CONFIG"

  log_success "Claude synced"
}

sync_kiro() {
  log_info "Syncing Kiro CLI..."
  if [[ -x "$KIRO_BIN" ]]; then
    
    local current_servers
    current_servers=$("$KIRO_BIN" mcp list 2>/dev/null || echo "")
    
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      cmd=$(jq -r ".[\"$name\"].command // empty" "$MASTER_CONFIG" 2>/dev/null)
      args=$(jq -r ".[\"$name\"].args | join(\" \") // \"\"" "$MASTER_CONFIG" 2>/dev/null || echo "")
      
      if [[ -n "$cmd" && "$cmd" != "null" ]]; then
        if ! echo "$current_servers" | grep -q "^${name}$"; then
          log_info "Adding $name to Kiro..."
          timeout 5 "$KIRO_BIN" mcp add "$name" "$cmd" $args 2>/dev/null || true
        fi
      fi
    done < <(jq -r 'keys[]' "$MASTER_CONFIG" 2>/dev/null || echo "")
    
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      if ! jq -e ".[\"$name\"]" "$MASTER_CONFIG" >/dev/null 2>&1; then
        log_info "Removing $name from Kiro..."
        timeout 5 "$KIRO_BIN" mcp remove "$name" 2>/dev/null || true
      fi
    done < <(echo "$current_servers")
    
    log_success "Kiro synced"
  else
    log_info "Kiro CLI not found"
  fi
}

sync_kilo() {
  log_info "Syncing Kilo-code..."
  backup "$KILO_CONFIG" "kilo"

  jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
    . + {mcpServers: $mcp}
  ' "$KILO_CONFIG" > "$KILO_CONFIG.tmp" && mv "$KILO_CONFIG.tmp" "$KILO_CONFIG"

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

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}
    ' "$TRAE_CONFIG" > "$TRAE_CONFIG.tmp" && mv "$TRAE_CONFIG.tmp" "$TRAE_CONFIG"

    log_success "Trae synced"
  else
    log_info "Trae config not found"
  fi
}

sync_qwen() {
  log_info "Syncing Qwen..."
  if [[ -f "$QWEN_CONFIG" ]]; then
    backup "$QWEN_CONFIG" "qwen"

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp}
    ' "$QWEN_CONFIG" > "$QWEN_CONFIG.tmp" && mv "$QWEN_CONFIG.tmp" "$QWEN_CONFIG"

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
        if .env then .environment = .env | del(.env) else . end |
        .command = (if .command | type == "string" then ([.command] + (.args // [])) else .command end) |
        del(.args))
      }) | from_entries
    ' "$MASTER_CONFIG")

    jq --argjson mcp "$opencode_mcp" '. + {$mcp}' "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" && mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"

    log_success "OpenCode synced"
  else
    log_info "OpenCode config not found"
  fi
}

sync_codebuddy() {
  log_info "Syncing Codebuddy..."
  if [[ -f "$CODEBUDDY_CONFIG" ]]; then
    backup "$CODEBUDDY_CONFIG" "codebuddy"

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp}
    ' "$CODEBUDDY_CONFIG" > "$CODEBUDDY_CONFIG.tmp" && mv "$CODEBUDDY_CONFIG.tmp" "$CODEBUDDY_CONFIG"

    log_success "Codebuddy synced"
  else
    log_info "Codebuddy config not found"
  fi
}

sync_antigravity() {
  log_info "Syncing Antigravity..."
  if [[ -f "$ANTIGRAVITY_CONFIG" ]]; then
    backup "$ANTIGRAVITY_CONFIG" "antigravity"

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp}
    ' "$ANTIGRAVITY_CONFIG" > "$ANTIGRAVITY_CONFIG.tmp" && mv "$ANTIGRAVITY_CONFIG.tmp" "$ANTIGRAVITY_CONFIG"

    log_success "Antigravity synced"
  else
    log_info "Antigravity config not found"
  fi
}

sync_vibe() {
  log_info "Syncing Mistral Vibe..."
  if [[ -f "$VIBE_CONFIG" ]]; then
    backup "$VIBE_CONFIG" "vibe"

    {
      echo "[[mcp_servers]]"
      jq -r '.[] | "[[mcp_servers]]\nname = \"\(.key)\"\ntransport = \"stdio\"\ncommand = \"\(.value.command)\"\n\(.value.args | if length > 0 then "args = [" + (map("\"\(.)\"") | join(", ")) + "]\n" else "" end)\(.value.env | if type == "object" then "env = { " + (to_entries | map("\(.key) = \"\(.value)\"") | join(", ") + " }\n" else "" end)"' "$MASTER_CONFIG" 2>/dev/null || true
    } > "$VIBE_CONFIG.tmp" && mv "$VIBE_CONFIG.tmp" "$VIBE_CONFIG"

    log_success "Vibe synced"
  else
    log_info "Vibe config not found"
  fi
}

sync_qoder() {
  log_info "Syncing Qoder..."
  if [[ -f "$QODER_CONFIG" ]]; then
    backup "$QODER_CONFIG" "qoder"

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp}
    ' "$QODER_CONFIG" > "$QODER_CONFIG.tmp" && mv "$QODER_CONFIG.tmp" "$QODER_CONFIG"

    log_success "Qoder synced"
  else
    log_info "Qoder config not found"
  fi
}

sync_auggie() {
  log_info "Syncing Auggie..."
  if [[ -f "$AUGGIE_CONFIG" ]]; then
    backup "$AUGGIE_CONFIG" "auggie"

    jq --argjson mcp "$(jq '.' "$MASTER_CONFIG")" '
      . + {mcpServers: $mcp}
    ' "$AUGGIE_CONFIG" > "$AUGGIE_CONFIG.tmp" && mv "$AUGGIE_CONFIG.tmp" "$AUGGIE_CONFIG"

    log_success "Auggie synced"
  else
    log_info "Auggie config not found"
  fi
}

status() {
  echo -e "${BLUE}=== MCP Status ===${NC}\n"

  local zed_count
  zed_count=$(jq ".context_servers // {} | length" "$ZED_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Zed:${NC} ${zed_count} servers"
  jq -r ".context_servers // {} | keys[] | \"  - \(.)\"" "$ZED_CONFIG" 2>/dev/null || true
  echo ""

  local claude_count
  claude_count=$(jq ".mcpServers // {} | length" "$CLAUDE_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Claude:${NC} ${claude_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$CLAUDE_CONFIG" 2>/dev/null || true
  echo ""

  local amp_count
  amp_count=$(jq ".\"amp.mcpServers\" // {} | length" "$AMP_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Amp:${NC} ${amp_count} servers"
  jq -r ".\"amp.mcpServers\" // {} | keys[] | \"  - \(.)\"" "$AMP_CONFIG" 2>/dev/null || true
  echo ""

  local kilo_count
  kilo_count=$(jq ".mcpServers // {} | length" "$KILO_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Kilo-code:${NC} ${kilo_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$KILO_CONFIG" 2>/dev/null || true
  echo ""

  local qwen_count
  qwen_count=$(jq ".mcpServers // {} | length" "$QWEN_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Qwen:${NC} ${qwen_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$QWEN_CONFIG" 2>/dev/null || true
  echo ""

  local opencode_count
  opencode_count=$(jq ".mcp // {} | length" "$OPENCODE_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}OpenCode:${NC} ${opencode_count} servers"
  jq -r ".mcp // {} | keys[] | \"  - \(.)\"" "$OPENCODE_CONFIG" 2>/dev/null || true
  echo ""

  local codebuddy_count
  codebuddy_count=$(jq ".mcpServers // {} | length" "$CODEBUDDY_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Codebuddy:${NC} ${codebuddy_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$CODEBUDDY_CONFIG" 2>/dev/null || true
  echo ""

  local antigravity_count
  antigravity_count=$(jq ".mcpServers // {} | length" "$ANTIGRAVITY_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Antigravity:${NC} ${antigravity_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$ANTIGRAVITY_CONFIG" 2>/dev/null || true
  echo ""

  local qoder_count
  qoder_count=$(jq ".mcpServers // {} | length" "$QODER_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Qoder:${NC} ${qoder_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$QODER_CONFIG" 2>/dev/null || true
  echo ""

  local auggie_count
  auggie_count=$(jq ".mcpServers // {} | length" "$AUGGIE_CONFIG" 2>/dev/null || echo 0)
  echo -e "${BLUE}Auggie:${NC} ${auggie_count} servers"
  jq -r ".mcpServers // {} | keys[] | \"  - \(.)\"" "$AUGGIE_CONFIG" 2>/dev/null || true
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
    generate_rendered_config
    sync_auggie
    sync_qoder
    sync_zed
    sync_amp
    sync_claude
    sync_factory
    sync_trae
    sync_qwen
    sync_opencode
    sync_codebuddy
    sync_antigravity
    sync_vibe
    sync_kiro
    sync_kilo
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
    backup "$ANTIGRAVITY_CONFIG" antigravity
    backup "$VIBE_CONFIG" vibe
    backup "$QODER_CONFIG" qoder
    backup "$AUGGIE_CONFIG" auggie
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
