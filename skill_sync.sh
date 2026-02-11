#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/skill_sync_configs/backups"
SKILLS_DIR="${SCRIPT_DIR}/skills"
PRIVATE_SKILLS_DIR="${SCRIPT_DIR}/private_skills"

mkdir -p "$BACKUP_DIR" "$SKILLS_DIR" "$PRIVATE_SKILLS_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

ZED_SKILLS_DIR="${HOME}/.config/zed/skills"
CLAIRE_SKILLS_DIR="${HOME}/.claude/skills"
AMP_SKILLS_DIR="${HOME}/.config/amp/skills"
KIRO_SKILLS_DIR="${HOME}/.kiro/skills"
KILO_SKILLS_DIR="${HOME}/.kilocode/skills"
FACTORY_SKILLS_DIR="${HOME}/.factory/skills"
TRAE_SKILLS_DIR="${HOME}/Library/Application Support/Trae/User/skills"
QWEN_SKILLS_DIR="${HOME}/.qwen/skills"
OPENCODE_SKILLS_DIR="${HOME}/.config/opencode/skills"
VIBE_SKILLS_DIR="${HOME}/.vibe/skills"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

backup() {
  local dir=$1 name=$2
  if [[ -d "$dir" ]]; then
    tar -czf "${BACKUP_DIR}/${name}_${TIMESTAMP}.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null || true
  fi
}

sync_zed_skills() {
  log_info "Syncing Zed skills..."
  backup "$ZED_SKILLS_DIR" "zed_skills"

  mkdir -p "$ZED_SKILLS_DIR"

  # Copy all skills from both public and private directories to Zed
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$ZED_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$ZED_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Zed skills synced"
}

sync_claude_skills() {
  log_info "Syncing Claude skills..."
  backup "$CLAIRE_SKILLS_DIR" "claude_skills"

  # Copy all skills from both public and private directories to Claude
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$CLAIRE_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$CLAIRE_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Claude skills synced"
}

sync_amp_skills() {
  log_info "Syncing Amp skills..."
  backup "$AMP_SKILLS_DIR" "amp_skills"

  # Copy all skills from both public and private directories to Amp
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$AMP_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$AMP_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Amp skills synced"
}

sync_kiro_skills() {
  log_info "Syncing Kiro skills..."
  backup "$KIRO_SKILLS_DIR" "kiro_skills"

  # Copy all skills from both public and private directories to Kiro
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$KIRO_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$KIRO_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Kiro skills synced"
}

sync_kilo_skills() {
  log_info "Syncing Kilo skills..."
  backup "$KILO_SKILLS_DIR" "kilo_skills"

  # Copy all skills from both public and private directories to Kilo
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$KILO_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$KILO_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Kilo skills synced"
}

sync_factory_skills() {
  log_info "Syncing Factory skills..."
  backup "$FACTORY_SKILLS_DIR" "factory_skills"

  # Copy all skills from both public and private directories to Factory
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$FACTORY_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$FACTORY_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Factory skills synced"
}

sync_trae_skills() {
  log_info "Syncing Trae skills..."
  backup "$TRAE_SKILLS_DIR" "trae_skills"

  # Copy all skills from both public and private directories to Trae
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$TRAE_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$TRAE_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Trae skills synced"
}

sync_qwen_skills() {
  log_info "Syncing Qwen skills..."
  backup "$QWEN_SKILLS_DIR" "qwen_skills"

  # Copy all skills from both public and private directories to Qwen
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$QWEN_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$QWEN_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Qwen skills synced"
}

sync_opencode_skills() {
  log_info "Syncing OpenCode skills..."
  backup "$OPENCODE_SKILLS_DIR" "opencode_skills"

  # Copy all skills from both public and private directories to OpenCode
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$OPENCODE_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$OPENCODE_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "OpenCode skills synced"
}

sync_vibe_skills() {
  log_info "Syncing Vibe skills..."
  backup "$VIBE_SKILLS_DIR" "vibe_skills"

  # Copy all skills from both public and private directories to Vibe
  if [[ -d "$SKILLS_DIR" ]]; then
    rsync -av --delete "$SKILLS_DIR/" "$VIBE_SKILLS_DIR/" 2>/dev/null || true
  fi

  if [[ -d "$PRIVATE_SKILLS_DIR" ]]; then
    rsync -av "$PRIVATE_SKILLS_DIR/" "$VIBE_SKILLS_DIR/" 2>/dev/null || true
  fi

  log_success "Vibe skills synced"
}

status() {
  echo -e "${BLUE}=== Skills Status ===${NC}\n"

  echo -e "${BLUE}Zed:${NC} $(find "$ZED_SKILLS_DIR" -name "AGENTS.md" -type f 2>/dev/null | wc -l) skill files"
  echo -e "${BLUE}Claude:${NC} $(find "$CLAIRE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Amp:${NC} $(find "$AMP_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Kiro:${NC} $(find "$KIRO_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Kilo:${NC} $(find "$KILO_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Factory:${NC} $(find "$FACTORY_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Trae:${NC} $(find "$TRAE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Qwen:${NC} $(find "$QWEN_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}OpenCode:${NC} $(find "$OPENCODE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"
  echo -e "${BLUE}Vibe:${NC} $(find "$VIBE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) skills"

  echo -e "\n${BLUE}Source Directories:${NC}"
  echo -e "${BLUE}Public Skills:${NC} $(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) directories"
  echo -e "${BLUE}Private Skills:${NC} $(find "$PRIVATE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l) directories"
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
    sync_zed_skills
    sync_claude_skills
    sync_amp_skills
    sync_kiro_skills
    sync_kilo_skills
    sync_factory_skills
    sync_trae_skills
    sync_qwen_skills
    sync_opencode_skills
    sync_vibe_skills
    log_success "Skills sync completed!"
    ;;
  status) status ;;
  backup)
    backup "$ZED_SKILLS_DIR" zed_skills
    backup "$CLAIRE_SKILLS_DIR" claude_skills
    backup "$AMP_SKILLS_DIR" amp_skills
    backup "$KIRO_SKILLS_DIR" kiro_skills
    backup "$KILO_SKILLS_DIR" kilo_skills
    backup "$FACTORY_SKILLS_DIR" factory_skills
    backup "$TRAE_SKILLS_DIR" trae_skills
    backup "$QWEN_SKILLS_DIR" qwen_skills
    backup "$OPENCODE_SKILLS_DIR" opencode_skills
    backup "$VIBE_SKILLS_DIR" vibe_skills
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
