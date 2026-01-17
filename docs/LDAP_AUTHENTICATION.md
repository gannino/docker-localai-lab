# LDAP Authentication Configuration

## Overview
Open WebUI supports LDAP authentication for enterprise environments. This guide covers configuration with JumpCloud LDAP.

## Quick Setup

### 1. Enable LDAP in .env
```bash
# WebUI LDAP Authentication
ENABLE_LDAP_AUTH=true
LDAP_BIND_DN=uid=service-account,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com
LDAP_BIND_PASSWORD=service-account-password
LDAP_USER_FILTER=(uid=%s)
LDAP_EMAIL_ATTRIBUTE=mail
LDAP_DISPLAY_NAME_ATTRIBUTE=displayName

# Authentication Strategy
ENABLE_SIGNUP=false  # LDAP only
# OR
ENABLE_SIGNUP=true   # LDAP + local accounts
```

### 2. Apply Configuration
```bash
docker compose restart webui
```

## JumpCloud Configuration

### Required Settings
- **LDAP URL**: `ldap://ldap.jumpcloud.com`
- **Port**: `389`
- **Base DN**: `ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com`
- **Bind DN**: Service account with read permissions
- **User Filter**: `(uid=%s)` for username login

### Service Account Setup
1. Create dedicated service account in JumpCloud
2. Grant LDAP read permissions
3. Use full DN format: `uid=service-account,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com`

## Authentication Modes

### LDAP Only (Production)
```bash
ENABLE_LDAP_AUTH=true
ENABLE_SIGNUP=false
```
- All users must authenticate via LDAP
- No local account creation

### Hybrid Mode (Development)
```bash
ENABLE_LDAP_AUTH=true
ENABLE_SIGNUP=true
```
- LDAP users can login with domain credentials
- Local accounts still allowed

## Troubleshooting

### Check LDAP Connection
```bash
# View WebUI logs
docker compose logs webui | grep -i ldap

# Test LDAP from container
docker compose exec webui ldapsearch -x -H ldap://ldap.jumpcloud.com:389 \
  -D "uid=service-account,ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com" \
  -W -b "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com" "(uid=username)"
```

### Common Issues
- **Connection refused**: Check LDAP URL/port
- **Invalid credentials**: Verify service account DN/password
- **User not found**: Check Base DN and user filter
- **No email/name**: Verify attribute mappings

### Disable LDAP
```bash
ENABLE_LDAP_AUTH=false
ENABLE_SIGNUP=true
```

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `ENABLE_LDAP_AUTH` | Enable LDAP authentication | `true/false` |
| `LDAP_SERVER_URL` | LDAP server URL | `ldap://ldap.jumpcloud.com` |
| `LDAP_SERVER_PORT` | LDAP server port | `389` |
| `LDAP_BIND_DN` | Service account DN | `uid=svc,ou=Users,o=123,dc=jumpcloud,dc=com` |
| `LDAP_BIND_PASSWORD` | Service account password | `password123` |
| `LDAP_USER_BASE` | User search base | `ou=Users,o=123,dc=jumpcloud,dc=com` |
| `LDAP_USER_FILTER` | User search filter | `(uid=%s)` |
| `LDAP_USER_ATTRIBUTE` | Username attribute | `uid` |
| `LDAP_EMAIL_ATTRIBUTE` | Email attribute | `mail` |
| `LDAP_DISPLAY_NAME_ATTRIBUTE` | Display name attribute | `displayName` |
