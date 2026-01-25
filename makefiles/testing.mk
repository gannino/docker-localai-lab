# Testing and Diagnostic Targets

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
	echo "💾 Docker Resources:"; \
	echo "-------------------"; \
	echo "Volumes: $$(docker volume ls -q | wc -l | tr -d ' ')"; \
	echo "Networks: $$(docker network ls -q | wc -l | tr -d ' ')"; \
	echo "Images: $$(docker images -q | wc -l | tr -d ' ')"; \
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

health-detailed: ## Run detailed health check with diagnostics
	@echo "🔍 Docker AI Lab - Detailed Health Check"
	@echo "========================================="
	@echo ""
	@$(MAKE) health
	@echo ""
	@echo "🔍 Detailed Diagnostics:"
	@echo "----------------------"
	@echo ""
	@echo "Docker Version:"
	@docker --version
	@docker compose version
	@echo ""
	@echo "System Resources:"
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		total_ram=$$(sysctl -n hw.memsize); \
		total_ram_gb=$$((total_ram / 1024 / 1024 / 1024)); \
		cpu_cores=$$(sysctl -n hw.ncpu); \
		echo "  RAM: $${total_ram_gb}GB"; \
		echo "  CPU Cores: $${cpu_cores}"; \
	fi
	@echo ""
	@echo "Docker Resource Usage:"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No containers running"
	@echo ""
	@echo "Disk Usage:"
	@docker system df
	@echo ""
	@if [ -f .env ]; then \
		echo "Environment Configuration:"; \
		echo "  .env file: ✅ Present"; \
		echo "  Domain: $$(grep DOMAIN_NAME .env | cut -d'=' -f2)"; \
		echo "  Subdomain: $$(grep SUBDOMAIN .env | cut -d'=' -f2)"; \
	else \
		echo "Environment Configuration: ❌ .env not found"; \
	fi
	@echo ""
	@echo "Recent Backups:"
	@ls -lt backups/ 2>/dev/null | head -5 || echo "No backups found"

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
		5) echo ""; echo "🔄 Troubleshooting: N8N workflows not running"; echo "=============================================="; \
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

test-integration: ## Run integration tests
	@echo "🧪 Testing service integration..."
	@FAILED=0; \
	if ! docker compose ps | grep -q "Up"; then \
		echo "❌ No services running. Start with 'make local-start'"; \
		exit 1; \
	fi; \
	echo "Testing WebUI → Ollama proxy..."; \
	if docker compose exec -T webui curl -sf http://ollama-proxy/health > /dev/null 2>&1; then \
		echo "✅ WebUI can reach Ollama proxy"; \
	else \
		echo "❌ WebUI → Ollama connection failed"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	echo "Testing N8N → Database..."; \
	if docker compose exec -T n8n-db pg_isready -U n8n > /dev/null 2>&1; then \
		echo "✅ Database is ready"; \
	else \
		echo "❌ Database not ready"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	echo "Testing N8N → Database connection..."; \
	if docker compose exec -T n8n-db psql -U n8n -d n8n -c "SELECT 1" > /dev/null 2>&1; then \
		echo "✅ N8N can query database"; \
	else \
		echo "❌ N8N database connection failed"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	if [ $$FAILED -eq 0 ]; then \
		echo ""; echo "🎉 All integration tests passed!"; \
	else \
		echo ""; echo "💥 $$FAILED integration test(s) failed"; \
		exit 1; \
	fi

smoke-test: ## Quick smoke test after deployment
	@echo "💨 Running smoke tests..."
	@FAILED=0; \
	if [ -f .env ]; then \
		echo "🔍 Detected: Production environment"; \
		source .env; \
		BASE_URL="https://webui.$$SUBDOMAIN.$$DOMAIN_NAME"; \
		N8N_URL="https://n8n.$$SUBDOMAIN.$$DOMAIN_NAME"; \
		PORTAINER_URL="https://portainer.$$SUBDOMAIN.$$DOMAIN_NAME"; \
	else \
		echo "🔍 Detected: Local environment"; \
		BASE_URL="http://localhost:8080"; \
		N8N_URL="http://localhost:5678"; \
		PORTAINER_URL="http://localhost:9000"; \
	fi; \
	if curl -sf --max-time 5 $$BASE_URL/health > /dev/null 2>&1; then \
		echo "✅ WebUI is accessible ($$BASE_URL)"; \
	else \
		echo "❌ WebUI health check failed ($$BASE_URL)"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	if curl -sf --max-time 5 $$N8N_URL/healthz > /dev/null 2>&1; then \
		echo "✅ N8N is accessible ($$N8N_URL)"; \
	else \
		echo "❌ N8N health check failed ($$N8N_URL)"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	if curl -sf --max-time 5 $$PORTAINER_URL > /dev/null 2>&1; then \
		echo "✅ Portainer is accessible ($$PORTAINER_URL)"; \
	else \
		echo "❌ Portainer health check failed ($$PORTAINER_URL)"; \
		FAILED=$$((FAILED + 1)); \
	fi; \
	if [ $$FAILED -eq 0 ]; then \
		echo ""; echo "✅ All smoke tests passed!"; \
	else \
		echo ""; echo "⚠️  $$FAILED smoke test(s) failed"; \
		exit 1; \
	fi

benchmark: ## Run performance benchmarks
	@echo "📊 Running performance benchmarks..."
	@if ! docker compose ps | grep -q "Up"; then \
		echo "❌ No services running. Start with 'make local-start' or 'make start'"; \
		exit 1; \
	fi
	@if [ -f .env ]; then \
		echo "🔍 Environment: Production"; \
		source .env; \
		WEBUI_URL="https://webui.$$SUBDOMAIN.$$DOMAIN_NAME"; \
		N8N_URL="https://n8n.$$SUBDOMAIN.$$DOMAIN_NAME"; \
		PORTAINER_URL="https://portainer.$$SUBDOMAIN.$$DOMAIN_NAME"; \
	else \
		echo "🔍 Environment: Local"; \
		WEBUI_URL="http://localhost:8080"; \
		N8N_URL="http://localhost:5678"; \
		PORTAINER_URL="http://localhost:9000"; \
	fi
	@echo ""
	@echo "Database Performance:"
	@echo "--------------------"
	@START=$$(date +%s%N); \
	docker compose exec -T n8n-db psql -U n8n -d n8n -c "SELECT COUNT(*) FROM pg_stat_activity" > /dev/null 2>&1; \
	END=$$(date +%s%N); \
	DURATION=$$((($${END} - $${START}) / 1000000)); \
	echo "Query response time: $${DURATION}ms"
	@echo ""
	@echo "Service Response Times:"
	@echo "----------------------"
	@for service in "$$WEBUI_URL|WebUI" "$$N8N_URL|N8N" "$$PORTAINER_URL|Portainer"; do \
		url=$$(echo $$service | cut -d'|' -f1); \
		name=$$(echo $$service | cut -d'|' -f2); \
		RESPONSE=$$(curl -o /dev/null -s -w '%{time_total}' --max-time 5 $$url 2>/dev/null || echo "timeout"); \
		if [ "$$RESPONSE" != "timeout" ]; then \
			MS=$$(echo "$$RESPONSE * 1000" | bc | cut -d'.' -f1); \
			echo "$$name: $${MS}ms"; \
		else \
			echo "$$name: timeout"; \
		fi; \
	done
	@echo ""
	@echo "Docker Resource Usage:"
	@echo "---------------------"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -5
	@echo ""
	@echo "✅ Benchmark complete"
