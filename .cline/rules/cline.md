# Docker AI Lab - Project Guide for Cline

## Project Overview

**Docker AI Lab** is a comprehensive, production-ready Docker infrastructure for local AI development on macOS. It provides a unified environment with AI-powered services, workflow automation, and container management tools.

### Purpose
- Enable local AI model inference without cloud dependencies
- Provide workflow automation with visual programming tools
- Offer beginner-friendly setup with advanced production capabilities
- Maintain complete data privacy with local processing

### Key Technologies
- **Docker & Docker Compose** - Container orchestration
- **Traefik** - Reverse proxy with automatic SSL
- **Open WebUI** - ChatGPT-like AI interface
- **N8N** - Visual workflow automation platform
- **Node-RED** - Flow-based visual programming
- **CodeProject.AI** - Computer vision services
- **PostgreSQL** - Database backend for N8N
- **Portainer** - Docker container management UI
- **MCP Gateway** - Model Context Protocol support
- **Ollama Proxy** - AI model inference bridge (Docker Model Runner)

### High-Level Architecture
```
User Browser → Traefik → Services (WebUI, N8N, Node-RED, etc.)
                ↓
         Docker Network (isolated)
                ↓
         Persistent Volumes (data storage)
```

All services run locally in Docker containers, communicate via internal networks, and persist data in Docker volumes.

---

## Getting Started

### Prerequisites
- macOS (Apple Silicon or Intel)
- Docker Desktop installed and running
- Terminal access
- Admin privileges

### Quick Start (New Users)
```bash
# One-command setup and start
make quick-start

# Or guided first-time setup
make first-time
```

### Basic Usage Examples

**Start local development environment:**
```bash
make local-start
```

**Access services:**
- AI Chat: http://localhost:8080
- Workflows: http://localhost:5678
- Node-RED: http://localhost:1880
- Portainer: http://localhost:9000
- Traefik Dashboard: http://localhost:8081

**Stop services:**
```bash
make local-stop
```

**Check status:**
```bash
make status
make health
```

### Running Tests
```bash
# Full test suite
make test

# Service tests
make test-services

# Configuration validation
make test-config

# Linting
make lint
```

---

## Project Structure

### Main Directories

```
local-ai-lab/
├── .cline/                      # Cline configuration and rules
│   └── rules/                   # Project documentation for Cline
├── .github/                     # CI/CD workflows
│   └── workflows/               # GitHub Actions
├── backups/                     # Timestamped backup snapshots
│   └── YYYYMMDD_HHMMSS/        # Individual backup folders
├── data/                        # Persistent data storage
│   ├── n8n-workflows/          # N8N workflow data
│   ├── webui-config/           # AI chat settings
│   ├── mcp-config/             # MCP Gateway configuration
│   └── postgres-backups/       # Database backups
├── docs/                        # Documentation files
│   ├── ARCHITECTURE.md         # System architecture guide
│   ├── FAQ.md                  # Common questions
│   ├── LDAP_AUTHENTICATION.md  # Enterprise LDAP setup
│   ├── PROJECT_SUMMARY.md      # Project overview
│   ├── PUBLIC_TUNNEL_GUIDE.md  # Public access setup
│   ├── ROADMAP.md              # Development roadmap
│   └── VSCODE_LLM_INTEGRATION.md # VS Code AI setup
├── legacy/                      # Deprecated scripts (reference)
└── local-files/                 # Shared file storage for services
```

### Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production service definitions with SSL/LDAP |
| `docker-compose.local.yml` | Local development overrides (direct ports) |
| `Makefile` | All management commands (consolidated) |
| `nginx-ollama.conf` | Ollama proxy configuration for AI models |
| `.env` | Environment variables (auto-generated) |
| `.env.example` | Environment template |
| `README.md` | Main documentation |
| `GETTING_STARTED.md` | Complete beginner's guide |
| `CONTRIBUTING.md` | Developer setup guide |
| `.pre-commit-config.yaml` | Code quality hooks |
| `.yamllint.yml` | YAML linting configuration |

### Important Configuration Files

- **Environment**: `.env` (auto-generated with secure passwords)
- **Service Definitions**: `docker-compose.yml` (production), `docker-compose.local.yml` (development)
- **Proxy Config**: `nginx-ollama.conf` (AI model routing)
- **Quality Checks**: `.pre-commit-config.yaml`, `.yamllint.yml`

---

## Development Workflow

### Coding Standards

**Shell Scripts:**
- Use `#!/bin/bash` shebang
- Enable strict mode for safety
- Follow shellcheck recommendations
- Add comments for complex logic

**YAML Files:**
- Use 2-space indentation
- Validate with yamllint
- Follow Docker Compose best practices
- Document service configurations

**Makefile:**
- Use `.PHONY` for non-file targets
- Add help text: `target: ## Description`
- Use `@` prefix for clean output
- Handle errors gracefully with proper exit codes

**Documentation:**
- Use clear, beginner-friendly language
- Include practical code examples
- Add visual diagrams where helpful
- Keep guides up-to-date

### Testing Approach

**Three-tier testing:**

1. **Quick Tests** (`make test-quick`)
   - Configuration validation
   - Docker availability checks
   - Documentation completeness

2. **Service Tests** (`make test-services`)
   - Service startup validation
   - Health check verification
   - Port accessibility tests

3. **Full Test Suite** (`make test`)
   - All configuration tests
   - Docker network setup
   - Service functionality
   - Documentation validation

**Pre-commit Hooks:**
- Trailing whitespace removal
- End-of-file fixing
- YAML validation
- Shell script linting
- Docker Compose validation
- Makefile syntax checking

### Build and Deployment Process

**Local Development:**
```bash
# Start local development (direct ports)
make local-start

# Monitor logs
make logs

# Check health
make health
```

**Production Deployment:**
```bash
# Validate configuration
make validate

# Start with SSL and LDAP
make start

# Monitor status
make status
```

**Deployment Modes:**
- **Local** (`make local-start`): Direct port access, no SSL, simplified setup
- **Production** (`make start`): SSL certificates, LDAP auth, reverse proxy

### Contribution Guidelines

1. **Create feature branch:** `git checkout -b feature/your-feature`
2. **Make changes and test:** `make test && make lint`
3. **Commit with hooks:** Hooks run automatically
4. **Push and create PR:** Follow commit message conventions
5. **CI/CD validation:** GitHub Actions runs tests

---

## Key Concepts

### Domain-Specific Terminology

- **Docker Model Runner**: Local AI inference without separate Ollama installation
- **Traefik**: Smart reverse proxy that routes traffic and manages SSL
- **Docker Volumes**: Persistent storage for service data (survives container restarts)
- **Docker Networks**: Isolated networks for service communication
- **Health Checks**: Automated service availability verification
- **MCP (Model Context Protocol)**: Protocol for AI model context sharing

### Core Abstractions

**Service Layers:**
1. **Infrastructure Layer**: Docker, networks, volumes
2. **Proxy Layer**: Traefik (routing and SSL)
3. **Application Layer**: WebUI, N8N, Node-RED, CodeProject.AI
4. **Data Layer**: PostgreSQL, Docker volumes

**Data Flow:**
```
User Request → Browser → Traefik → Service → Processing → Response
                                        ↓
                                   Database/Storage
```

**Security Model:**
- **Local**: All processing on your Mac
- **Isolated**: Docker network boundaries
- **Encrypted**: SSL for production
- **Private**: No external data transfer

### Design Patterns Used

1. **Infrastructure as Code**: All services defined in docker-compose.yml
2. **Environment Configuration**: .env for secrets and settings
3. **Service Discovery**: Docker DNS and networks
4. **Health Monitoring**: Built-in health checks
5. **Backup/Restore**: Automated data protection
6. **Graceful Degradation**: Services can fail independently

---

## Common Tasks

### Start/Stop Services

```bash
# Start local development
make local-start

# Start production
make start

# Stop services
make local-stop  # or: make stop

# Restart services
make restart

# Restart specific service
make restart-service SERVICE=webui
```

### Monitor and Debug

```bash
# Check service status
make status

# Run health check
make health

# View all logs
make logs

# View specific service logs
make logs SERVICE=webui

# Show service URLs
make show-urls

# Interactive troubleshooting
make troubleshoot
```

### Backup and Restore

```bash
# Create backup (uncompressed)
make backup

# Create compressed backup
make backup COMPRESS=true

# List available backups
make list-backups

# Restore from backup
make restore BACKUP=20240101_120000

# Restore specific service
make restore-service BACKUP=20240101_120000 SERVICE=n8n
```

### Update and Maintenance

```bash
# Update all images
make update

# Clean unused resources
make clean

# Complete reset (removes data)
make clean-reset

# Quick development reset (keeps data)
make dev-reset

# Optimize resource usage
make optimize
```

### Working with AI Models

```bash
# Access Open WebUI
open http://localhost:8080

# Check AI service logs
make logs SERVICE=webui
make logs SERVICE=ollama-proxy

# Restart AI services
make restart-service SERVICE=webui
```

### Development Tasks

```bash
# Install pre-commit hooks
make pre-commit-install

# Run pre-commit checks
make pre-commit-run

# Run linting
make lint

# Run tests
make test
make test-services
make test-config
```

---

## Troubleshooting

### Common Issues and Solutions

**Issue: Services won't start**
```bash
# Solution 1: Check Docker is running
docker info

# Solution 2: Restart Docker Desktop, then:
make local-start

# Solution 3: Complete clean restart
make clean-reset
make quick-start
```

**Issue: Can't access web interfaces**
```bash
# Solution 1: Wait 30 seconds after start
sleep 30

# Solution 2: Check service status
make status
make health

# Solution 3: Try 127.0.0.1 instead of localhost
# e.g., http://127.0.0.1:8080
```

**Issue: AI models not working**
```bash
# Solution 1: Check logs
make logs SERVICE=webui
make logs SERVICE=ollama-proxy

# Solution 2: Restart AI services
make restart-service SERVICE=ollama-proxy
make restart-service SERVICE=webui

# Solution 3: Verify Docker Model Runner is accessible
curl http://localhost:8082/api/tags
```

**Issue: Database connection errors**
```bash
# Solution 1: Check database is running
docker compose ps n8n-db

# Solution 2: Restart database
make restart-service SERVICE=n8n-db

# Solution 3: Check database logs
make logs SERVICE=n8n-db
```

**Issue: Port already in use**
```bash
# Solution 1: Find process using port
lsof -i :8080

# Solution 2: Stop conflicting service or use different port
# Edit docker-compose.local.yml to change port mappings
```

**Issue: Out of disk space**
```bash
# Solution: Clean up Docker resources
make clean
docker system prune -a --volumes
```

**Issue: Performance is slow**
```bash
# Solution: Optimize resource allocation
make optimize

# Check Docker Desktop settings:
# - Increase RAM allocation (8-12GB recommended)
# - Enable Rosetta on Apple Silicon
# - Use SSD storage
```

### Debugging Tips

**Enable verbose logging:**
```bash
# View real-time logs
make logs

# Check specific service
make logs SERVICE=n8n
```

**Check service health:**
```bash
# Comprehensive health check
make health

# Service status
make status

# Docker container inspection
docker compose ps
docker inspect <container-name>
```

**Network debugging:**
```bash
# List Docker networks
docker network ls

# Inspect network
docker network inspect traefik-public

# Test connectivity between services
docker compose exec webui ping n8n
```

**Volume debugging:**
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect local-ai-lab_webui_data

# View volume contents
docker run --rm -v local-ai-lab_webui_data:/data alpine ls -la /data
```

---

## References

### Internal Documentation
- [README.md](../README.md) - Main project documentation
- [GETTING_STARTED.md](../GETTING_STARTED.md) - Complete beginner's guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Developer setup guide
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System architecture with diagrams
- [docs/FAQ.md](../docs/FAQ.md) - Frequently asked questions
- [docs/VSCODE_LLM_INTEGRATION.md](../docs/VSCODE_LLM_INTEGRATION.md) - VS Code AI setup
- [docs/LDAP_AUTHENTICATION.md](../docs/LDAP_AUTHENTICATION.md) - Enterprise LDAP guide
- [docs/PUBLIC_TUNNEL_GUIDE.md](../docs/PUBLIC_TUNNEL_GUIDE.md) - Public access setup
- [docs/ROADMAP.md](../docs/ROADMAP.md) - Development roadmap

### External Resources
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [N8N Documentation](https://docs.n8n.io/)
- [Node-RED Documentation](https://nodered.org/docs/)
- [CodeProject.AI](https://www.codeproject.com/Articles/5322557/CodeProject-AI-Server)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Makefile Commands Reference

Run `make help` to see all available commands. Key command categories:

- **Setup**: `quick-start`, `first-time`, `setup`, `beginner-setup`
- **Start/Stop**: `start`, `stop`, `local-start`, `local-stop`, `restart`
- **Monitoring**: `status`, `health`, `logs`, `show-urls`
- **Backup**: `backup`, `restore`, `list-backups`
- **Maintenance**: `update`, `clean`, `clean-reset`, `dev-reset`
- **Development**: `test`, `lint`, `pre-commit-install`, `pre-commit-run`
- **Troubleshooting**: `troubleshoot`, `optimize`, `health`

---

## Quick Reference Card

### Most Common Commands
```bash
make quick-start      # First-time setup
make local-start      # Start development
make local-stop       # Stop services
make status           # Check status
make health           # Health check
make logs             # View logs
make backup           # Backup data
make help             # Show all commands
```

### Service URLs (Local)
- 🤖 AI Chat: http://localhost:8080
- 🔄 Workflows: http://localhost:5678
- 🔎 Node-RED: http://localhost:1880
- 📷 Computer Vision: http://localhost:32168
- 🐳 Docker UI: http://localhost:9000
- 📊 Dashboard: http://localhost:8081
- 🌐 MCP: http://localhost:8811

### Emergency Commands
```bash
make troubleshoot     # Interactive help
make dev-reset        # Quick restart
make clean-reset      # Complete reset
```

---

## Notes for Cline

**When working with this project:**

1. **Always check if Docker is running** before executing commands
2. **Use make commands** instead of direct docker compose (they handle env vars properly)
3. **Test changes in local mode** (`make local-start`) before production
4. **Run tests** after configuration changes (`make test`)
5. **Check logs** if services don't start (`make logs SERVICE=name`)
6. **Backup before major changes** (`make backup`)
7. **Use health checks** to verify service status (`make health`)
8. **Follow coding standards** defined in CONTRIBUTING.md
9. **Update documentation** when adding features
10. **Run pre-commit hooks** before commits (`make pre-commit-run`)

**Common modification patterns:**

- **Add service**: Update docker-compose.yml → Update Makefile → Add tests → Update docs
- **Change ports**: Edit docker-compose.local.yml → Restart services
- **Modify config**: Edit relevant file → Validate → Restart affected service
- **Add command**: Update Makefile → Add help text → Test command → Update docs

**Architecture considerations:**

- Services use **Docker networks** for isolation and communication
- Data persists in **Docker volumes** (survives container restarts)
- **Traefik** handles routing in production, direct ports in development
- **Health checks** ensure services are ready before dependencies start
- **Environment variables** in `.env` configure all services
