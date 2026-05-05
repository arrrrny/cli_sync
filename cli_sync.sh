#!/usr/bin/env bash
# CLI Sync - Unified Auto-Detecting Sync Tool
# Consolidates MCP and Skills syncing for all AI CLIs/Editors.

set -euo pipefail

# --- 1. Colors & Logging ---
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- 2. Environment & Dependencies ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

load_env() {
    set -a
    for f in ".env" ".zshenv"; do
        [[ -f "$SCRIPT_DIR/$f" ]] && source "$SCRIPT_DIR/$f"
        [[ -f "$HOME/$f" ]] && source "$HOME/$f"
    done
    set +a
}

check_deps() {
    for dep in jq rsync sed; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_error "Missing dependency: $dep. Please install it."
            exit 1
        fi
    done
}

substitute_env() {
    if command -v envsubst >/dev/null 2>&1; then
        envsubst
    else
        perl -pe 's/\$\{([^}]+)\}/$ENV{$1} || $&/ge'
    fi
}

# --- 3. Configuration ---
load_env
check_deps

# Master Paths
RAW_MASTER="${SCRIPT_DIR}/mcp_sync_configs/master_mcp_servers.json"
RENDERED_MASTER="${SCRIPT_DIR}/mcp_sync_configs/master_mcp_servers.json.rendered"
SKILLS_SRC="${SCRIPT_DIR}/skills"
PRIV_SKILLS_SRC="${SCRIPT_DIR}/private_skills"
BACKUP_DIR="${SCRIPT_DIR}/backups"

# App Definitions (Name | Config Path | Skills Dir | Format)
# Format types: standard, opencode, zed, amp, vibe
APPS=(
    "Claude      | ${HOME}/.claude.json                   | ${HOME}/.claude/skills         | standard"
    "OpenCode    | ${HOME}/.config/opencode/opencode.json         | ${HOME}/.config/opencode/skills | opencode"
    "Zed         | ${HOME}/.config/zed/settings.json              | ${HOME}/.config/zed/skills     | zed"
    "Trae        | ${HOME}/Library/Application Support/Trae/User/mcp.json | ${HOME}/Library/Application Support/Trae/User/skills | standard"
    "Amp         | ${HOME}/.config/amp/settings.json              | ${HOME}/.config/amp/skills      | amp"
    "Junie       | ${HOME}/.junie/mcp/mcp.json                    | ${HOME}/.junie/skills          | standard"
    "Vibe        | ${HOME}/.vibe/config.toml                      | ${HOME}/.vibe/skills           | vibe"
    "Qwen        | ${HOME}/.qwen/settings.json                    | ${HOME}/.qwen/skills           | standard"
    "Antigravity | ${HOME}/.gemini/antigravity/mcp_config.json    | ${HOME}/.gemini/skills         | standard"
)

# --- 4. Core Logic ---

backup() {
    local file=$1 name=$2
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "${BACKUP_DIR}/${name}_$(date +%Y%m%d_%H%M%S).bak"
    fi
}

# MCP Transformation Functions
transform_opencode() {
    jq -r 'to_entries | map({
        key: .key,
        value: (.value + {enabled: true} |
        if .type == "http" then . + {type: "remote"} else (. + {type: "local"} | if .env then .environment = .env | del(.env) else . end | .command = (if .command | type == "string" then ([.command] + (.args // [])) else .command end) | del(.args)) end)
    }) | from_entries' "$1"
}

transform_amp() {
    jq --argjson mcp "$(jq '.' "$1")" '. + {"amp.mcpServers": $mcp | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}'
}

# --- 5. Execution ---

sync_app() {
    local name=$(echo "$1" | cut -d'|' -f1 | xargs)
    local config=$(echo "$1" | cut -d'|' -f2 | xargs)
    local skills=$(echo "$1" | cut -d'|' -f3 | xargs)
    local format=$(echo "$1" | cut -d'|' -f4 | xargs)

    if [[ ! -e "$config" && ! -d "$skills" ]]; then
        return 0 # Skip if not installed
    fi

    log_info "Detected ${name}. Syncing..."
    backup "$config" "$name"

    # 1. Sync MCP if config exists
    if [[ -f "$config" ]]; then
        case "$format" in
            standard)
                jq --argjson mcp "$(jq '.' "$RENDERED_MASTER")" '. + {mcpServers: $mcp}' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
                ;;
            opencode)
                local mcp_json=$(transform_opencode "$RENDERED_MASTER")
                jq --argjson mcp "$mcp_json" '. + {mcp: $mcp}' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
                ;;
            zed)
                local clean=$(sed -e 's|//.*$||g' -e 's|/\*.*\*/||g' "$config")
                jq -s '.[0] * {context_servers: .[1]}' <(echo "$clean") "$RENDERED_MASTER" 2>/dev/null > "$config.tmp" && mv "$config.tmp" "$config"
                ;;
            amp)
                jq --argjson mcp "$(jq '.' "$RENDERED_MASTER")" '. + {"amp.mcpServers": $mcp | to_entries | map({key: .key, value: (.value + {enabled: true})}) | from_entries}' "$config" > "$config.tmp" && mv "$config.tmp" "$config"
                ;;
            vibe)
                # Specialized Vibe TOML output
                {
                    echo "# Vibe MCP Config"
                    jq -r 'to_entries[] | "[[mcp_servers]]\nname = \"" + .key + "\"\ncommand = \"" + .value.command + "\"\nargs = " + (.value.args | tojson) + "\n"' "$RENDERED_MASTER"
                } > "$config"
                ;;
        esac
    fi

    # 2. Sync Skills if target dir exists (or we want to create it)
    if [[ -n "$skills" ]]; then
        mkdir -p "$skills"
        [[ -d "$SKILLS_SRC" ]] && rsync -av --delete "$SKILLS_SRC/" "$skills/" 2>/dev/null || true
        [[ -d "$PRIV_SKILLS_SRC" ]] && rsync -av "$PRIV_SKILLS_SRC/" "$skills/" 2>/dev/null || true
    fi

    log_success "${name} sync complete."
}

main() {
    local cmd="${1:-sync}"

    case "$cmd" in
        sync)
            log_info "Scanning for installed AI CLIs..."
            mkdir -p "$(dirname "$RENDERED_MASTER")"
            substitute_env < "$RAW_MASTER" > "$RENDERED_MASTER"

            for app in "${APPS[@]}"; do
                sync_app "$app"
            done
            log_success "All systems synced."
            ;;
        status)
            echo -e "${BLUE}=== Installed CLIs ===${NC}"
            for app in "${APPS[@]}"; do
                local name=$(echo "$app" | cut -d'|' -f1 | xargs)
                local config=$(echo "$app" | cut -d'|' -f2 | xargs)
                if [[ -e "$config" ]]; then
                    echo -e "${GREEN}[INSTALLED]${NC} $name"
                else
                    echo -e "${RED}[NOT FOUND]${NC} $name"
                fi
            done
            ;;
        trust)
            local dir="$(pwd)"
            log_info "Adding ${dir} to trusted directories for Claude and OpenCode..."
            # Claude
            local c_conf="${HOME}/.claude/settings.json"
            [[ -f "$c_conf" ]] && jq --arg d "$dir" '."trusted-directories" = (."trusted-directories" // []) + [$d] | .["trusted-directories"] |= unique' "$c_conf" > "$c_conf.tmp" && mv "$c_conf.tmp" "$c_conf"
            # OpenCode
            local o_conf="${HOME}/.config/opencode/opencode.json"
            [[ -f "$o_conf" ]] && jq --arg d "$dir" '.trustedDirectories = (.trustedDirectories // []) + [$d] | .trustedDirectories |= unique' "$o_conf" > "$o_conf.tmp" && mv "$o_conf.tmp" "$o_conf"
            log_success "Trust updated."
            ;;
        clear)
            rm -rf "$BACKUP_DIR"/*
            log_success "Backups cleared."
            ;;
        *)
            echo "Usage: $0 [sync|status|trust|clear]"
            exit 1
            ;;
    esac
}

main "$@"
