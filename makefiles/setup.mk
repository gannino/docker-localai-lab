# Setup and Configuration Targets

check-env:
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
	else \
		echo "✅ Using .env configuration file"; \
	fi

validate: check-env ## Validate environment configuration
	@echo "🔍 Validating environment configuration..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
	fi
	@source .env && \
	MISSING="" && \
	if [ -z "$$DOMAIN_NAME" ]; then MISSING="$$MISSING DOMAIN_NAME"; fi && \
	if [ -z "$$SUBDOMAIN" ]; then MISSING="$$MISSING SUBDOMAIN"; fi && \
	if [ -z "$$PASSWORD" ] || [ $$(echo "$$PASSWORD" | wc -c) -lt 13 ]; then MISSING="$$MISSING PASSWORD(min_12_chars)"; fi && \
	if [ -z "$$POSTGRES_PASSWORD" ]; then MISSING="$$MISSING POSTGRES_PASSWORD"; fi && \
	if [ -z "$$WEBUI_SECRET_KEY" ] || [ "$$WEBUI_SECRET_KEY" = "change-me-to-random-32-char-hex" ]; then MISSING="$$MISSING WEBUI_SECRET_KEY"; fi && \
	if [ -n "$$MISSING" ]; then \
		echo "❌ Missing or default values for:$$MISSING"; \
		if echo "$$MISSING" | grep -q "WEBUI_SECRET_KEY\|N8N_ENCRYPTION_KEY"; then \
			echo "To generate keys, run: openssl rand -hex 32"; \
		fi; \
		echo "Please update your .env file with proper values."; \
		exit 1; \
	else \
		echo "✅ Environment validation passed"; \
	fi

beginner-setup: ## Complete beginner setup with Docker Model Runner
	@echo "🚀 Setting up Docker AI Infrastructure for Beginners"
	@echo "=================================================="
	@echo "📋 Creating environment configuration..."
	@cat > .env << 'EOF'
	# Admin Credentials
	USERNAME=admin
	PASSWORD=$$(openssl rand -hex 12)

	# Domain Configuration
	DOMAIN_NAME=example.com
	SUBDOMAIN=app
	GENERIC_TIMEZONE=America/New_York

	# Database Security
	POSTGRES_PASSWORD=$$(openssl rand -hex 16)
	N8N_ENCRYPTION_KEY=$$(openssl rand -hex 32)

	# WebUI Security
	WEBUI_SECRET_KEY=$$(openssl rand -hex 32)
	WEBUI_AUTH=false
	ENABLE_SIGNUP=false
	DEFAULT_USER_ROLE=user
	ENABLE_COMMUNITY_SHARING=false
	ENABLE_MESSAGE_RATING=true

	# API Configuration
	ENABLE_OPENAI_API=true
	ENABLE_OLLAMA_API=true
	OPENAI_API_KEY=not-needed

	# Service Images
	TRAEFIK_IMAGE=traefik:latest
	PORTAINER_IMAGE=portainer/portainer-ce:latest
	N8N_IMAGE=docker.n8n.io/n8nio/n8n:latest
	POSTGRES_IMAGE=postgres:15
	WEBUI_IMAGE=ghcr.io/open-webui/open-webui:main
	NODERED_IMAGE=nodered/node-red:latest
	CODEPROJECTAI_IMAGE=codeproject/ai-server:latest
	NGINX_IMAGE=nginx:alpine
	MCP_GATEWAY_IMAGE=mcp/gateway:latest
	EOF

setup-portainer: ## Setup Portainer admin user
	@echo "👤 Setting up Portainer admin user..."
	@if [ ! -f .env ]; then echo "Error: .env file not found"; exit 1; fi
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	echo "Waiting for Portainer to be ready..." && \
	sleep 10 && \
	curl -X POST https://portainer.$$DOMAIN/api/users/admin/init \
		-H "Content-Type: application/json" \
		-d '{"Username":"'$$USERNAME'","Password":"'$$PASSWORD'"}' \
		2>/dev/null && \
	echo "✅ Portainer admin user created with username: $$USERNAME" || \
	echo "ℹ️  Portainer admin user may already exist"

setup: ## Initial setup - create network and prepare environment
	@echo "🔧 Setting up Docker infrastructure..."
	@docker network create traefik-public 2>/dev/null || echo "Network already exists"
	@$(MAKE) setup-data
	@echo "✅ Setup complete"

setup-data: ## Create persistent data directories
	@echo "📁 Setting up persistent data directories..."
	@mkdir -p data/{n8n-workflows,n8n-credentials,webui-config,webui-uploads,mcp-config,postgres-backups}
	@mkdir -p local-files backups
	@chmod 755 data/ data/* 2>/dev/null || true
	@touch data/n8n-workflows/.gitkeep data/n8n-credentials/.gitkeep data/webui-config/.gitkeep
	@touch data/webui-uploads/.gitkeep data/mcp-config/.gitkeep data/postgres-backups/.gitkeep
	@echo "✅ Data directories created"

setup-nginx: ## Create nginx configuration
	@echo "🌐 Creating nginx configuration..."
	@cat > nginx-ollama.conf << 'EOF'
	events { worker_connections 1024; }
	http {
	    upstream ollama { server host.docker.internal:12434; }
	    server {
	        listen 80;
	        # Open WebUI compatibility - /ollama path (must come first)
	        location /ollama/ {
	            proxy_pass http://ollama/;
	            proxy_set_header Host $$host;
	            proxy_set_header X-Real-IP $$remote_addr;
	            proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
	            proxy_set_header X-Forwarded-Proto $$scheme;
	            proxy_buffering off;
			proxy_cache off;
	            proxy_read_timeout 300s;
			proxy_connect_timeout 75s;
	        }
	        # Direct Ollama API access
	        location / {
	            proxy_pass http://ollama;
	            proxy_set_header Host $$host;
	            proxy_set_header X-Real-IP $$remote_addr;
	            proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
	            proxy_set_header X-Forwarded-Proto $$scheme;
	            proxy_buffering off;
			proxy_cache off;
	            proxy_read_timeout 300s;
			proxy_connect_timeout 75s;
	        }
	    }
	}
	EOF
	@echo "✅ Nginx configuration created"

setup-rosetta: ## Architecture-specific setup for Apple Silicon
	@if [[ "$$(uname -m)" == "arm64" ]]; then \
		echo "🍎 Apple Silicon detected - checking Rosetta..."; \
		if arch -x86_64 /usr/bin/true >/dev/null 2>&1; then \
			echo "   ✅ Rosetta is installed and working"; \
			echo "   ✅ Node-RED: Running via Rosetta emulation"; \
			echo "   ✅ CodeProject.AI: Running via Rosetta emulation"; \
			echo "   💡 Tip: Enable 'Use Rosetta for x86/amd64 emulation' in Docker Desktop"; \
		else \
			echo "   ⚠️  Rosetta not installed - installing now..."; \
			/usr/sbin/softwareupdate --install-rosetta --agree-to-license; \
			if arch -x86_64 /usr/bin/true >/dev/null 2>&1; then \
				echo "   ✅ Rosetta installed successfully"; \
				echo "   ✅ Node-RED: Ready for Rosetta emulation"; \
				echo "   ✅ CodeProject.AI: Ready for Rosetta emulation"; \
				echo "   💡 Tip: Enable 'Use Rosetta for x86/amd64 emulation' in Docker Desktop"; \
			else \
				echo "   ❌ Rosetta installation failed"; \
				echo "   ⚠️  x86 services may not work properly"; \
			fi; \
		fi; \
	else \
		echo "💻 Intel Mac detected - all services supported natively"; \
	fi

quick-start: ## One-command setup and start for new users
	@echo "🚀 Docker AI Lab - One-Command Setup"
	@echo "===================================="
	@if ! command -v docker &> /dev/null; then \
		echo "❌ Docker not found. Please install Docker Desktop first:"; \
		echo "   https://www.docker.com/products/docker-desktop/"; \
		exit 1; \
	fi
	@if ! docker info &> /dev/null; then \
		echo "❌ Docker is not running. Please start Docker Desktop and try again."; \
		exit 1; \
	fi
	@if [ ! -f .env ]; then \
		echo "📋 Creating environment configuration..."; \
		cp .env.example .env; \
		RANDOM_PASSWORD=$$(openssl rand -hex 12); \
		POSTGRES_PASSWORD=$$(openssl rand -hex 16); \
		N8N_KEY=$$(openssl rand -hex 32); \
		WEBUI_KEY=$$(openssl rand -hex 32); \
		sed -i.bak "s/PASSWORD=change-me/PASSWORD=$$RANDOM_PASSWORD/" .env; \
		sed -i.bak "s/POSTGRES_PASSWORD=change-me/POSTGRES_PASSWORD=$$POSTGRES_PASSWORD/" .env; \
		sed -i.bak "s/N8N_ENCRYPTION_KEY=change-me-to-random-32-char-hex/N8N_ENCRYPTION_KEY=$$N8N_KEY/" .env; \
		sed -i.bak "s/WEBUI_SECRET_KEY=change-me-to-random-32-char-hex/WEBUI_SECRET_KEY=$$WEBUI_KEY/" .env; \
		sed -i.bak "s/WEBUI_AUTH=true/WEBUI_AUTH=false/" .env; \
		rm .env.bak; \
		echo "✅ Environment configured with secure random passwords"; \
	fi
	@$(MAKE) setup-data
	@$(MAKE) setup-rosetta
	@docker network create traefik-public 2>/dev/null || echo "Network already exists"
	@$(MAKE) local-start
	@echo "⏳ Waiting for services to start..."
	@sleep 15
	@echo ""
	@echo "🎉 Setup Complete!"
	@echo "=================="
	@echo ""
	@$(MAKE) show-urls
	@echo ""
	@echo "💡 Tips:"
	@echo "   • No login required for local development"
	@echo "   • AI models will download automatically when first used"
	@echo "   • Use 'make status' to check service health"
	@echo "   • Use 'make logs' to view service logs"
	@echo ""
	@echo "🆘 Need help? Run 'make help' for all available commands"

first-time: ## Complete first-time setup with guided tour
	@echo "👋 Welcome to Docker AI Lab!"
	@echo "============================="
	@echo ""
	@echo "This will set up a complete AI development environment with:"
	@echo "• 🤖 Open WebUI - ChatGPT-like interface for AI models"
	@echo "• 🔄 N8N - Visual workflow automation"
	@echo "• 🐳 Portainer - Docker container management"
	@echo "• 📊 Traefik - Reverse proxy and dashboard"
	@echo ""
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(MAKE) quick-start
	@echo ""
	@echo "🎉 Setup complete! Here's what to do next:"
	@echo ""
	@echo "1. 🤖 Try AI Chat:"
	@echo "   • Open http://localhost:8080"
	@echo "   • No login required for local development"
	@echo "   • AI models will download automatically"
	@echo ""
	@echo "2. 🔄 Create Workflows:"
	@echo "   • Open http://localhost:5678"
	@echo "   • Create your first automation workflow"
	@echo ""
	@echo "3. 🐳 Manage Containers:"
	@echo "   • Open http://localhost:9000"
	@echo "   • Monitor your Docker containers"
	@echo ""
	@echo "💡 Run 'make help' anytime to see all available commands"
