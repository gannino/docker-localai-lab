.PHONY: help start stop restart status logs clean backup update setup local-start local-stop beginner-setup test test-services test-quick test-config pre-commit-install pre-commit-run lint restore-service restore-n8n restore-webui restore-traefik restore-config restore-files

# Default target
help: ## Show this help message
	@echo "Docker Infrastructure - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Helper function to check and source .env
check-env:
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
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


start: validate setup-rosetta ## Start all services (production)
	@echo "🚀 Starting all services..."
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
	docker network create traefik-public 2>/dev/null || true && \
	docker compose up -d

stop: ## Stop all services
	@echo "🛑 Stopping all services..."
	@docker compose down

restart: stop start ## Restart all services

start-service: ## Start specific service (use: make start-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make start-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@if [ -f .env ]; then \
		source .env && \
		export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
		export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
		docker network create traefik-public 2>/dev/null || true && \
		docker compose up -d $(SERVICE); \
	else \
		echo "Error: .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
	fi

stop-service: ## Stop specific service (use: make stop-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make stop-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@docker compose stop $(SERVICE)

restart-service: ## Restart specific service (use: make restart-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make restart-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@if [ -f .env ]; then \
		source .env && \
		export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
		export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
		docker network create traefik-public 2>/dev/null || true && \
		docker compose stop $(SERVICE) && \
		docker compose up -d $(SERVICE); \
	else \
		echo "Error: .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
	fi

status: ## Show service status and URLs
	@echo "📊 Service Status:"
	@if [ -f .env ]; then \
		source .env && \
		export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
		export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
		docker compose ps; \
	else \
		docker compose ps; \
	fi
	@echo ""
	@if [ -f .env ]; then \
		source .env 2>/dev/null && echo "🌐 Service URLs:" && \
		echo "   Traefik:       https://traefik.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   Portainer:     https://portainer.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   N8N:           https://n8n.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   Node-RED:      https://nodered.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   CodeProject.AI: https://codeprojectai.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   MCP Gateway:   https://mcp.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   Ollama Proxy:  https://oi.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   WebUI:         https://webui.$$SUBDOMAIN.$$DOMAIN_NAME" && \
		echo "   Echo IP:       https://echo.$$SUBDOMAIN.$$DOMAIN_NAME"; \
	else \
		echo "🌐 Local URLs:" && \
		echo "   WebUI:         http://localhost:8080" && \
		echo "   N8N:           http://localhost:5678" && \
		echo "   Node-RED:      http://localhost:1880" && \
		echo "   CodeProject.AI: http://localhost:32168" && \
		echo "   Portainer:     http://localhost:9000" && \
		echo "   Traefik:       http://localhost:8081" && \
		echo "   MCP Gateway:   http://localhost:8811"; \
	fi

logs: ## Show logs for all services (use 'make logs SERVICE=servicename' for specific service)
	@if [ -n "$(SERVICE)" ]; then \
		echo "📋 Showing logs for $(SERVICE)..."; \
		docker compose logs -f $(SERVICE); \
	else \
		echo "📋 Showing logs for all services..."; \
		docker compose logs -f; \
	fi

clean: ## Clean up unused Docker resources
	@echo "🧹 Cleaning up unused resources..."
	@docker compose down
	@docker system prune -f
	@docker volume prune -f
	@echo "✅ Cleanup complete"

clean-reset: ## Complete clean restart (removes all data)
	@echo "🧹 Cleaning Docker setup - removing all volumes and data..."
	@docker compose down
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume rm $${PROJECT_NAME}_traefik_data $${PROJECT_NAME}_portainer_data $${PROJECT_NAME}_n8n_data $${PROJECT_NAME}_db_data $${PROJECT_NAME}_webui_data 2>/dev/null || true
	@rm -rf data/
	@docker container prune -f
	@docker volume prune -f
	@echo "✅ Clean complete! Run 'make beginner-setup' to start fresh."

backup: check-env ## Backup persistent data (use: make backup COMPRESS=true for compression)
	@echo "💾 Creating backup..."
	@BACKUP_DATE=$$(date +%Y%m%d_%H%M%S) && \
	PROJECT_NAME=$$(basename $$(pwd)) && \
	source .env && mkdir -p backups/$$BACKUP_DATE && \
	echo "Backing up PostgreSQL database (SQL dump)..." && \
	docker exec $$(docker compose ps -q n8n-db) pg_dump -U n8n -d n8n > backups/$$BACKUP_DATE/n8n_database.sql 2>/dev/null || echo "Database dump failed" && \
	echo "Backing up WebUI SQLite database..." && \
	docker exec $$(docker compose ps -q webui) cp /app/backend/data/webui.db /tmp/webui_backup.db && \
	docker cp $$(docker compose ps -q webui):/tmp/webui_backup.db backups/$$BACKUP_DATE/webui.db 2>/dev/null || echo "WebUI database backup failed" && \
	echo "Backing up actual user data from Docker volumes..." && \
	if [ "$(COMPRESS)" = "true" ]; then \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$$BACKUP_DATE:/backup alpine tar czf /backup/n8n_data.tar.gz -C /data . 2>/dev/null || echo "N8N data not found"; \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$$BACKUP_DATE:/backup alpine tar czf /backup/webui_data.tar.gz -C /data . 2>/dev/null || echo "WebUI data not found"; \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$$BACKUP_DATE:/backup alpine tar czf /backup/traefik_ssl.tar.gz -C /data . 2>/dev/null || echo "SSL certs not found"; \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$$BACKUP_DATE:/backup alpine tar czf /backup/nodered_data.tar.gz -C /data . 2>/dev/null || echo "Node-RED data not found"; \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$$BACKUP_DATE:/backup alpine tar czf /backup/codeprojectai_data.tar.gz -C /data . 2>/dev/null || echo "CodeProject.AI data not found"; \
	else \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$$BACKUP_DATE/n8n_data:/backup alpine cp -r /data/. /backup/ 2>/dev/null || echo "N8N data not found"; \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$$BACKUP_DATE/webui_data:/backup alpine cp -r /data/. /backup/ 2>/dev/null || echo "WebUI data not found"; \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$$BACKUP_DATE/traefik_ssl:/backup alpine cp -r /data/. /backup/ 2>/dev/null || echo "SSL certs not found"; \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$$BACKUP_DATE/nodered_data:/backup alpine cp -r /data/. /backup/ 2>/dev/null || echo "Node-RED data not found"; \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$$BACKUP_DATE/codeprojectai_data:/backup alpine cp -r /data/. /backup/ 2>/dev/null || echo "CodeProject.AI data not found"; \
	fi && \
	echo "Backing up host directories and configs..." && \
	cp -r local-files/ backups/$$BACKUP_DATE/ 2>/dev/null || echo "local-files/ not found" && \
	cp .env docker-compose.yml docker-compose.local.yml nginx-ollama.conf backups/$$BACKUP_DATE/ 2>/dev/null || true && \
	echo "✅ Backup completed: backups/$$BACKUP_DATE/" && \
	echo "   📊 N8N workflows & config: n8n_database.sql + n8n_data/" && \
	echo "   🤖 WebUI conversations & prompts: webui.db + webui_data/" && \
	echo "   🔒 SSL certificates: traefik_ssl/" && \
	echo "   🔎 Node-RED flows & settings: nodered_data/" && \
	echo "   📷 CodeProject.AI models & config: codeprojectai_data/"

restore: ## Restore from backup (use: make restore BACKUP=20240101_120000)
	@if [ -z "$(BACKUP)" ]; then \
		echo "Error: Please specify backup folder. Usage: make restore BACKUP=20240101_120000"; \
		echo "Available backups:"; \
		ls -1 backups/ 2>/dev/null || echo "No backups found"; \
		exit 1; \
	fi
	@if [ ! -d "backups/$(BACKUP)" ]; then \
		echo "Error: Backup folder backups/$(BACKUP) not found"; \
		exit 1; \
	fi
	@echo "🔄 Restoring from backup: $(BACKUP)"
	@echo "Stopping services..."
	@docker compose down
	@echo "Restoring configuration files..."
	@cp backups/$(BACKUP)/.env backups/$(BACKUP)/docker-compose.yml backups/$(BACKUP)/nginx-ollama.conf . 2>/dev/null || echo "Some config files not found in backup"
	@echo "Creating Docker volumes..."
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_n8n_data 2>/dev/null || true && \
	docker volume create $${PROJECT_NAME}_webui_data 2>/dev/null || true && \
	docker volume create $${PROJECT_NAME}_traefik_data 2>/dev/null || true && \
	docker volume create $${PROJECT_NAME}_nodered_data 2>/dev/null || true && \
	docker volume create $${PROJECT_NAME}_codeprojectai_data 2>/dev/null || true
	@echo "Restoring Docker volumes..."
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	if [ -f "backups/$(BACKUP)/n8n_data.tar.gz" ]; then \
		echo "Restoring compressed volumes..."; \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/n8n_data.tar.gz" 2>/dev/null || echo "N8N data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/webui_data.tar.gz" 2>/dev/null || echo "WebUI data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/traefik_ssl.tar.gz" 2>/dev/null || echo "SSL certs restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/nodered_data.tar.gz" 2>/dev/null || echo "Node-RED data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/codeprojectai_data.tar.gz" 2>/dev/null || echo "CodeProject.AI data restore failed"; \
	elif [ -d "backups/$(BACKUP)/n8n_data" ]; then \
		echo "Restoring uncompressed volumes..."; \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$(BACKUP)/n8n_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "N8N data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$(BACKUP)/webui_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "WebUI data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$(BACKUP)/traefik_ssl:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "SSL certs restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$(BACKUP)/nodered_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "Node-RED data restore failed"; \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$(BACKUP)/codeprojectai_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "CodeProject.AI data restore failed"; \
	else \
		echo "⚠️  No volume data found in backup"; \
	fi
	@echo "Restoring host directories..."
	@cp -r backups/$(BACKUP)/local-files/ . 2>/dev/null || echo "local-files not found in backup"
	@echo "Starting database for SQL restore..."
	@if [ -f .env ]; then \
		source .env && export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
		docker network create traefik-public 2>/dev/null || true && \
		docker compose up -d n8n-db && \
		echo "Waiting for database to be ready..." && sleep 15 && \
		if [ -f "backups/$(BACKUP)/n8n_database.sql" ]; then \
			echo "Restoring N8N database..."; \
			docker exec -i $$(docker compose ps -q n8n-db) psql -U n8n -d n8n < backups/$(BACKUP)/n8n_database.sql 2>/dev/null || echo "Database restore failed - this is normal for fresh installs"; \
		else \
			echo "No database backup found"; \
		fi; \
	else \
		echo "No .env file found after restore"; \
	fi
	@echo "✅ Restore completed. Run 'make start' or 'make local-start' to start services"

	restore-service: ## Restore specific service (use: make restore-service BACKUP=20240101_120000 SERVICE=n8n)
	@if [ -z "$(BACKUP)" ] || [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify both backup and service. Usage: make restore-service BACKUP=20240101_120000 SERVICE=n8n"; \
		echo "Available services: n8n, webui, traefik, nodered, codeprojectai, config, files"; \
		echo "Available backups:"; \
		ls -1 backups/ 2>/dev/null || echo "No backups found"; \
		exit 1; \
	fi
	@if [ ! -d "backups/$(BACKUP)" ]; then \
		echo "Error: Backup folder backups/$(BACKUP) not found"; \
		exit 1; \
	fi
	@echo "🔄 Restoring $(SERVICE) from backup: $(BACKUP)"
	@case "$(SERVICE)" in \
		n8n) $(MAKE) restore-n8n BACKUP=$(BACKUP) ;; \
		webui) $(MAKE) restore-webui BACKUP=$(BACKUP) ;; \
		traefik) $(MAKE) restore-traefik BACKUP=$(BACKUP) ;; \
		nodered) $(MAKE) restore-nodered BACKUP=$(BACKUP) ;; \
		codeprojectai) $(MAKE) restore-codeprojectai BACKUP=$(BACKUP) ;; \
		config) $(MAKE) restore-config BACKUP=$(BACKUP) ;; \
		files) $(MAKE) restore-files BACKUP=$(BACKUP) ;; \
		*) echo "Error: Unknown service $(SERVICE). Available: n8n, webui, traefik, nodered, codeprojectai, config, files"; exit 1 ;; \
	esac

restore-n8n: ## Restore N8N service data (internal use)
	@echo "📊 Restoring N8N workflows and database..."
	@docker compose stop n8n 2>/dev/null || true
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_n8n_data 2>/dev/null || true && \
	if [ -f "backups/$(BACKUP)/n8n_data.tar.gz" ]; then \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/n8n_data.tar.gz" 2>/dev/null || echo "N8N data restore failed"; \
	elif [ -d "backups/$(BACKUP)/n8n_data" ]; then \
		docker run --rm -v $${PROJECT_NAME}_n8n_data:/data -v $$(pwd)/backups/$(BACKUP)/n8n_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "N8N data restore failed"; \
	fi && \
	if [ -f "backups/$(BACKUP)/n8n_database.sql" ]; then \
		echo "Starting database for restore..."; \
		docker compose up -d n8n-db && sleep 10 && \
		docker exec -i $$(docker compose ps -q n8n-db) psql -U n8n -d n8n < backups/$(BACKUP)/n8n_database.sql 2>/dev/null || echo "Database restore failed"; \
	fi
	@echo "✅ N8N restore completed. Run 'make start-service SERVICE=n8n' to start"

restore-webui: ## Restore WebUI service data (internal use)
	@echo "🤖 Restoring WebUI conversations and settings..."
	@docker compose stop webui 2>/dev/null || true
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_webui_data 2>/dev/null || true && \
	if [ -f "backups/$(BACKUP)/webui_data.tar.gz" ]; then \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/webui_data.tar.gz" 2>/dev/null || echo "WebUI data restore failed"; \
	elif [ -d "backups/$(BACKUP)/webui_data" ]; then \
		docker run --rm -v $${PROJECT_NAME}_webui_data:/data -v $$(pwd)/backups/$(BACKUP)/webui_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "WebUI data restore failed"; \
	fi && \
	if [ -f "backups/$(BACKUP)/webui.db" ]; then \
		echo "Restoring WebUI database..."; \
		docker compose up -d webui && sleep 5 && \
		docker cp backups/$(BACKUP)/webui.db $$(docker compose ps -q webui):/app/backend/data/webui.db 2>/dev/null || echo "WebUI database restore failed"; \
		docker compose restart webui; \
	fi
	@echo "✅ WebUI restore completed. Run 'make start-service SERVICE=webui' to start"

restore-traefik: ## Restore Traefik SSL certificates (internal use)
	@echo "🔒 Restoring SSL certificates..."
	@docker compose stop traefik 2>/dev/null || true
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_traefik_data 2>/dev/null || true && \
	if [ -f "backups/$(BACKUP)/traefik_ssl.tar.gz" ]; then \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/traefik_ssl.tar.gz" 2>/dev/null || echo "SSL certs restore failed"; \
	elif [ -d "backups/$(BACKUP)/traefik_ssl" ]; then \
		docker run --rm -v $${PROJECT_NAME}_traefik_data:/data -v $$(pwd)/backups/$(BACKUP)/traefik_ssl:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "SSL certs restore failed"; \
	fi
	@echo "✅ Traefik restore completed. Run 'make start-service SERVICE=traefik' to start"

restore-config: ## Restore configuration files (internal use)
	@echo "⚙️  Restoring configuration files..."
	@cp backups/$(BACKUP)/.env backups/$(BACKUP)/docker-compose.yml backups/$(BACKUP)/nginx-ollama.conf . 2>/dev/null || echo "Some config files not found in backup"
	@echo "✅ Configuration files restored"

restore-files: ## Restore shared files directory (internal use)
	@echo "📁 Restoring shared files..."
	@cp -r backups/$(BACKUP)/local-files/ . 2>/dev/null || echo "local-files not found in backup"
	@echo "✅ Shared files restored"

list-backups: ## List available backups
	@echo "💾 Available backups:"
	@ls -la backups/ 2>/dev/null || echo "No backups found"

update: ## Update all images and restart services
	@echo "🔄 Updating all images..."
	@if [ -f .env ]; then \
		source .env && \
		export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
		export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
		docker compose pull && \
		echo "🔄 Restarting services with new images..." && \
		docker compose up -d && \
		echo "✅ Update complete - services restarted with latest images"; \
	else \
		echo "Error: .env file not found. Run 'make beginner-setup' first."; \
		exit 1; \
	fi

local-start: ## Start with local development overrides (direct port access)
	@echo "🔧 Starting with local development configuration..."
	@if [[ "$$(uname -m)" == "arm64" ]]; then \
		echo "🍎 Apple Silicon detected - CodeProject.AI disabled (Intel only)"; \
		docker compose -f docker-compose.yml -f docker-compose.local.yml up -d; \
	else \
		echo "💻 Intel Mac detected - all services enabled"; \
		docker compose -f docker-compose.yml -f docker-compose.local.yml --profile intel up -d; \
	fi
	@echo "✅ Local development environment started"
	@echo "📍 Local access URLs:"
	@echo "   🤖 Open WebUI (AI Chat): http://localhost:8080"
	@echo "   🔄 N8N (Workflows):      http://localhost:5678"
	@echo "   🔎 Node-RED (Flows):     http://localhost:1880"
	@if [[ "$$(uname -m)" != "arm64" ]]; then \
		echo "   📷 CodeProject.AI (CV):   http://localhost:32168"; \
	fi
	@echo "   🐳 Portainer (Docker):   http://localhost:9000"
	@echo "   📊 Traefik Dashboard:    http://localhost:8081"
	@echo "   🌐 MCP Gateway:          http://localhost:8811"

local-stop: ## Stop local development environment
	@echo "🛑 Stopping local development environment..."
	@docker compose -f docker-compose.yml -f docker-compose.local.yml down

local-status: ## Show local development status
	@echo "📊 Local Development Status:"
	@docker compose -f docker-compose.yml -f docker-compose.local.yml ps
	@echo ""
	@echo "🌐 Local Access URLs:"
	@echo "   🤖 Open WebUI: http://localhost:8080"
	@echo "   🔄 N8N: http://localhost:5678"
	@echo "   🐳 Portainer: http://localhost:9000"
	@echo "   📊 Traefik: http://localhost:8081"

local-logs: ## Show logs for local development (use 'make local-logs SERVICE=servicename' for specific service)
	@if [ -n "$(SERVICE)" ]; then \
		echo "📋 Showing local logs for $(SERVICE)..."; \
		docker compose -f docker-compose.yml -f docker-compose.local.yml logs -f $(SERVICE); \
	else \
		echo "📋 Showing local logs for all services..."; \
		docker compose -f docker-compose.yml -f docker-compose.local.yml logs -f; \
	fi

# Convenience aliases
up: start ## Alias for start
down: stop ## Alias for stop
ps: status ## Alias for status
local: local-start ## Alias for local-start

# Development commands
test: ## Run test suite
	@echo "🧪 Docker AI Lab - Test Suite"
	@echo "=============================="
	@TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; \
	test_result() { \
		TESTS_RUN=$$((TESTS_RUN + 1)); \
		if [ $$1 -eq 0 ]; then \
			echo "✅ PASS: $$2"; TESTS_PASSED=$$((TESTS_PASSED + 1)); \
		else \
			echo "❌ FAIL: $$2"; TESTS_FAILED=$$((TESTS_FAILED + 1)); \
		fi; \
	}; \
	echo "🐳 Testing Docker availability..."; \
	if command -v docker >/dev/null 2>&1; then test_result 0 "Docker command available"; else test_result 1 "Docker command not found"; fi; \
	if docker info >/dev/null 2>&1; then test_result 0 "Docker daemon running"; else test_result 1 "Docker daemon not running"; fi; \
	if docker compose version >/dev/null 2>&1; then test_result 0 "Docker Compose available"; else test_result 1 "Docker Compose not available"; fi; \
	echo "📝 Testing configuration files..."; \
	if [ -f "docker-compose.yml" ]; then test_result 0 "docker-compose.yml exists"; \
		if docker compose -f docker-compose.yml config >/dev/null 2>&1; then test_result 0 "docker-compose.yml is valid"; else test_result 1 "docker-compose.yml has syntax errors"; fi; \
	else test_result 1 "docker-compose.yml missing"; fi; \
	if [ -f "docker-compose.local.yml" ]; then test_result 0 "docker-compose.local.yml exists"; \
		if docker compose -f docker-compose.yml -f docker-compose.local.yml config >/dev/null 2>&1; then test_result 0 "docker-compose.local.yml is valid"; else test_result 1 "docker-compose.local.yml has syntax errors"; fi; \
	else test_result 1 "docker-compose.local.yml missing"; fi; \
	if [ -f ".env.example" ]; then test_result 0 ".env.example exists"; else test_result 1 ".env.example missing"; fi; \
	if [ -f "Makefile" ]; then test_result 0 "Makefile exists"; \
		if make -n help >/dev/null 2>&1; then test_result 0 "Makefile syntax is valid"; else test_result 1 "Makefile has syntax errors"; fi; \
	else test_result 1 "Makefile missing"; fi; \
	echo "🌐 Testing Docker network..."; \
	if docker network create traefik-public 2>/dev/null || docker network inspect traefik-public >/dev/null 2>&1; then test_result 0 "traefik-public network available"; else test_result 1 "Failed to create traefik-public network"; fi; \
	echo "📚 Testing documentation..."; \
	for doc in README.md GETTING_STARTED.md docs/FAQ.md docs/ARCHITECTURE.md; do \
		if [ -f "$$doc" ]; then test_result 0 "$$doc exists"; else test_result 1 "$$doc missing"; fi; \
	done; \
	echo ""; echo "🏁 Test Results"; echo "==============="; \
	echo "Tests run: $$TESTS_RUN"; echo "Passed: $$TESTS_PASSED"; echo "Failed: $$TESTS_FAILED"; \
	if [ $$TESTS_FAILED -eq 0 ]; then echo "🎉 All tests passed!"; else echo "💥 Some tests failed!"; exit 1; fi

test-services: ## Test service startup and accessibility
	@echo "🚀 Testing service startup..."
	@if ! docker compose ps | grep -q "Up"; then \
		echo "Starting services for testing..."; \
		if timeout 120 docker compose -f docker-compose.yml -f docker-compose.local.yml up -d; then \
			echo "✅ Services started successfully"; sleep 30; \
			if docker compose ps | grep -q "webui.*Up"; then echo "✅ WebUI service is running"; else echo "❌ WebUI service failed"; fi; \
			if docker compose ps | grep -q "n8n-db.*Up"; then echo "✅ Database service is running"; else echo "❌ Database service failed"; fi; \
			if curl -s --max-time 10 http://localhost:8080 >/dev/null; then echo "✅ WebUI is accessible"; else echo "❌ WebUI not accessible"; fi; \
			echo "Stopping test services..."; docker compose -f docker-compose.yml -f docker-compose.local.yml down; \
		else echo "❌ Failed to start services"; exit 1; fi; \
	else echo "⚠️  Services already running, skipping startup test"; fi

test-quick: ## Run quick tests (no service startup)
	@$(MAKE) test

test-config: ## Test configuration files only
	@echo "📝 Testing configuration files..."
	@docker compose -f docker-compose.yml config --quiet && echo "✅ docker-compose.yml valid"
	@docker compose -f docker-compose.yml -f docker-compose.local.yml config --quiet && echo "✅ docker-compose.local.yml valid"
	@make -n help > /dev/null && echo "✅ Makefile syntax valid"

pre-commit-install: ## Install pre-commit hooks
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "✅ Pre-commit hooks installed"; \
	else \
		echo "❌ Pre-commit not found. Install with: pip install pre-commit"; \
	fi

pre-commit-run: ## Run pre-commit hooks on all files
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "❌ Pre-commit not found. Install with: pip install pre-commit"; \
	fi

lint: ## Run linting checks
	@echo "🔍 Running linting checks..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -not -path "./legacy/*" -exec shellcheck {} \; && echo "✅ Shell scripts OK"; \
	else \
		echo "⚠️  Shellcheck not found, skipping shell script checks"; \
	fi
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint docker-compose*.yml .github/workflows/*.yml && echo "✅ YAML files OK"; \
	else \
		echo "⚠️  yamllint not found, skipping YAML checks"; \
	fi

# New convenience commands
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

health: ## Run comprehensive health check
	@echo "🏥 Docker AI Lab - Health Check"
	@echo "==============================="
	@echo ""
	@if ! docker info &> /dev/null; then \
		echo "❌ Docker is not running"; \
		exit 1; \
	fi
	@echo "✅ Docker is running"
	@if [ ! -f docker-compose.yml ]; then \
		echo "❌ docker-compose.yml not found"; \
		exit 1; \
	fi
	@echo ""
	@echo "📊 Service Status:"
	@echo "------------------"
	@ALL_HEALTHY=true; \
	for service in traefik n8n-db n8n webui portainer ollama-proxy mcp-gateway; do \
		if docker compose ps --format "table" | grep -q "$$service.*Up"; then \
			if docker compose ps --format "table" | grep "$$service" | grep -q "healthy"; then \
				echo "✅ $$service - Running (Healthy)"; \
			elif docker compose ps --format "table" | grep "$$service" | grep -q "unhealthy"; then \
				echo "⚠️  $$service - Running (Unhealthy)"; \
				ALL_HEALTHY=false; \
			else \
				echo "🟡 $$service - Running (No health check)"; \
			fi; \
		else \
			echo "❌ $$service - Not running"; \
			ALL_HEALTHY=false; \
		fi; \
	done; \
	echo ""; \
	echo "🌐 Service Accessibility:"; \
	echo "-------------------------"; \
	for endpoint in "http://localhost:8080|Open WebUI" "http://localhost:5678|N8N" "http://localhost:9000|Portainer" "http://localhost:8081|Traefik" "http://localhost:8811|MCP Gateway"; do \
		url=$$(echo $$endpoint | cut -d'|' -f1); \
		name=$$(echo $$endpoint | cut -d'|' -f2); \
		if curl -s --max-time 5 "$$url" > /dev/null 2>&1; then \
			echo "✅ $$name - Accessible"; \
		else \
			echo "❌ $$name - Not accessible"; \
			ALL_HEALTHY=false; \
		fi; \
	done; \
	echo ""; \
	if [ "$$ALL_HEALTHY" = "true" ]; then \
		echo "🎉 All systems healthy!"; \
	else \
		echo "⚠️  Some issues detected. Run 'make logs' for details."; \
		echo ""; \
		echo "🔧 Quick fixes:"; \
		echo "   • Restart services: make local-stop && make local-start"; \
		echo "   • Check logs: make logs SERVICE=<service-name>"; \
		echo "   • Complete reset: make clean-reset && make quick-start"; \
	fi

optimize: ## Optimize resource usage for your system
	@echo "⚡ Docker AI Lab - Resource Optimization"
	@echo "========================================"
	@echo "🖥️  System Resources:"
	@echo "--------------------"
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		total_ram=$$(sysctl -n hw.memsize); \
		total_ram_gb=$$((total_ram / 1024 / 1024 / 1024)); \
		cpu_cores=$$(sysctl -n hw.ncpu); \
		echo "   RAM: $${total_ram_gb}GB"; \
		echo "   CPU Cores: $${cpu_cores}"; \
		echo ""; \
		echo "🐳 Docker Desktop Recommendations:"; \
		echo "----------------------------------"; \
		if [ $$total_ram_gb -lt 8 ]; then \
			echo "⚠️  Low RAM detected ($${total_ram_gb}GB)"; \
			echo "   Recommended: Allocate 4GB to Docker Desktop"; \
		elif [ $$total_ram_gb -lt 16 ]; then \
			echo "✅ Adequate RAM ($${total_ram_gb}GB)"; \
			echo "   Recommended: Allocate 6-8GB to Docker Desktop"; \
		else \
			echo "🚀 Excellent RAM ($${total_ram_gb}GB)"; \
			echo "   Recommended: Allocate 8-12GB to Docker Desktop"; \
		fi; \
	fi
	@echo ""
	@echo "🔧 Optimization Options:"
	@echo "------------------------"
	@if docker compose ps | grep -q "Up"; then \
		echo "1. 🎯 Minimal Setup (WebUI + Database only)"; \
		echo "2. 🔄 Standard Setup (WebUI + N8N + Database)"; \
		echo "3. 🚀 Full Setup (All services)"; \
		echo "4. 📊 Show current resource usage"; \
		echo "5. 🧹 Clean unused resources"; \
		echo ""; \
		read -p "Choose optimization (1-5): " choice; \
		case $$choice in \
			1) echo "🎯 Starting minimal setup..."; docker compose -f docker-compose.yml -f docker-compose.local.yml up -d n8n-db webui ;; \
			2) echo "🔄 Starting standard setup..."; docker compose -f docker-compose.yml -f docker-compose.local.yml up -d n8n-db n8n webui ;; \
			3) echo "🚀 Starting full setup..."; $(MAKE) local-start ;; \
			4) echo "📊 Current resource usage:"; docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" ;; \
			5) echo "🧹 Cleaning unused resources..."; docker system prune -f; docker volume prune -f; docker image prune -f; echo "✅ Cleanup complete" ;; \
			*) echo "Invalid choice" ;; \
		esac; \
	else \
		echo "No services currently running."; \
		echo "Run 'make quick-start' to start with optimal configuration."; \
	fi
	@echo ""
	@echo "💡 Performance Tips:"
	@echo "-------------------"
	@echo "• Use SSD storage for Docker volumes"
	@echo "• Close unused applications to free RAM"
	@echo "• Enable Docker Desktop's 'Use Rosetta for x86/amd64 emulation' on Apple Silicon"
	@echo "• Regularly run 'make clean' to free disk space"
	@echo "• Monitor resource usage with 'docker stats'"

troubleshoot: ## Interactive troubleshooting assistant
	@echo "🔧 Docker AI Lab - Troubleshooting Assistant"
	@echo "============================================="
	@echo ""
	@echo "What issue are you experiencing?"
	@echo ""
	@echo "1. 🚫 Services won't start"
	@echo "2. 🌐 Can't access web interfaces"
	@echo "3. 🤖 AI models not working"
	@echo "4. 💾 Database connection issues"
	@echo "5. 🔄 N8N workflows not running"
	@echo "6. 📊 Performance issues"
	@echo "7. 🧹 Clean up and reset"
	@echo "8. 🔍 Run full diagnostic"
	@echo ""
	@read -p "Choose option (1-8): " choice; \
	case $$choice in \
		1) echo ""; echo "🚫 Troubleshooting: Services won't start"; echo "========================================"; \
		   if ! docker info &> /dev/null; then echo "❌ Docker not running - Start Docker Desktop"; else echo "✅ Docker is running"; fi; \
		   echo "🔧 Try: make clean-reset && make quick-start" ;; \
		2) echo ""; echo "🌐 Troubleshooting: Can't access web interfaces"; echo "=============================================="; \
		   $(MAKE) show-urls; echo "🔧 Try: Wait 30 seconds, check firewall, or use 127.0.0.1 instead of localhost" ;; \
		3) echo ""; echo "🤖 Troubleshooting: AI models not working"; echo "========================================"; \
		   echo "🔧 Try: docker compose restart ollama-proxy webui" ;; \
		4) echo ""; echo "💾 Troubleshooting: Database connection issues"; echo "=============================================="; \
		   if docker compose ps | grep -q "n8n-db.*Up"; then echo "✅ Database running"; else echo "❌ Database not running - Try: docker compose up -d n8n-db"; fi ;; \
		5) echo ""; echo "🔄 Troubleshooting: N8N workflows not running"; echo "============================================="; \
		   echo "🔧 Check logs: make logs SERVICE=n8n" ;; \
		6) echo ""; echo "📊 Performance issues"; $(MAKE) optimize ;; \
		7) echo ""; echo "🧹 Reset options: 1=Restart 2=Clean 3=Full reset"; \
		   read -p "Choose (1-3): " reset; \
		   case $$reset in 1) $(MAKE) dev-reset ;; 2) $(MAKE) clean && $(MAKE) local-start ;; 3) echo "⚠️  Full reset will delete data!"; read -p "Type 'yes': " confirm; [ "$$confirm" = "yes" ] && $(MAKE) clean-reset ;; esac ;; \
		8) $(MAKE) health ;; \
		*) echo "Invalid option" ;; \
	esac
	@echo ""
	@echo "💡 Need more help? Run 'make logs [SERVICE=name]' or 'make health'"

dev-reset: ## Quick development reset (keeps data)
	@echo "🔄 Quick development reset..."
	@docker compose -f docker-compose.yml -f docker-compose.local.yml down
	@docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
	@echo "✅ Development environment restarted"

show-urls: ## Show all service URLs
	@echo "🌐 Service URLs:"
	@echo "   🤖 Open WebUI (AI Chat): http://localhost:8080"
	@echo "   🔄 N8N (Workflows):      http://localhost:5678"
	@echo "   🔎 Node-RED (Flows):     http://localhost:1880"
	@echo "   📷 CodeProject.AI (CV):   http://localhost:32168"
	@echo "   🐳 Portainer (Docker):   http://localhost:9000"
	@echo "   📊 Traefik Dashboard:    http://localhost:8081"
	@echo "   🌐 MCP Gateway:          http://localhost:8811"
	@echo "   🔗 Ollama Proxy:         http://localhost:8082"

show-passwords: ## Show generated passwords (requires .env file)
	@if [ -f .env ]; then \
		echo "🔐 Generated Passwords:"; \
		echo "   Admin Password: $$(grep '^PASSWORD=' .env | cut -d'=' -f2)"; \
		echo "   Database Password: $$(grep '^POSTGRES_PASSWORD=' .env | cut -d'=' -f2)"; \
	else \
		echo "❌ .env file not found. Run 'make quick-start' first."; \
	fi

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

restore-nodered: ## Restore Node-RED service data (internal use)
	@echo "🔎 Restoring Node-RED flows and settings..."
	@docker compose stop nodered 2>/dev/null || true
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_nodered_data 2>/dev/null || true && \
	if [ -f "backups/$(BACKUP)/nodered_data.tar.gz" ]; then \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/nodered_data.tar.gz" 2>/dev/null || echo "Node-RED data restore failed"; \
	elif [ -d "backups/$(BACKUP)/nodered_data" ]; then \
		docker run --rm -v $${PROJECT_NAME}_nodered_data:/data -v $$(pwd)/backups/$(BACKUP)/nodered_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "Node-RED data restore failed"; \
	fi
	@echo "✅ Node-RED restore completed. Run 'make start-service SERVICE=nodered' to start"

restore-codeprojectai: ## Restore CodeProject.AI service data (internal use)
	@echo "📷 Restoring CodeProject.AI models and config..."
	@docker compose stop codeprojectai 2>/dev/null || true
	@PROJECT_NAME=$$(basename $$(pwd)) && \
	docker volume create $${PROJECT_NAME}_codeprojectai_data 2>/dev/null || true && \
	if [ -f "backups/$(BACKUP)/codeprojectai_data.tar.gz" ]; then \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$(BACKUP):/backup alpine sh -c "cd /data && tar xzf /backup/codeprojectai_data.tar.gz" 2>/dev/null || echo "CodeProject.AI data restore failed"; \
	elif [ -d "backups/$(BACKUP)/codeprojectai_data" ]; then \
		docker run --rm -v $${PROJECT_NAME}_codeprojectai_data:/data -v $$(pwd)/backups/$(BACKUP)/codeprojectai_data:/backup alpine cp -r /backup/. /data/ 2>/dev/null || echo "CodeProject.AI data restore failed"; \
	fi
	@echo "✅ CodeProject.AI restore completed. Run 'make start-service SERVICE=codeprojectai' to start"
