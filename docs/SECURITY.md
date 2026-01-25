# Security Best Practices

## 🔒 Overview
Security guidelines for Docker AI Lab deployment and operation.

---

## 📝 Environment File Security

### .env File Permissions
```bash
# Set restrictive permissions
chmod 600 .env

# Verify
ls -la .env
# Should show: -rw------- (owner read/write only)
```

### Never Commit .env
```bash
# Verify .env is in .gitignore
grep "^\.env$" .gitignore

# If not, add it
echo ".env" >> .gitignore
```

### Rotate Secrets Regularly
```bash
# Generate new secrets
openssl rand -hex 32  # For encryption keys

# Update .env and restart
make restart
```

---

## 🌐 Network Security

### Local Development
- ✅ Services bound to localhost only
- ✅ No external exposure by default
- ✅ Firewall rules not needed

### Production Deployment
```yaml
# Use SSL/TLS everywhere
- HTTPS enforced via Traefik
- Let's Encrypt certificates
- 300s DNS propagation delay
```

### Rate Limiting
```yaml
# Already configured on WebUI
- 100 requests/second average
- 50 request burst allowed
```

---

## 🔐 SSL/TLS Best Practices

### Certificate Management
- ✅ Automatic renewal (Let's Encrypt)
- ✅ Wildcard certificates
- ✅ Stored in Docker volumes
- ✅ Backed up with `make backup`

### Verify SSL Configuration
```bash
# Check certificate expiry
make logs SERVICE=traefik | grep certificate

# Test SSL endpoint
curl -I https://webui.yourdomain.com
```

---

## 🔑 Secrets Management

### Current Approach
- Environment variables in .env
- Auto-generated encryption keys
- Docker volume storage

### Best Practices
```bash
# Generate strong passwords
openssl rand -hex 16  # 32 characters

# Never use default values
# Never commit secrets to git
# Rotate secrets periodically
```

### Future: Docker Secrets (Roadmap Phase 4)
```yaml
# Planned for production deployments
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

---

## 📊 Audit Logging

### Enable Logging
```bash
# Already enabled - logs to Docker
make logs SERVICE=traefik  # Access logs
make logs SERVICE=n8n      # Workflow logs
```

### Log Retention
- 10MB per log file
- 3 files kept (30MB total)
- Automatic rotation

### Monitor Logs
```bash
# Watch for suspicious activity
make logs SERVICE=traefik | grep -i "429\|403\|401"
```

---

## 🚫 Security Checklist

### Before Production Deployment
- [ ] Change all default passwords
- [ ] Set .env file permissions (600)
- [ ] Enable HTTPS/SSL
- [ ] Configure rate limiting
- [ ] Enable LDAP auth (if needed)
- [ ] Test backup/restore
- [ ] Review firewall rules
- [ ] Update all images

### Regular Maintenance
- [ ] Update Docker images monthly
- [ ] Rotate secrets quarterly
- [ ] Review access logs weekly
- [ ] Test backups monthly
- [ ] Check SSL expiry

---

## ⚠️ Common Security Mistakes

### ❌ Don't Do This
```bash
# Don't expose database ports publicly
ports:
  - "5432:5432"  # BAD!

# Don't use weak passwords
PASSWORD=admin123  # BAD!

# Don't commit .env to git
git add .env  # BAD!
```

### ✅ Do This Instead
```bash
# Bind to localhost only
ports:
  - "127.0.0.1:5432:5432"  # GOOD

# Use strong generated passwords
PASSWORD=$(openssl rand -hex 16)  # GOOD

# Keep .env in .gitignore
echo ".env" >> .gitignore  # GOOD
```

---

## 🔍 Security Monitoring

### Health Checks
```bash
# Regular security checks
make health-detailed
make benchmark
```

### Resource Monitoring
```bash
# Watch for unusual activity
docker stats
make logs
```

---

## 📞 Incident Response

### If Compromised
1. **Immediately**: `make stop`
2. **Rotate all secrets** in .env
3. **Review logs**: `make logs`
4. **Restore from backup**: `make restore BACKUP=<clean-backup>`
5. **Update all images**: `make update`
6. **Restart**: `make start`

---

## 🔗 Related Documentation
- [Main README](../README.md)
- [LDAP Authentication](LDAP_AUTHENTICATION.md)
- [Architecture](ARCHITECTURE.md)

---

**Last Updated**: January 2024
**Review Frequency**: Quarterly
