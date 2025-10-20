#!/bin/bash
###############################################################################
# Koinos Node Backup Script
# 
# This script creates a complete backup of a Koinos node's data that can be
# used to bootstrap a new seed node without downloading blocks from scratch.
#
# Usage: ./backup_koinos_node.sh [options]
# Options:
#   -d, --data-dir DIR     Koinos data directory (default: /root/.koinos)
#   -o, --output DIR       Output directory for backup (default: /backup)
#   -n, --name NAME        Backup name prefix (default: koinos-backup)
#   -c, --compress LEVEL   Compression level 1-9 (default: 6)
#   -k, --keep-days DAYS   Keep backups for N days (default: 7)
#   --seed-only            Only backup essential data for seed node
#   --exclude-logs         Exclude log files from backup
#   --exclude-mempool      Exclude mempool data from backup
#   -h, --help             Show this help message
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Default configuration
DATA_DIR="/root/.koinos"
OUTPUT_DIR="/backup"
BACKUP_NAME="koinos-backup"
COMPRESSION_LEVEL=6
KEEP_DAYS=7
EXCLUDE_LOGS=false
EXCLUDE_MEMPOOL=false
SEED_ONLY=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_NAME}_${TIMESTAMP}.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
Koinos Node Backup Script

Usage: $0 [options]

Options:
  -d, --data-dir DIR     Koinos data directory (default: /root/.koinos)
  -o, --output DIR       Output directory for backup (default: /backup)
  -n, --name NAME        Backup name prefix (default: koinos-backup)
  -c, --compress LEVEL   Compression level 1-9 (default: 6)
  -k, --keep-days DAYS   Keep backups for N days (default: 7)
  --seed-only            Only backup essential data for seed node
  --exclude-logs         Exclude log files from backup
  --exclude-mempool      Exclude mempool data from backup
  -h, --help             Show this help message

Example:
  $0 -d /root/.koinos -o /backup -k 14 --exclude-logs
  $0 --seed-only -o /backup  # Minimal seed node backup

Critical directories for SEED NODE:
  - block_store/        (Block data - REQUIRED)
  - chain/              (Chain state - REQUIRED)
  - config.yml          (Node configuration - REQUIRED)

Additional directories for FULL NODE:
  - transaction_store/  (Transaction index - for API queries)
  - account_history/    (Account history - for API queries)
  - contract_meta_store/ (Contract metadata - for API queries)
  - p2p/                (P2P peer data - regenerates automatically)

Optional directories (can be excluded):
  - mempool/            (Temporary transaction pool)
  - logs/               (Log files)
  - block_producer/     (Producer-specific data)

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--data-dir)
                DATA_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -n|--name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            -c|--compress)
                COMPRESSION_LEVEL="$2"
                shift 2
                ;;
            -k|--keep-days)
                KEEP_DAYS="$2"
                shift 2
                ;;
            --seed-only)
                SEED_ONLY=true
                shift
                ;;
            --exclude-logs)
                EXCLUDE_LOGS=true
                shift
                ;;
            --exclude-mempool)
                EXCLUDE_MEMPOOL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if directory exists
check_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        log_error "Directory not found: $dir"
        exit 1
    fi
}

# Create output directory if it doesn't exist
prepare_output_dir() {
    if [ ! -d "$OUTPUT_DIR" ]; then
        log_info "Creating output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
}

# Calculate directory size
get_dir_size() {
    local dir=$1
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "N/A"
    fi
}

# Get available disk space
get_available_space() {
    df -h "$OUTPUT_DIR" | awk 'NR==2 {print $4}'
}

# Build exclude list for tar
build_exclude_list() {
    local excludes=""
    
    if [ "$SEED_ONLY" = true ]; then
        # For seed nodes, exclude everything except essentials
        excludes="$excludes --exclude='account_history'"
        excludes="$excludes --exclude='transaction_store'"
        excludes="$excludes --exclude='contract_meta_store'"
        excludes="$excludes --exclude='p2p'"
        excludes="$excludes --exclude='logs'"
        excludes="$excludes --exclude='mempool'"
        log_info "Seed-only mode: Backing up only block_store, chain, and config.yml"
    else
        if [ "$EXCLUDE_LOGS" = true ]; then
            excludes="$excludes --exclude='logs'"
            log_info "Excluding logs directory"
        fi
        
        if [ "$EXCLUDE_MEMPOOL" = true ]; then
            excludes="$excludes --exclude='mempool'"
            log_info "Excluding mempool directory"
        fi
    fi
    
    # Always exclude temporary and cache files
    excludes="$excludes --exclude='*.tmp' --exclude='*.lock' --exclude='*.pid'"
    
    echo "$excludes"
}

# Create backup
create_backup() {
    local full_backup_path="${OUTPUT_DIR}/${BACKUP_FILE}"
    local exclude_opts=$(build_exclude_list)
    
    log_info "Starting backup..."
    log_info "Data directory: $DATA_DIR"
    log_info "Output file: $full_backup_path"
    log_info "Compression level: $COMPRESSION_LEVEL"
    
    # Show directory sizes
    log_info "Directory sizes:"
    echo "  block_store:        $(get_dir_size "${DATA_DIR}/block_store")"
    echo "  chain:              $(get_dir_size "${DATA_DIR}/chain")"
    echo "  transaction_store:  $(get_dir_size "${DATA_DIR}/transaction_store")"
    echo "  account_history:    $(get_dir_size "${DATA_DIR}/account_history")"
    echo "  contract_meta_store: $(get_dir_size "${DATA_DIR}/contract_meta_store")"
    echo "  p2p:                $(get_dir_size "${DATA_DIR}/p2p")"
    echo "  mempool:            $(get_dir_size "${DATA_DIR}/mempool")"
    echo "  logs:               $(get_dir_size "${DATA_DIR}/logs")"
    
    log_info "Available disk space: $(get_available_space)"
    
    # Create the backup with progress indicator
    log_info "Creating compressed archive..."
    
    # Use pipe to gzip for better compatibility across different tar implementations
    eval tar -cf - \
        -C "$(dirname "$DATA_DIR")" \
        $exclude_opts \
        --exclude='grpc' \
        --exclude='jsonrpc' \
        --exclude='block_producer' \
        "$(basename "$DATA_DIR")" \
        | gzip -${COMPRESSION_LEVEL} > "$full_backup_path"
    
    if [ ${PIPESTATUS[0]} -eq 0 ] && [ ${PIPESTATUS[1]} -eq 0 ]; then
        local backup_size=$(du -sh "$full_backup_path" | cut -f1)
        log_info "Backup created successfully!"
        log_info "Backup file: $full_backup_path"
        log_info "Backup size: $backup_size"
        
        # Create checksum
        log_info "Creating SHA256 checksum..."
        sha256sum "$full_backup_path" > "${full_backup_path}.sha256"
        log_info "Checksum saved to: ${full_backup_path}.sha256"
        
        # Create metadata file
        create_metadata "$full_backup_path"
    else
        log_error "Backup failed!"
        exit 1
    fi
}

# Create metadata file
create_metadata() {
    local backup_path=$1
    local metadata_file="${backup_path}.metadata"
    
    log_info "Creating metadata file..."
    
    cat > "$metadata_file" << EOF
Koinos Node Backup Metadata
============================

Backup Information:
-------------------
Backup File: $(basename "$backup_path")
Backup Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Backup Size: $(du -sh "$backup_path" | cut -f1)
Compression: gzip level $COMPRESSION_LEVEL

Source Information:
-------------------
Data Directory: $DATA_DIR
Hostname: $(hostname)
Backup Mode: $([ "$SEED_ONLY" = true ] && echo "SEED NODE ONLY" || echo "FULL NODE")

Included Directories:
---------------------
$(if [ "$SEED_ONLY" = true ]; then
    echo "block_store/        - Block data (REQUIRED FOR SEED)"
    echo "chain/              - Chain state (REQUIRED FOR SEED)"
    echo "config.yml          - Configuration (REQUIRED FOR SEED)"
else
    echo "block_store/        - Block data"
    echo "chain/              - Chain state"
    echo "transaction_store/  - Transaction index"
    echo "account_history/    - Account history"
    echo "contract_meta_store/ - Contract metadata"
    echo "p2p/                - P2P data"
    echo "config.yml          - Configuration"
fi)

Excluded:
---------
Seed-Only Mode: $SEED_ONLY
Logs: $EXCLUDE_LOGS
Mempool: $EXCLUDE_MEMPOOL

Restore Instructions:
---------------------
1. Extract archive: tar -xzf $(basename "$backup_path") -C /
2. Verify ownership: chown -R root:root /root/.koinos
3. Start Koinos node: docker-compose up -d
4. Monitor logs: docker-compose logs -f

Checksum:
---------
$(cat "${backup_path}.sha256" 2>/dev/null || echo "Checksum file not found")

EOF
    
    log_info "Metadata saved to: $metadata_file"
}

# Clean old backups
cleanup_old_backups() {
    if [ $KEEP_DAYS -gt 0 ]; then
        log_info "Cleaning up backups older than $KEEP_DAYS days..."
        
        find "$OUTPUT_DIR" -name "${BACKUP_NAME}_*.tar.gz" -type f -mtime +$KEEP_DAYS -delete
        find "$OUTPUT_DIR" -name "${BACKUP_NAME}_*.sha256" -type f -mtime +$KEEP_DAYS -delete
        find "$OUTPUT_DIR" -name "${BACKUP_NAME}_*.metadata" -type f -mtime +$KEEP_DAYS -delete
        
        log_info "Cleanup completed"
    fi
}

# List recent backups
list_backups() {
    log_info "Recent backups in $OUTPUT_DIR:"
    ls -lh "$OUTPUT_DIR"/${BACKUP_NAME}_*.tar.gz 2>/dev/null | tail -5 || log_warn "No backups found"
}

# Main function
main() {
    echo "================================================"
    echo "  Koinos Node Backup Script"
    echo "================================================"
    echo ""
    
    parse_args "$@"
    
    # Validate directories
    check_directory "$DATA_DIR"
    prepare_output_dir
    
    # Check for required files
    if [ ! -f "${DATA_DIR}/config.yml" ]; then
        log_warn "config.yml not found in $DATA_DIR"
    fi
    
    # Create backup
    create_backup
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Show recent backups
    list_backups
    
    echo ""
    log_info "Backup process completed successfully!"
    echo "================================================"
}

# Run main function
main "$@"
