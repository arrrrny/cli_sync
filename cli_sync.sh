#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
  echo "Usage: $0 [sync|mcp|skills|status|backup|clear-backups|trust] [--mcp|--skills]"
  echo ""
  echo "Commands:"
  echo "  sync           Sync both MCP and Skills (default)"
  echo "  mcp            Sync only MCP configurations"
  echo "  skills         Sync only Skills"
  echo "  status         Show status of both MCP and Skills"
  echo "  backup         Backup both MCP and Skills configurations"
  echo "  clear-backups  Clear backup files"
  echo "  trust          Add trusted directories to all CLIs"
  echo ""
  echo "Options:"
  echo "  --mcp          Only sync MCP configurations (alternative to 'mcp' command)"
  echo "  --skills       Only sync Skills (alternative to 'skills' command)"
}

# Default behavior is to sync both
SYNC_MCP=true
SYNC_SKILLS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    sync)
      ;;
    mcp)
      SYNC_SKILLS=false
      ;;
    skills)
      SYNC_MCP=false
      ;;
    status)
      log_info "Checking MCP status..."
      bash "$SCRIPT_DIR/mcp_sync.sh" status

      log_info "Checking Skills status..."
      bash "$SCRIPT_DIR/skill_sync.sh" status
      exit 0
      ;;
    backup)
      log_info "Backing up MCP configurations..."
      bash "$SCRIPT_DIR/mcp_sync.sh" backup

      log_info "Backing up Skills configurations..."
      bash "$SCRIPT_DIR/skill_sync.sh" backup
      log_success "Backup completed!"
      exit 0
      ;;
    clear-backups|clear)
      log_info "Clearing MCP backups..."
      bash "$SCRIPT_DIR/mcp_sync.sh" clear-backups

      log_info "Clearing Skills backups..."
      bash "$SCRIPT_DIR/skill_sync.sh" clear-backups
      log_success "Backups cleared!"
      exit 0
      ;;
    trust)
      log_info "Adding trusted directories to all CLIs..."
      bash "$SCRIPT_DIR/skill_sync.sh" trust
      log_success "Trusted directories added!"
      exit 0
      ;;
    help|--help|-h)
      show_help
      exit 0
      ;;
    --mcp)
      SYNC_SKILLS=false
      ;;
    --skills)
      SYNC_MCP=false
      ;;
    *)
      log_error "Unknown command: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# Execute sync based on flags
if [ "$SYNC_MCP" = true ]; then
  log_info "Syncing MCP configurations..."
  bash "$SCRIPT_DIR/mcp_sync.sh" sync
fi

if [ "$SYNC_SKILLS" = true ]; then
  log_info "Syncing Skills..."
  bash "$SCRIPT_DIR/skill_sync.sh" sync
fi

log_success "CLI sync completed!"
