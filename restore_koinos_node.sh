#!/bin/bash
###############################################################################
# Koinos Node Restore Script
#
# This script restores a Koinos node from a backup created by backup_koinos_node.sh
#
# Usage: ./restore_koinos_node.sh <backup_file> [options]
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show help
show_help() {
    cat << EOF
Koinos Node Restore Script

Usage: $0 <backup_file> [options]

Options:
  -t, --target DIR       Target directory (default: /root/.koinos)
  -v, --verify           Verify backup checksum before restore
  -b, --backup-existing  Backup existing data before restore
  -h, --help             Show this help message

Example:
  $0 koinos-backup_20241020_120000.tar.gz --verify --backup-existing

EOF
}

# Main restore function
restore_backup() {
    local backup_file=$1
    local target_dir=${2:-/root/.koinos}
    local verify=${3:-false}
    local backup_existing=${4:-false}
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_info "Backup file: $backup_file"
    log_info "Target directory: $target_dir"
    
    # Verify checksum if requested
    if [ "$verify" = true ]; then
        log_info "Verifying backup checksum..."
        if [ -f "${backup_file}.sha256" ]; then
            sha256sum -c "${backup_file}.sha256"
            log_info "Checksum verification passed!"
        else
            log_warn "Checksum file not found, skipping verification"
        fi
    fi
    
    # Backup existing data if requested
    if [ "$backup_existing" = true ] && [ -d "$target_dir" ]; then
        local old_backup="${target_dir}_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing data to: $old_backup"
        mv "$target_dir" "$old_backup"
    fi
    
    # Extract backup
    log_info "Extracting backup..."
    tar -xzf "$backup_file" -C / --no-same-owner
    
    # Set proper permissions
    log_info "Setting proper permissions..."
    chown -R root:root "$target_dir" 2>/dev/null || log_warn "Could not set ownership (may need sudo)"
    
    log_info "Restore completed successfully!"
    log_info "You can now start your Koinos node"
    
    # Show metadata if available
    if [ -f "${backup_file}.metadata" ]; then
        echo ""
        log_info "Backup metadata:"
        cat "${backup_file}.metadata"
    fi
}

# Parse arguments and restore
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

BACKUP_FILE=$1
VERIFY=false
BACKUP_EXISTING=false
TARGET_DIR="/root/.koinos"

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verify) VERIFY=true; shift ;;
        -b|--backup-existing) BACKUP_EXISTING=true; shift ;;
        -t|--target) TARGET_DIR="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

restore_backup "$BACKUP_FILE" "$TARGET_DIR" "$VERIFY" "$BACKUP_EXISTING"
