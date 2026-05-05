#!/usr/bin/env bash
# Core functions for CLI Sync

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logger functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check for required tools
check_dependencies() {
    local deps=("jq" "rsync" "sed")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_error "Required dependency '$dep' is not installed."
            exit 1
        fi
    done
}

# Variable substitution fallback for envsubst
substitute_env() {
    if command -v envsubst >/dev/null 2>&1; then
        envsubst
    else
        # Perl is standard on macOS and handles basic ${VAR} substitution
        perl -pe 's/\$\{([^}]+)\}/$ENV{$1} || $&/ge'
    fi
}

# Environment loader
load_env() {
    local dir="$1"
    # Export variables so they are available to sub-processes (like perl/envsubst)
    set -a
    for f in ".env" ".zshenv"; do
        if [[ -f "$dir/$f" ]]; then
            # shellcheck source=/dev/null
            source "$dir/$f"
        fi
        if [[ -f "$HOME/$f" ]]; then
            # shellcheck source=/dev/null
            source "$HOME/$f"
        fi
    done
    set +a
}

# Backup utility
backup_file() {
    local file="$1"
    local name="$2"
    local backup_dir="$3"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")

    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        cp "$file" "${backup_dir}/${name}_${timestamp}.json.bak"
    fi
}

# App detection logic
is_installed() {
    local path="$1"
    local binary="${2:-}"

    # Check for config path existence
    if [[ -e "$path" ]]; then
        return 0
    fi

    # Optionally check for binary existence
    if [[ -n "$binary" ]] && command -v "$binary" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Master config rendering
render_master_config() {
    local raw_config="$1"
    local rendered_config="$2"

    if [[ ! -f "$raw_config" ]]; then
        log_error "Master config not found: $raw_config"
        return 1
    fi

    log_info "Rendering master configuration..."
    substitute_env < "$raw_config" > "$rendered_config"
    log_success "Configuration rendered to $(basename "$rendered_config")"
}
