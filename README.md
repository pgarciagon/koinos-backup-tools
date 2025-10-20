# Koinos Node Backup Tools

Complete backup and restore solution for Koinos blockchain nodes.

## 📋 Overview

This toolkit provides scripts to create complete backups of Koinos nodes that can be used to bootstrap new seed nodes without re-downloading the entire blockchain from scratch.

## ✨ Features

- ✅ **Complete node backup** - All critical data for seed node operation
- ✅ **Compressed archives** - Configurable gzip compression levels
- ✅ **Checksum verification** - SHA256 checksums for data integrity
- ✅ **Metadata tracking** - Backup information and restore instructions
- ✅ **Automatic cleanup** - Remove old backups automatically
- ✅ **Flexible excludes** - Skip logs, mempool, or other optional data
- ✅ **Easy restore** - Simple one-command restoration

## 🚀 Quick Start

### Installation

```bash
# Clone or copy the scripts to your server
cd /root/scripts
chmod +x backup_koinos_node.sh restore_koinos_node.sh
```

### Create a Backup

```bash
# Basic backup (uses defaults)
./backup_koinos_node.sh

# Backup with custom options
./backup_koinos_node.sh \
  --data-dir /root/.koinos \
  --output /backup \
  --compress 9 \
  --keep-days 14 \
  --exclude-logs
```

### Restore a Backup

```bash
# Basic restore
./restore_koinos_node.sh koinos-backup_20241020_120000.tar.gz

# Restore with verification and existing backup
./restore_koinos_node.sh koinos-backup_20241020_120000.tar.gz \
  --verify \
  --backup-existing
```

## 📦 What Gets Backed Up

### Critical Data (Always Included)

| Directory | Description | Size | Required |
|-----------|-------------|------|----------|
| `block_store/` | Block data | Large | ✅ Yes |
| `chain/` | Chain state and headers | Medium | ✅ Yes |
| `transaction_store/` | Transaction index | Medium | ⭐ Recommended |
| `account_history/` | Account transaction history | Medium | ⭐ Recommended |
| `contract_meta_store/` | Smart contract metadata | Small | ⭐ Recommended |
| `p2p/` | Peer connection data | Small | 🔷 Optional |
| `config.yml` | Node configuration | Tiny | ✅ Yes |

### Optional Data (Can Be Excluded)

| Directory | Description | Regenerates? | Exclude Option |
|-----------|-------------|--------------|----------------|
| `mempool/` | Temporary transaction pool | Yes | `--exclude-mempool` |
| `logs/` | Log files | N/A | `--exclude-logs` |
| `block_producer/` | Producer-specific data | No | Auto-excluded |
| `grpc/`, `jsonrpc/` | API service data | Yes | Auto-excluded |

## 📖 Usage Guide

### Backup Script Options

```bash
./backup_koinos_node.sh [options]

Options:
  -d, --data-dir DIR     Koinos data directory (default: /root/.koinos)
  -o, --output DIR       Output directory for backup (default: /backup)
  -n, --name NAME        Backup name prefix (default: koinos-backup)
  -c, --compress LEVEL   Compression level 1-9 (default: 6)
  -k, --keep-days DAYS   Keep backups for N days (default: 7)
  --exclude-logs         Exclude log files from backup
  --exclude-mempool      Exclude mempool data from backup
  -h, --help             Show this help message
```

### Restore Script Options

```bash
./restore_koinos_node.sh <backup_file> [options]

Options:
  -t, --target DIR       Target directory (default: /root/.koinos)
  -v, --verify           Verify backup checksum before restore
  -b, --backup-existing  Backup existing data before restore
  -h, --help             Show this help message
```

## 🗓️ Backup Schedule Recommendations

### Production Seed Node

```bash
# Edit crontab
crontab -e

# Daily full backup at 2 AM, keep for 7 days
0 2 * * * /root/scripts/backup_koinos_node.sh --output /backup --keep-days 7 >> /var/log/koinos-backup.log 2>&1

# Weekly full backup with all data, keep for 30 days
0 3 * * 0 /root/scripts/backup_koinos_node.sh --name koinos-weekly --keep-days 30 >> /var/log/koinos-backup.log 2>&1
```

### Development Node

```bash
# Manual backup before major changes
./backup_koinos_node.sh --name pre-upgrade
```

## 💾 Storage Requirements

Typical backup sizes with gzip compression level 6:

| Age | Approximate Size | Notes |
|-----|------------------|-------|
| Fresh node | 500 MB - 1 GB | Minimal blockchain data |
| 3 months | 5-10 GB | Moderate history |
| 6 months | 15-30 GB | Significant history |
| 1 year+ | 50+ GB | Complete blockchain |

**Rule of thumb**: Backup size ≈ 40-60% of original data size (with compression)

## 🌐 Remote Backup

### Transfer to Remote Server

```bash
# Using SCP
scp /backup/koinos-backup_*.tar.gz user@remote-server:/remote/backup/path/

# Using rsync (incremental)
rsync -avz --progress /backup/ user@remote-server:/remote/backup/
```

### Cloud Storage (AWS S3)

```bash
# Install AWS CLI
apt install awscli

# Configure credentials
aws configure

# Upload to S3
aws s3 cp /backup/koinos-backup_20241020_120000.tar.gz \
  s3://your-bucket/koinos-backups/ \
  --storage-class STANDARD_IA
```

### Cloud Storage (Google Cloud)

```bash
# Install gsutil
apt install google-cloud-sdk

# Authenticate
gcloud auth login

# Upload to GCS
gsutil cp /backup/koinos-backup_20241020_120000.tar.gz \
  gs://your-bucket/koinos-backups/
```

## 🔧 Disaster Recovery

### Complete Node Recovery Procedure

#### 1. Prepare New Server

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
apt install docker.io docker-compose -y

# Start Docker
systemctl enable docker
systemctl start docker
```

#### 2. Transfer Backup

```bash
# From backup server to new server
scp koinos-backup_20241020_120000.tar.gz root@new-server:/tmp/
```

#### 3. Restore Data

```bash
# On new server
./restore_koinos_node.sh /tmp/koinos-backup_20241020_120000.tar.gz --verify
```

#### 4. Setup Koinos

```bash
# Clone Koinos orchestration
cd /root
git clone https://github.com/koinos/koinos.git
cd koinos

# Copy your custom config if needed
# (or it should be in the backup already)

# Start services
docker-compose up -d
```

#### 5. Verify Operation

```bash
# Check block height
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"chain.get_head_info","params":{},"id":1}' | jq .

# Check logs
docker-compose logs -f

# Check sync status
docker-compose logs chain | grep "Applied block"
```

## 🔍 Verification & Testing

### Test Your Backups Regularly

```bash
# 1. Create test backup
./backup_koinos_node.sh --name test-backup --output /tmp

# 2. Verify checksum
sha256sum -c /tmp/test-backup_*.tar.gz.sha256

# 3. Test extraction (to temporary location)
mkdir /tmp/restore-test
tar -tzf /tmp/test-backup_*.tar.gz | head -20

# 4. Clean up
rm -rf /tmp/restore-test /tmp/test-backup_*
```

### Monitor Backup Sizes

```bash
# Check backup growth over time
ls -lh /backup/ | grep koinos-backup

# Alert if backup size changes dramatically
CURRENT_SIZE=$(du -m /backup/koinos-backup_latest.tar.gz | cut -f1)
if [ $CURRENT_SIZE -gt 50000 ]; then
  echo "WARNING: Backup exceeds 50GB!"
fi
```

## 🛠️ Troubleshooting

### Problem: Backup Too Large

**Solution**: Exclude optional data

```bash
./backup_koinos_node.sh --exclude-logs --exclude-mempool
```

### Problem: Insufficient Disk Space

**Solution**: Check and clean up

```bash
# Check space
df -h /backup

# Clean old backups manually
rm /backup/koinos-backup_old_*.tar.gz

# Or reduce retention period
./backup_koinos_node.sh --keep-days 3
```

### Problem: Slow Backup

**Solution**: Use lower compression

```bash
# Faster backup, larger file
./backup_koinos_node.sh --compress 1

# Or fastest (no compression)
./backup_koinos_node.sh --compress 0
```

### Problem: Restore Fails

**Solution**: Verify and check permissions

```bash
# Verify checksum first
sha256sum -c backup_file.tar.gz.sha256

# Check if running as root
whoami

# Manually extract to test
tar -tzf backup_file.tar.gz | head

# Check disk space
df -h /
```

## 🔐 Security Considerations

### Encrypt Backups for Offsite Storage

```bash
# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 koinos-backup_20241020_120000.tar.gz

# Decrypt before restore
gpg koinos-backup_20241020_120000.tar.gz.gpg
```

### Secure Backup Location

```bash
# Set proper permissions
chmod 700 /backup
chown root:root /backup

# Restrict script access
chmod 700 backup_koinos_node.sh restore_koinos_node.sh
```

## 📊 Best Practices

1. **Test Regularly** ✅
   - Restore to a test environment monthly
   - Verify blockchain continues to sync after restore

2. **Multiple Locations** 🌍
   - Local backup: Fast recovery
   - Remote backup: Disaster recovery
   - Cloud backup: Long-term storage

3. **Monitor & Alert** 📢
   - Monitor backup script exit codes
   - Alert on failures or unusual sizes
   - Track backup completion times

4. **Document Process** 📝
   - Keep restore procedures updated
   - Document custom configurations
   - Note any modifications

5. **Version Control** 🔄
   - Keep multiple generations
   - Test upgrades with backups
   - Document Koinos version in metadata

6. **Automate** 🤖
   - Use cron for regular backups
   - Automate verification checks
   - Script remote transfers

## 📄 Example Cron Setup

Create `/etc/cron.d/koinos-backup`:

```bash
# Daily backup at 2 AM
0 2 * * * root /root/scripts/backup_koinos_node.sh --output /backup --keep-days 7 >> /var/log/koinos-backup.log 2>&1

# Weekly full backup on Sunday at 3 AM
0 3 * * 0 root /root/scripts/backup_koinos_node.sh --name weekly --keep-days 30 >> /var/log/koinos-backup.log 2>&1

# Monthly backup on the 1st at 4 AM
0 4 1 * * root /root/scripts/backup_koinos_node.sh --name monthly --keep-days 90 >> /var/log/koinos-backup.log 2>&1
```

## 🆘 Support

For issues or questions:
- Check the [Koinos Documentation](https://docs.koinos.io)
- Join [Koinos Discord](https://discord.gg/koinos)
- Open an issue on GitHub

## 📜 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions welcome! Please submit pull requests or open issues for improvements.

---

**Created for the Koinos Community** 🚀
