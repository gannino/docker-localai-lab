# Backup and Restore Targets

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

verify-backup: ## Verify backup integrity (use: make verify-backup BACKUP=20240101_120000)
	@if [ -z "$(BACKUP)" ]; then \
		echo "Error: Please specify backup folder. Usage: make verify-backup BACKUP=20240101_120000"; \
		echo "Available backups:"; \
		ls -1 backups/ 2>/dev/null || echo "No backups found"; \
		exit 1; \
	fi
	@if [ ! -d "backups/$(BACKUP)" ]; then \
		echo "Error: Backup folder backups/$(BACKUP) not found"; \
		exit 1; \
	fi
	@echo "🔍 Verifying backup: $(BACKUP)"
	@echo ""
	@ERRORS=0; \
	echo "Checking backup files..."; \
	if [ -f "backups/$(BACKUP)/n8n_database.sql" ]; then \
		if head -1 backups/$(BACKUP)/n8n_database.sql | grep -q "PostgreSQL\|--"; then \
			echo "✅ N8N database backup valid"; \
		else \
			echo "❌ N8N database backup corrupted"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	else \
		echo "⚠️  N8N database backup not found"; \
	fi; \
	if [ -f "backups/$(BACKUP)/webui.db" ]; then \
		if file backups/$(BACKUP)/webui.db | grep -q "SQLite"; then \
			echo "✅ WebUI database backup valid"; \
		else \
			echo "❌ WebUI database backup corrupted"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	else \
		echo "⚠️  WebUI database backup not found"; \
	fi; \
	if [ -f "backups/$(BACKUP)/.env" ]; then \
		if grep -q "DOMAIN_NAME" backups/$(BACKUP)/.env; then \
			echo "✅ Configuration backup valid"; \
		else \
			echo "❌ Configuration backup corrupted"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	else \
		echo "⚠️  Configuration backup not found"; \
	fi; \
	if [ -f "backups/$(BACKUP)/n8n_data.tar.gz" ] || [ -d "backups/$(BACKUP)/n8n_data" ]; then \
		echo "✅ N8N volume data present"; \
	else \
		echo "⚠️  N8N volume data not found"; \
	fi; \
	if [ -f "backups/$(BACKUP)/webui_data.tar.gz" ] || [ -d "backups/$(BACKUP)/webui_data" ]; then \
		echo "✅ WebUI volume data present"; \
	else \
		echo "⚠️  WebUI volume data not found"; \
	fi; \
	if [ -f "backups/$(BACKUP)/traefik_ssl.tar.gz" ] || [ -d "backups/$(BACKUP)/traefik_ssl" ]; then \
		echo "✅ SSL certificates present"; \
	else \
		echo "⚠️  SSL certificates not found"; \
	fi; \
	echo ""; \
	if [ $$ERRORS -eq 0 ]; then \
		echo "🎉 Backup verification passed!"; \
		echo "✅ Backup $(BACKUP) is valid and can be restored"; \
	else \
		echo "⚠️  Backup verification found $$ERRORS error(s)"; \
		echo "❌ Backup $(BACKUP) may be corrupted or incomplete"; \
		exit 1; \
	fi

setup-auto-backup: ## Setup automatic daily backups at 2 AM
	@echo "⏰ Setting up automatic daily backups..."
	@echo ""
	@echo "This will create a cron job to run backups daily at 2 AM"
	@echo "Backup location: $(PWD)/backups/"
	@echo "Backup command: make backup COMPRESS=true"
	@echo ""
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@CRON_CMD="0 2 * * * cd $(PWD) && make backup COMPRESS=true >> $(PWD)/backups/auto-backup.log 2>&1"; \
	(crontab -l 2>/dev/null | grep -v "make backup" ; echo "$$CRON_CMD") | crontab - && \
	echo "✅ Automatic backup scheduled for 2 AM daily" && \
	echo "📋 Logs will be saved to: backups/auto-backup.log" && \
	echo "" && \
	echo "To view scheduled backups: crontab -l" && \
	echo "To remove auto-backup: make remove-auto-backup"

remove-auto-backup: ## Remove automatic backup schedule
	@echo "🗑️  Removing automatic backup schedule..."
	@crontab -l 2>/dev/null | grep -v "make backup" | crontab - && \
	echo "✅ Automatic backup removed" || \
	echo "ℹ️  No automatic backup was configured"

show-auto-backup: ## Show current automatic backup schedule
	@echo "📅 Current automatic backup schedule:"
	@if crontab -l 2>/dev/null | grep -q "make backup"; then \
		crontab -l | grep "make backup"; \
	else \
		echo "ℹ️  No automatic backup configured"; \
		echo "Run 'make setup-auto-backup' to enable automatic backups"; \
	fi
