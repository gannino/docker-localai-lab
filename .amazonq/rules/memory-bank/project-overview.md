# Docker Infrastructure Memory Bank

## Project Overview
Unified Docker infrastructure for local macOS development with AI-powered services, featuring Open WebUI, N8N workflow automation, and Docker Model Runner integration. Supports both production deployment on `app.example.com` and local development with direct port access.

## Core Architecture
- **Reverse Proxy**: Traefik with automatic SSL via Let's Encrypt DNS challenge
- **SSL Provider**: Hurricane Electric DNS challenge
- **Domain**: `app.example.com` (SUBDOMAIN.DOMAIN_NAME)
- **Network**: `traefik-public` external network for service communication
- **Authentication**: JumpCloud LDAP integration for protected services
- **AI Integration**: Open WebUI with Docker Model Runner and Ollama proxy
- **Deployment**: Single unified `docker-compose.yml` file
- **Development**: Local overrides via `docker-compose.local.yml` with direct port access
- **Beginner Support**: Automated setup script for easy local development

## Environment Configuration (.env)
```bash
# Admin credentials
USERNAME=admin
PASSWORD=liangian

# Database
POSTGRES_PASSWORD=anyrandom-here

# LDAP (JumpCloud)
LDAP_URL="ldap://ldap.jumpcloud.com"
LDAP_PORT="389"
LDAP_BASEDN="ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
LDAP_ATTRIBUTE="uid"

# Domain configuration
DOMAIN_NAME=example.com
SUBDOMAIN=app
GENERIC_TIMEZONE=Europe/Rome
SSL_EMAIL=admin@example.com
CERT_RESOLVER=le-dns

# Hurricane Electric DNS
HURRICANE_TOKENS_PASSWORD=DtOKRKTldWeRkG1X

# Ollama Configuration
SOCAT_PORT=8081
OLLAMA_INTERNAL_PORT=12434
```

## Services & Endpoints

### Core Infrastructure
1. **Traefik** (`traefik.app.example.com` | `localhost:8081`)
   - Reverse proxy and load balancer
   - SSL termination with Let's Encrypt
   - Hurricane Electric DNS challenge
   - LDAP authentication plugin

2. **Portainer** (`portainer.app.example.com` | `localhost:9000`)
   - Docker container management UI
   - Connected to Docker socket

### AI-Powered Services
3. **Open WebUI** (`webui.app.example.com` | `localhost:8080`)
   - ChatGPT-like interface for AI models
   - Docker Model Runner integration
   - Dual endpoint configuration (OpenAI API + Ollama)
   - Arena mode for model comparison
   - Persistent data storage

4. **N8N** (`n8n.app.example.com` | `localhost:5678`)
   - AI workflow automation platform
   - PostgreSQL database backend
   - File sharing via `/files` mount
   - AI model integration capabilities

5. **MCP Gateway** (`mcp.app.example.com` | `localhost:8811`)
   - Model Context Protocol gateway
   - Enabled servers: duckduckgo, google-flights, playwright
   - Streaming transport on port 8811

6. **Ollama Proxy** (`oi.app.example.com`)
   - Nginx proxy to local Ollama instance
   - Bridges Docker to host.docker.internal:11434
   - Dual API support: `/api` and `/ollama/v1`

### Utility Services
7. **Echo IP** (`echo.app.example.com`)
   - IP echo service with LDAP authentication
   - Uses mpolden/echoip image

## Deployment Process

### Beginner Setup (Recommended)
```bash
# Complete automated setup for beginners
make first-time       # Guided setup with explanations
make quick-start      # One-command automated setup

# Start services after setup
make local-start
```

### Production Deployment
```bash
# Quick Start
make start

# Development Commands
make help             # Show all commands
make start            # Start all services
make stop             # Stop all services
make status           # Show service status and URLs
make health           # Comprehensive health check
make logs             # View all logs
make logs SERVICE=n8n # View specific service logs
make local-start      # Start with local port exposure
make troubleshoot     # Interactive problem solving
make optimize         # Resource optimization
```

### Local Development
```bash
# Local development with direct port access
make local-start

# Access services locally:
# Open WebUI: http://localhost:8080
# N8N: http://localhost:5678
# Portainer: http://localhost:9000
# Traefik: http://localhost:8081
```

### Clean Reset
```bash
# Complete clean restart (removes all data)
make clean-reset
make beginner-setup
make local-start
```

## Key Features
- **AI-First Architecture**: Open WebUI with Docker Model Runner for local AI inference
- **Dual Deployment Modes**: Production (HTTPS + SSL) and Local Development (direct ports)
- **Beginner-Friendly**: Automated setup script with zero configuration
- **Arena Mode**: Compare multiple AI models side-by-side
- **Workflow Automation**: N8N with AI model integration capabilities
- **Unified Deployment**: Single `docker-compose.yml` file for all services
- **Local Development**: Override file for local port exposure and debugging
- **SSL Everywhere**: All services use HTTPS with wildcard certificates (production)
- **LDAP Integration**: JumpCloud LDAP for authentication where needed
- **Service Discovery**: Traefik automatically discovers services via Docker labels
- **Persistent Storage**: Named volumes and host-mounted directories for data persistence
- **Network Isolation**: Services communicate via traefik-public network
- **Health Monitoring**: Restart policies and health checks ensure service availability
- **Development Tools**: Utility scripts and Makefile for common operations
- **Security**: Auto-generated encryption keys for N8N and WebUI
- **Environment Validation**: Automated checks for required configuration
- **Individual Service Management**: Start/stop/restart specific services
- **macOS Optimized**: Configured for local macOS development with Docker Desktop

## File Structure
```
/Users/Nella/Docker/
├── .env                                    # Environment variables
├── .env.example                           # Environment template
├── docker-compose.yml                     # Unified service definitions
├── docker-compose.local.yml               # Local development overrides
├── Makefile                               # Development commands (consolidated)
├── nginx-ollama.conf                      # Nginx proxy configuration
├── README.md                              # Project documentation
├── AI_WORKFLOW_SETUP_GUIDE.md             # AI workflow guide
├── ARENA_MODEL_TROUBLESHOOTING.md         # Arena mode troubleshooting
├── OPENWEBUI_DOCKER_MODEL_RUNNER_FIX.md   # WebUI configuration fix
├── local-files/                           # Shared file storage (N8N)
├── backups/                               # Automated backups
│   └── YYYYMMDD_HHMMSS/                   # Timestamped backup folders
│       ├── n8n_database.sql               # PostgreSQL dump
│       ├── webui.db                       # WebUI SQLite database
│       ├── n8n_data/                      # N8N Docker volume backup
│       ├── webui_data/                    # WebUI Docker volume backup
│       └── traefik_ssl/                   # SSL certificates backup
└── legacy/                                # Consolidated bash scripts
    ├── prep.sh                            # (moved from root)
    ├── dev.sh                             # (moved from root)
    ├── setup-beginner.sh                  # (moved from root)
    ├── setup-persistent-data.sh           # (moved from root)
    ├── clean-reset.sh                     # (moved from root)
    ├── traefik.yaml                       # Original separate configs
    ├── portainer.yaml
    ├── n8n.yaml
    ├── mcp_gateway.yaml
    ├── ollama_socat.yaml
    ├── whoami.yaml
    ├── http_env.yaml
    └── codeprojectai.yaml
```

## Development Workflow

### For Beginners
1. **Complete Setup**: `make first-time` (guided) or `make quick-start` (automatic)
2. **Start Services**: `make local-start`
3. **Access AI Chat**: Open http://localhost:8080
4. **Create Workflows**: Open http://localhost:5678
5. **Manage Containers**: Open http://localhost:9000
6. **Get Help**: `make troubleshoot` or `make health`

### For Advanced Users
1. **Initial Setup**: `make setup` (first time only)
2. **Start Development**: `make start`
3. **Check Status**: `make status`
4. **View Logs**: `make logs [SERVICE=service]`
5. **Local Testing**: `make local-start` for direct port access
6. **Troubleshoot**: `make troubleshoot` for interactive help
7. **Optimize**: `make optimize` for resource management
8. **Backup Data**: `make backup [COMPRESS=true]`
9. **Restore Data**: `make restore BACKUP=folder_name`
10. **Update Images**: `make update`
11. **Clean Resources**: `make clean`
12. **Complete Reset**: `make clean-reset` then re-setup

## Data Storage & Backup

### Where Your Data Lives
- **N8N workflows & credentials** → PostgreSQL database + Docker volume
- **WebUI conversations & prompts** → SQLite database + Docker volume
- **SSL certificates** → Traefik Docker volume
- **Shared files** → `local-files/` directory

### Backup System
- **Default**: `make backup` (uncompressed, faster)
- **Compressed**: `make backup COMPRESS=true` (smaller files)
- **Restore**: `make restore BACKUP=20240101_120000`
- **List backups**: `make list-backups`

### What Gets Backed Up
- PostgreSQL database dump (N8N workflows/credentials)
- WebUI SQLite database (conversations/prompts/settings)
- All Docker volumes (N8N data, WebUI data, SSL certificates)
- Configuration files (.env, docker-compose files, nginx config)
- Shared files directory

## Security Notes
- **Production**: All services require HTTPS with SSL certificates
- **Local Development**: HTTP access for ease of development
- **LDAP Authentication**: JumpCloud LDAP on sensitive endpoints (production)
- **Docker Socket**: Access limited to management containers
- **SSL Certificates**: Auto-renewed via Let's Encrypt (production)
- **DNS Challenge**: Hurricane Electric tokens for DNS authentication
- **AI Privacy**: All AI models run locally, no data sent to external services
- **Data Persistence**: User data and conversations stored locally

## AI Features
- **Docker Model Runner**: No need to install Ollama separately
- **Multiple AI Models**: Access to various open-source models
- **Arena Mode**: Compare responses from different models
- **AI Workflows**: Automate tasks with N8N + AI integration
- **Local Inference**: All AI processing happens on your machine
- **Model Management**: Easy model installation and updates
- **Persistent Conversations**: Chat history saved locally
- **File Processing**: Upload and process documents with AI
