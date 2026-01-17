# Memory Bank - Docker AI Infrastructure

## 🎯 Project Overview
**Purpose**: Unified Docker infrastructure for local macOS development with AI-powered services
**Target**: Local development environment with Open WebUI, N8N, Traefik, and Docker Model Runner
**Platform**: macOS optimized

## 🚀 Quick Start Commands
```bash
# Complete setup from scratch
make first-time      # Guided first-time setup
make quick-start     # One-command setup and start

# Start local development
make local-start

# Check everything is running
make health          # Comprehensive health check
make status          # Service status + URLs

# Stop everything
make local-stop

# Get help with issues
make troubleshoot    # Interactive troubleshooting
make optimize        # Resource optimization
```

## 🌐 Service URLs & Ports
| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| Open WebUI | http://localhost:8080 | 8080 | AI Chat Interface |
| N8N | http://localhost:5678 | 5678 | Workflow Automation |
| Portainer | http://localhost:9000 | 9000 | Docker Management |
| Traefik Dashboard | http://localhost:8081 | 8081 | Reverse Proxy |
| MCP Gateway | http://localhost:8811 | 8811 | Model Context Protocol |

## 🏗️ Architecture Components
- **Traefik**: Reverse proxy and load balancer
- **Open WebUI**: ChatGPT-like interface for AI models
- **N8N**: Visual workflow automation platform
- **PostgreSQL**: Database for N8N workflows
- **Portainer**: Docker container management UI
- **MCP Gateway**: Model Context Protocol support
- **Ollama Proxy**: AI model inference bridge
- **Docker Model Runner**: Local AI model inference (no separate Ollama needed)

## 📁 Critical File Locations
```
Docker/
├── docker-compose.yml              # Main service definitions
├── docker-compose.local.yml        # Local development overrides
├── Makefile                        # All management commands
├── nginx-ollama.conf               # Ollama proxy configuration
├── local-files/                    # Shared file storage (N8N)
├── backups/YYYYMMDD_HHMMSS/       # Timestamped backups
└── README.md                       # Complete documentation
```

## 💾 Data Storage Map
| Data Type | Storage Location | Backup Method |
|-----------|------------------|---------------|
| N8N workflows & credentials | PostgreSQL + `{folder-name}_n8n_data` volume | `make backup` |
| WebUI conversations | SQLite + `{folder-name}_webui_data` volume | `make backup` |
| SSL certificates | `{folder-name}_traefik_data` volume | `make backup` |
| Shared files | `local-files/` directory | `make backup` |

## 🔧 Essential Make Commands
```bash
# Setup & Deployment
make first-time        # Complete guided setup for beginners
make quick-start       # One-command setup and start
make local-start       # Start with direct ports (development)
make start            # Start with Traefik (production)
make stop             # Stop all services

# Monitoring & Health
make status           # Service status + URLs
make health           # Comprehensive health check
make logs             # All service logs
make logs SERVICE=webui # Specific service logs
make show-urls        # Display all service URLs

# Troubleshooting & Optimization
make troubleshoot     # Interactive troubleshooting assistant
make optimize         # Resource optimization with interactive menu
make dev-reset        # Quick restart (keeps data)

# Backup & Recovery
make backup                        # Uncompressed backup
make backup COMPRESS=true          # Compressed backup
make restore BACKUP=20240101_120000 # Restore from backup
make list-backups                  # List available backups

# Maintenance
make update           # Update all images
make clean            # Clean unused resources
make clean-reset      # Complete clean restart
```

**Note**: All commands automatically detect your project folder name for volume and container management.

## 🚨 Common Issues & Solutions

### Services Won't Start
```bash
# Check Docker is running
docker info

# Restart Docker Desktop
# Applications → Docker → Restart

# Try again
make local-start
```

### Port Conflicts
```bash
# Check what's using ports
lsof -i :8080
lsof -i :5678

# Kill conflicting processes or change ports in docker-compose.local.yml
```

### AI Models Not Working
```bash
# Check WebUI logs
docker compose logs webui

# Check Ollama proxy
docker compose logs ollama-proxy

# Restart AI services
docker compose restart webui ollama-proxy
```

### Complete Reset
```bash
make clean-reset
make beginner-setup
make local-start
```

## 🔍 Debugging Commands
```bash
# Service-specific logs
make logs SERVICE=webui
make logs SERVICE=n8n
make logs SERVICE=traefik

# Container inspection
docker compose ps
docker compose top

# Network debugging
docker network ls
docker network inspect docker_default

# Volume inspection
docker volume ls
docker volume inspect docker_n8n_data
```

## 🛡️ Security & Configuration
- **Local Processing**: All AI runs locally, no external data
- **Auto-generated Keys**: N8N and WebUI encryption keys
- **SSL Support**: Production deployment uses HTTPS
- **LDAP Integration**: Enterprise authentication available (JumpCloud)
- **WebUI LDAP**: Full LDAP authentication support for Open WebUI
- **Health Checks**: Service monitoring and dependencies
- **Environment Validation**: Pre-deployment checks

### LDAP Configuration
```bash
# Enable LDAP in WebUI
ENABLE_LDAP_AUTH=true
LDAP_BIND_DN=uid=service-account,ou=Users,o=ORG_ID,dc=jumpcloud,dc=com
LDAP_BIND_PASSWORD=service-password

# Authentication modes
ENABLE_SIGNUP=false  # LDAP only
ENABLE_SIGNUP=true   # LDAP + local accounts
```

## 🤖 AI Features Checklist
- ✅ Docker Model Runner (no separate Ollama install)
- ✅ Multiple AI models access
- ✅ Arena mode (model comparison)
- ✅ Local inference (privacy)
- ✅ Persistent conversations
- ✅ File processing capabilities
- ✅ N8N AI workflow integration

## 📋 Prerequisites Checklist
- ✅ macOS (any recent version)
- ✅ Docker Desktop installed
- ✅ Internet connection for initial setup
- ✅ Admin access to Mac
- ✅ Available ports: 8080, 5678, 9000, 8081, 8811

## 🔄 Backup Strategy
| Backup Type | Command | Speed | Size | Use Case |
|-------------|---------|-------|------|----------|
| Uncompressed | `make backup` | Fast | Large | Quick daily backups |
| Compressed | `make backup COMPRESS=true` | Slow | Small | Long-term storage |

## 📚 Documentation References
- **README.md**: Complete setup guide
- **ROADMAP.md**: Development roadmap and future features
- **LDAP_AUTHENTICATION.md**: Enterprise LDAP configuration guide
- **AI_WORKFLOW_SETUP_GUIDE.md**: N8N workflow automation
- **ARENA_MODEL_TROUBLESHOOTING.md**: Model comparison issues
- **OPENWEBUI_DOCKER_MODEL_RUNNER_FIX.md**: WebUI configuration
- **Makefile**: All available commands with descriptions

## 🎯 Use Case Quick Reference
| Use Case | Primary Service | Setup Steps |
|----------|----------------|-------------|
| AI Chat | Open WebUI | `make local-start` → http://localhost:8080 |
| Workflow Automation | N8N | `make local-start` → http://localhost:5678 |
| Container Management | Portainer | `make local-start` → http://localhost:9000 |
| Model Comparison | Open WebUI Arena | Enable in WebUI settings |
| Document Processing | Open WebUI + N8N | Upload files to WebUI, create N8N workflows |

## 🆘 Emergency Procedures
1. **Complete System Failure**: `make clean-reset && make quick-start`
2. **Data Recovery**: `make restore BACKUP=<timestamp>`
3. **Interactive Troubleshooting**: `make troubleshoot`
4. **Health Diagnosis**: `make health`
5. **Resource Issues**: `make optimize`
6. **Quick Restart**: `make dev-reset`
7. **Docker Issues**: Restart Docker Desktop from Applications

---
**Last Updated**: Generated from project documentation
**Quick Help**: Run `make help` to see all available commands
