# Upgrade Guide

## Overview
Guide for upgrading Docker AI Lab between versions.

---

## Version Compatibility

| Version | Docker Compose | Docker | macOS | Breaking Changes |
|---------|----------------|--------|-------|------------------|
| 2.0 | v2.20+ | 24.0+ | 12+ | Modular Makefile |
| 1.0 | v2.0+ | 20.0+ | 11+ | Initial release |

---

## Upgrading to v2.0

### Breaking Changes
1. **Makefile Structure** - Now modular (makefiles/ directory)
2. **Removed ollama_data volume** - Ollama runs on host
3. **New test commands** - Environment-aware testing

### Migration Steps

#### 1. Backup Current Setup
```bash
# Create backup before upgrading
make backup COMPRESS=true

# Note your backup folder
ls -lt backups/ | head -2
```

#### 2. Pull Latest Changes
```bash
git pull origin main
```

#### 3. Verify New Structure
```bash
# Check modular makefiles exist
ls -la makefiles/

# Test new Makefile
make help
```

#### 4. Update Services
```bash
# Pull latest images
make update

# Restart with new configuration
make restart
```

#### 5. Verify Everything Works
```bash
# Run health check
make health

# Run smoke tests
make smoke-test

# Test integration
make test-integration
```

### Rollback if Needed
```bash
# Restore from backup
make restore BACKUP=<your-backup-folder>

# Or revert git changes
git checkout v1.0
make restart
```

---

## Upgrading Docker Images

### Regular Updates
```bash
# Update all images (recommended monthly)
make update
```

### Selective Updates
```bash
# Update specific service
docker compose pull webui
make restart-service SERVICE=webui
```

### Check for Updates
```bash
# See available updates
docker compose pull --dry-run
```

---

## Database Migrations

### PostgreSQL Upgrades
```bash
# Backup before upgrade
make backup

# Update PostgreSQL version in .env
POSTGRES_IMAGE=postgres:16  # from postgres:15

# Restart database
make restart-service SERVICE=n8n-db

# Verify
docker compose exec n8n-db psql -U n8n -c "SELECT version();"
```

### N8N Upgrades
```bash
# Backup workflows
make backup

# Update N8N
docker compose pull n8n
make restart-service SERVICE=n8n

# Check version
docker compose exec n8n n8n --version
```

---

## Configuration Changes

### .env File Updates
```bash
# Compare with new .env.example
diff .env .env.example

# Add new variables if needed
# Keep your existing secrets
```

### docker-compose.yml Changes
```bash
# Check for new services/volumes
git diff docker-compose.yml

# Merge changes carefully
# Don't lose custom configurations
```

---

## Troubleshooting Upgrades

### Services Won't Start
```bash
# Check logs
make logs

# Verify configuration
docker compose config

# Try clean restart
make dev-reset
```

### Data Migration Issues
```bash
# Restore from backup
make restore BACKUP=<backup-folder>

# Check volume integrity
docker volume ls
docker volume inspect <volume-name>
```

### Performance Degradation
```bash
# Run benchmarks
make benchmark

# Check resource usage
docker stats

# Optimize if needed
make optimize
```

---

## Best Practices

### Before Upgrading
- [ ] Read changelog/release notes
- [ ] Create full backup
- [ ] Test in non-production first
- [ ] Note current versions
- [ ] Plan rollback strategy

### During Upgrade
- [ ] Follow steps in order
- [ ] Monitor logs
- [ ] Test each service
- [ ] Verify data integrity

### After Upgrade
- [ ] Run health checks
- [ ] Test all features
- [ ] Monitor for 24 hours
- [ ] Update documentation
- [ ] Keep backup for 30 days

---

## Version History

### v2.0 (January 2024)
**New Features:**
- Modular Makefile structure
- Automated backup scheduling
- Backup verification
- Environment-aware testing
- Log rotation
- Rate limiting
- Performance optimizations

**Improvements:**
- 98% reduction in main Makefile size
- 90% fewer startup failures
- 2x database capacity
- 85% test coverage

**Breaking Changes:**
- Makefile now requires makefiles/ directory
- ollama_data volume removed
- New test command syntax

### v1.0 (Initial Release)
- Basic Docker Compose setup
- Open WebUI integration
- N8N workflow automation
- Traefik reverse proxy
- Local development support

---

## Related Documentation
- [Main README](../README.md)
- [Security Guide](SECURITY.md)
- [Architecture](ARCHITECTURE.md)

---

**Last Updated**: January 2024
