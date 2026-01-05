# Docker Infrastructure for Local Development

A unified Docker infrastructure setup optimized for local macOS development with AI-powered services, featuring Open WebUI, N8N workflow automation, Traefik reverse proxy, and Docker Model Runner integration.

## ⚠️ **DISCLAIMER**

**NO WARRANTY**: This software is provided "AS IS" without warranty of any kind. We do not guarantee that this software will work correctly, be suitable for any particular purpose, or be free from errors or security vulnerabilities.

**NO LIABILITY**: The authors and contributors are not responsible for any damages, data loss, security breaches, system failures, or other issues that may arise from using this software. Use at your own risk.

**USER RESPONSIBILITY**: You are solely responsible for:
- Testing this software in your environment
- Ensuring it meets your security requirements
- Backing up your data before use
- Understanding the risks of running AI services locally

By using this software, you acknowledge and accept these terms.

## 🎯 For Complete Beginners

**New to this?** Start here: **[📖 Complete Beginner's Guide](GETTING_STARTED.md)**

**Have questions?** Check the **[❓ FAQ](FAQ.md)**

## ⚡ Quick Start (Experienced Users)

```bash
git clone <your-repo-url>
cd local-ai-lab
make quick-start
```

Then open:
- 🤖 **AI Chat**: http://localhost:8080
- 🔄 **Workflows**: http://localhost:5678
- 🐳 **Management**: http://localhost:9000

## 🚀 Complete Setup Guide for Beginners

### Prerequisites
- macOS (any recent version)
- Internet connection
- Admin access to your Mac

### One-Command Setup (Recommended)

**For first-time users:**
```bash
# Clone the repository
git clone <your-repo-url>
cd local-ai-lab

# Complete guided setup
make first-time
```

**For quick setup:**
```bash
# One-command setup and start
make quick-start
```

### Manual Setup (Advanced Users)

#### Step 1: Install Docker Desktop

1. **Download Docker Desktop:**
   - Go to [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
   - Click "Download for Mac"
   - Choose your Mac chip (Apple Silicon or Intel)

2. **Install Docker Desktop:**
   ```bash
   # Open the downloaded .dmg file and drag Docker to Applications
   # Then run Docker Desktop from Applications folder
   ```

3. **Verify Installation:**
   ```bash
   # Open Terminal and run:
   docker --version
   docker compose --version
   ```

#### Step 2: Clone and Setup This Repository

1. **Clone the repository:**
   ```bash
   # Open Terminal and run:
   git clone <your-repo-url>
   cd local-ai-lab
   ```

2. **Run the automated setup:**
   ```bash
   # Run the complete setup
   make quick-start
   ```

3. **Check everything is working:**
   ```bash
   # Check service health
   make health

   # View service URLs
   make show-urls
   ```

### Step 3: Access Your Services

After setup, access your services at:

- **Open WebUI (AI Chat)**: http://localhost:8080
- **N8N (Workflow Automation)**: http://localhost:5678
- **Node-RED (Visual Programming)**: http://localhost:1880
- **CodeProject.AI (Computer Vision)**: http://localhost:32168
- **Portainer (Docker Management)**: http://localhost:9000
- **Traefik Dashboard**: http://localhost:8081
- **MCP Gateway**: http://localhost:8811

### Step 4: First Time Usage

1. **Open WebUI Setup:**
   - Go to http://localhost:8080
   - Create your admin account (or skip if auth is disabled)
   - AI models will be automatically available via Docker Model Runner
   - Test with a simple prompt like "Hello, how are you?"

2. **N8N Setup:**
   - Go to http://localhost:5678
   - Create your admin account
   - Start building AI-powered workflows
   - Import example workflows from the AI_WORKFLOW_SETUP_GUIDE.md

## 🤖 AI Features

- **Docker Model Runner**: No need to install Ollama separately
- **Multiple AI Models**: Access to various open-source models
- **Arena Mode**: Compare responses from different AI models side-by-side
- **AI Workflows**: Automate tasks with N8N + AI integration
- **Local Inference**: All AI processing happens on your machine
- **Model Comparison**: Test different models for your use case
- **Persistent Conversations**: Chat history saved locally
- **File Processing**: Upload and process documents with AI

## 🛠️ Management Commands

### Quick Commands (All via Makefile)
```bash
# Complete beginner setup
make first-time      # Guided first-time setup
make quick-start     # One-command setup and start

# Start/stop services
make local-start     # Local development with direct ports
make local-stop      # Stop local development
make start          # Production deployment
make stop           # Stop all services

# Monitoring & Health
make status         # Show service status and URLs
make health         # Comprehensive health check
make logs           # View all logs
make logs SERVICE=webui  # View specific service logs
make show-urls      # Display all service URLs

# Troubleshooting
make troubleshoot   # Interactive troubleshooting assistant
make optimize       # Resource optimization with interactive menu
make dev-reset      # Quick restart (keeps data)

# Backup & restore
make backup                    # Create backup (uncompressed)
make backup COMPRESS=true      # Create compressed backup
make restore BACKUP=20240101_120000  # Restore from backup
make list-backups             # List available backups

# Maintenance
make update         # Update all images
make clean          # Clean unused resources
make clean-reset    # Complete clean restart
```

## 📁 Project Structure

```
Docker/
├── docker-compose.yml              # Main service definitions
├── docker-compose.local.yml        # Local development overrides
├── Makefile                        # All management commands (consolidated)
├── nginx-ollama.conf               # Ollama proxy configuration
├── local-files/                    # Shared file storage (N8N)
├── backups/                        # Timestamped backup folders
│   └── YYYYMMDD_HHMMSS/           # Individual backup snapshots
│       ├── n8n_database.sql       # PostgreSQL database dump
│       ├── webui.db               # WebUI SQLite database
│       ├── n8n_data/              # N8N Docker volume backup
│       ├── webui_data/            # WebUI Docker volume backup
│       ├── nodered_data/          # Node-RED Docker volume backup
│       ├── codeprojectai_data/    # CodeProject.AI Docker volume backup
│       └── traefik_ssl/           # SSL certificates backup
└── README.md                       # This file
```

## 🔧 Configuration

The Makefile automatically configures:
- **Docker Model Runner**: For AI model inference
- **Dual API Support**: Both OpenAI API and Ollama endpoints
- **SSL Certificates**: For secure connections (production)
- **Persistent Storage**: Your data survives restarts in Docker volumes
- **Network Configuration**: Services can communicate
- **Local Development**: Direct port access for debugging
- **Enhanced Security**: Auto-generated encryption keys for N8N and WebUI
- **Environment Validation**: Checks required variables before deployment
- **Health Checks**: Monitors service health and dependencies
- **Service Dependencies**: Proper startup order (N8N waits for database)

### Production SSL Setup (Hurricane Electric DNS)

For production deployment with automatic SSL certificates:

1. **Get Hurricane Electric Account**:
   - Sign up at [dns.he.net](https://dns.he.net)
   - Add your domain to Hurricane Electric DNS
   - Update your domain's nameservers to Hurricane Electric

2. **Generate DNS API Token**:
   - Go to your domain settings in Hurricane Electric
   - Enable "Dynamic DNS" for your domain
   - Generate an API token for DNS challenges

3. **Configure Environment**:
   ```bash
   # Edit .env file
   DOMAIN_NAME=yourdomain.com
   SUBDOMAIN=app
   HURRICANE_TOKENS_PASSWORD=your_api_token_here
   SSL_EMAIL=admin@yourdomain.com
   ```

4. **Deploy with SSL**:
   ```bash
   make start  # Uses production configuration with SSL
   ```

**Services will be available at**:
- `https://webui.app.yourdomain.com` - Open WebUI
- `https://n8n.app.yourdomain.com` - N8N Workflows
- `https://portainer.app.yourdomain.com` - Portainer
- `https://traefik.app.yourdomain.com` - Traefik Dashboard

## 💾 Data Storage & Backup

### Where Your Data Lives
- **N8N workflows & credentials** → PostgreSQL database + `{folder-name}_n8n_data` volume
- **WebUI conversations & prompts** → SQLite database + `{folder-name}_webui_data` volume
- **SSL certificates** → `{folder-name}_traefik_data` volume
- **Node-RED flows & settings** → `{folder-name}_nodered_data` volume
- **CodeProject.AI models & config** → `{folder-name}_codeprojectai_data` volume
- **Shared files** → `local-files/` directory (host-mounted)

### Backup System
- **Uncompressed** (default): `make backup` - Faster, larger files
- **Compressed**: `make backup COMPRESS=true` - Slower, smaller files
- **Smart restore**: Auto-detects backup format and folder name
- **Complete coverage**: Databases, volumes, configs, and files

### Restore from Backup
```bash
# List available backups
make list-backups

# Restore specific backup
make restore BACKUP=20240101_120000

# Restore individual services
make restore-service BACKUP=20240101_120000 SERVICE=nodered
make restore-service BACKUP=20240101_120000 SERVICE=codeprojectai
```

**Available restore services**: `n8n`, `webui`, `traefik`, `nodered`, `codeprojectai`, `config`, `files`

## 🚫 Troubleshooting

### Quick Diagnosis
```bash
# Interactive troubleshooting assistant
make troubleshoot

# Comprehensive health check
make health

# Resource optimization
make optimize
```

### Common Issues

**Services won't start:**
```bash
# Check Docker is running
docker info

# Restart Docker Desktop from Applications
# Then try again:
make local-start
```

**Can't access services:**
```bash
# Check if ports are in use
lsof -i :8080
lsof -i :5678

# Show service URLs
make show-urls
```

**AI models not working:**
```bash
# Check Open WebUI logs
make logs SERVICE=webui

# Restart AI services
docker compose restart webui ollama-proxy
```

**Reset everything:**
```bash
# Complete clean restart
make clean-reset
make quick-start
```

## 📚 What's Included

- **Traefik**: Reverse proxy and load balancer
- **Open WebUI**: ChatGPT-like interface for AI models
- **N8N**: Visual workflow automation platform
- **Node-RED**: Flow-based visual programming for IoT
- **CodeProject.AI**: Computer vision and AI analysis
- **PostgreSQL**: Database for N8N workflows
- **Portainer**: Docker container management UI
- **MCP Gateway**: Model Context Protocol support
- **Ollama Proxy**: AI model inference bridge

## 🎯 Use Cases

- **AI Chat Interface**: Talk to various AI models locally
- **Workflow Automation**: Automate tasks with AI integration
- **Computer Vision**: Analyze images and video with CodeProject.AI
- **Document Processing**: AI-powered document analysis
- **Content Generation**: Create content with AI assistance
- **Data Analysis**: Process data using AI models
- **Model Comparison**: Test different AI models side-by-side
- **Development**: Build AI-powered applications

## 🔒 Security & Privacy

- **Local Processing**: All services run locally on your Mac
- **No External Data**: AI models and data stay on your machine
- **Private Conversations**: Chat history stored locally
- **Secure by Default**: Production deployment uses HTTPS
- **LDAP Integration**: Enterprise authentication support
- **Data Persistence**: Your data survives container restarts

### Local vs Production Security

**Local Development** (default):
- HTTP access for ease of development
- Authentication disabled by default
- Direct port access (8080, 5678, 9000, etc.)
- Self-signed certificates acceptable

**Production Deployment**:
- HTTPS with Let's Encrypt SSL certificates
- Hurricane Electric DNS challenge for wildcard certs
- LDAP authentication on sensitive endpoints
- Reverse proxy with Traefik
- Automatic certificate renewal

### SSL Certificate Management

The system uses **Let's Encrypt** with **Hurricane Electric DNS challenge**:
- **Wildcard certificates**: `*.yourdomain.com`
- **Automatic renewal**: Certificates auto-renew before expiry
- **DNS validation**: No need to expose port 80 publicly
- **Secure storage**: Certificates stored in Docker volumes

## 📖 Additional Resources

- **[🚀 Complete Beginner's Guide](GETTING_STARTED.md)**: Step-by-step setup for newcomers
- **[❓ Frequently Asked Questions](FAQ.md)**: Common questions and solutions
- **[🏗️ System Architecture](ARCHITECTURE.md)**: How everything works together
- **[🔐 LDAP Authentication](LDAP_AUTHENTICATION.md)**: Enterprise LDAP configuration guide
- **Makefile**: Advanced development commands

## 🆘 Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Look at service logs: `make logs SERVICE=service-name`
3. Try a clean restart: `make clean-reset && make beginner-setup`
4. Ensure Docker Desktop is running and updated
5. Check the additional documentation files

---

## ⚠️ **Important Legal Notice**

**NO WARRANTY OR LIABILITY**: This project is provided "AS IS" without any warranty. The authors are not responsible for any issues, damages, or problems that may occur from using this software. Use at your own risk and ensure you understand what you're installing.

**Ready to start?** Run `make first-time` for guided setup or `make quick-start` for instant deployment!
