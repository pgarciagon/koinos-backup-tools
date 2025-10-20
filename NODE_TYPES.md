# Koinos Node Types & Backup Requirements

## 🌱 Seed Node (Minimal)

**Purpose**: Help other nodes discover peers and bootstrap into the network

### Required Data:
- ✅ `block_store/` - Block data for syncing peers
- ✅ `chain/` - Chain state for validation
- ✅ `config.yml` - Node configuration

### Backup Command:
```bash
./backup_koinos_node.sh --seed-only
```

### Restore Size:
- **Fresh**: ~500 MB - 1 GB
- **6 months**: ~10-15 GB  
- **1 year+**: ~20-30 GB

### Use Cases:
- Bootstrap new nodes
- P2P network health
- Fast sync for other nodes
- No API queries needed

---

## 🔌 API Node (Full)

**Purpose**: Serve all API queries (accounts, transactions, contracts)

### Required Data:
- ✅ `block_store/` - Block data
- ✅ `chain/` - Chain state
- ✅ `transaction_store/` - Transaction index
- ✅ `account_history/` - Account transaction history
- ✅ `contract_meta_store/` - Smart contract metadata
- ✅ `config.yml` - Configuration

### Optional Data:
- 🔷 `p2p/` - P2P peer data (regenerates)
- 🔷 `mempool/` - Temporary pool (regenerates)
- ❌ `logs/` - Not needed for restore

### Backup Command:
```bash
./backup_koinos_node.sh
# or with exclusions:
./backup_koinos_node.sh --exclude-logs --exclude-mempool
```

### Restore Size:
- **Fresh**: ~1-2 GB
- **6 months**: ~20-30 GB
- **1 year+**: ~50-80 GB

### Use Cases:
- Public API endpoints
- DApp backends
- Block explorers
- Full transaction history queries

---

## 🔨 Block Producer

**Purpose**: Produce blocks and participate in consensus

### Required Data:
- ✅ `block_store/` - Block data
- ✅ `chain/` - Chain state
- ✅ `config.yml` - Configuration (with producer settings)
- ⭐ `block_producer/` - Producer-specific data (signing keys, etc.)

### Backup Command:
```bash
# Full backup including producer data
./backup_koinos_node.sh
```

### Additional Requirements:
- Must have producer private key configured
- Must be registered as a producer on-chain
- Requires staking

---

## 📊 Comparison Table

| Feature | Seed Node | API Node | Block Producer |
|---------|-----------|----------|----------------|
| Block Data | ✅ | ✅ | ✅ |
| Chain State | ✅ | ✅ | ✅ |
| Account History | ❌ | ✅ | Optional |
| Transaction Store | ❌ | ✅ | Optional |
| Contract Metadata | ❌ | ✅ | Optional |
| Producer Data | ❌ | ❌ | ✅ |
| Backup Size | Smallest | Medium | Medium-Large |
| API Queries | No | Yes | Optional |
| Block Production | No | No | Yes |

---

## 🚀 Quick Start Examples

### Create a Seed Node Backup
```bash
# Minimal backup for seed node
./backup_koinos_node.sh --seed-only -o /backup

# Expected size: ~60% smaller than full backup
# Contains: block_store, chain, config.yml only
```

### Create a Full Node Backup
```bash
# Complete backup with all data
./backup_koinos_node.sh -o /backup

# Expected size: Full blockchain data
# Contains: All stores + configuration
```

### Create a Backup Without Logs
```bash
# Save space by excluding logs
./backup_koinos_node.sh --exclude-logs --exclude-mempool -o /backup

# Expected size: ~10-20% smaller
# Logs and mempool regenerate automatically
```

---

## 🔄 Restore Scenarios

### Scenario 1: New Seed Node
```bash
# Use seed-only backup
./restore_koinos_node.sh koinos-backup-seed_20241020.tar.gz --verify

# Result: Fast restore, minimal data, ready to serve peers
```

### Scenario 2: New API Node
```bash
# Use full backup
./restore_koinos_node.sh koinos-backup_20241020.tar.gz --verify

# Result: Complete restore, ready to serve API queries
```

### Scenario 3: Migrate Producer
```bash
# Full backup from old server
ssh old-server './backup_koinos_node.sh -o /tmp'

# Transfer to new server
scp old-server:/tmp/koinos-backup_*.tar.gz new-server:/tmp/

# Restore on new server
ssh new-server './restore_koinos_node.sh /tmp/koinos-backup_*.tar.gz --verify'

# Update producer configuration with signing keys
# Start services
```

---

## 💡 Best Practices

### For Seed Nodes:
1. Use `--seed-only` flag for smaller, faster backups
2. Backup daily (small size makes it feasible)
3. Keep 7-14 days of backups
4. No need for transaction/account history

### For API Nodes:
1. Use full backup with all stores
2. Backup less frequently (larger size)
3. Keep 3-7 days of backups
4. Test API queries after restore

### For Block Producers:
1. Always include producer data
2. Backup before/after key operations
3. Secure backups with encryption
4. Test failover procedures regularly

---

## 📦 Storage Planning

### Seed Node Backups:
```bash
# Daily for 7 days
7 backups × 15 GB = 105 GB storage needed
```

### API Node Backups:
```bash
# Daily for 3 days + Weekly for 4 weeks
(3 × 50 GB) + (4 × 50 GB) = 350 GB storage needed
```

### Recommended:
- **Local**: Fast restore (same datacenter)
- **Remote**: Disaster recovery (different location)
- **Cloud**: Long-term archival (cost-effective)

---

## 🎯 Decision Guide

**Choose Seed-Only Backup If:**
- ✅ You only need P2P bootstrapping
- ✅ No API queries required
- ✅ Want smaller backup sizes
- ✅ Want faster backup/restore times
- ✅ Storage space is limited

**Choose Full Backup If:**
- ✅ You serve API requests
- ✅ Need transaction history
- ✅ Need account history
- ✅ Run a block explorer
- ✅ Storage space is available

---

## 📞 Support

For more information:
- [Koinos Documentation](https://docs.koinos.io)
- [Koinos Discord](https://discord.gg/koinos)
- [Koinos GitHub](https://github.com/koinos)
