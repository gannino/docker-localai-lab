# Service Management Targets

start: check-env validate setup-rosetta ## Start all services (production)
	@echo "🚀 Starting all services..."
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
	docker network create traefik-public 2>/dev/null || true && \
	docker compose up -d

stop: ## Stop all services
	@echo "🛑 Stopping all services..."
	@docker compose down

restart: check-env stop start ## Restart all services

start-service: check-env ## Start specific service (use: make start-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make start-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
	docker network create traefik-public 2>/dev/null || true && \
	docker compose up -d $(SERVICE)

stop-service: ## Stop specific service (use: make stop-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make stop-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@docker compose stop $(SERVICE)

restart-service: check-env ## Restart specific service (use: make restart-service SERVICE=webui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: Please specify service. Usage: make restart-service SERVICE=webui"; \
		echo "Available services: traefik, portainer, n8n-db, n8n, mcp-gateway, ollama-proxy, echo, webui"; \
		exit 1; \
	fi
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
	docker network create traefik-public 2>/dev/null || true && \
	docker compose stop $(SERVICE) && \
	docker compose up -d $(SERVICE)

status: check-env ## Show service status and URLs
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

update: check-env ## Update all images and restart services
	@echo "🔄 Updating all images..."
	@source .env && \
	export DOMAIN=$$SUBDOMAIN.$$DOMAIN_NAME && \
	export HURRICANE_TOKENS=$$DOMAIN:$$HURRICANE_TOKENS_PASSWORD && \
	docker compose pull && \
	echo "🔄 Restarting services with new images..." && \
	docker compose up -d && \
	echo "✅ Update complete - services restarted with latest images"

dev-reset: ## Quick development reset (keeps data)
	@echo "🔄 Quick development reset..."
	@docker compose -f docker-compose.yml -f docker-compose.local.yml down
	@docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
	@echo "✅ Development environment restarted"

# Convenience aliases
up: start ## Alias for start
down: stop ## Alias for stop
ps: status ## Alias for status
local: local-start ## Alias for local-start

debug: ## Start services in debug mode with verbose logging
	@echo "🔍 Starting services in debug mode..."
	@DEBUG=1 LOG_LEVEL=debug docker compose -f docker-compose.yml -f docker-compose.local.yml up
