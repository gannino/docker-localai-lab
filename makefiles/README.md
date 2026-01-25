# Makefiles Directory

This directory contains modular Makefile components for the Docker AI Lab project.

## Structure

```
makefiles/
├── setup.mk      - Setup and configuration targets
├── services.mk   - Service management targets
├── backup.mk     - Backup and restore targets
└── testing.mk    - Testing and diagnostic targets
```

## Module Descriptions

### setup.mk (Setup & Configuration)
Handles initial setup, environment configuration, and first-time user experience.

**Key targets:**
- `beginner-setup` - Complete beginner setup
- `quick-start` - One-command setup and start
- `first-time` - Guided first-time setup
- `setup`, `setup-data`, `setup-nginx`, `setup-rosetta`
- `validate`, `check-env`

### services.mk (Service Management)
Manages Docker services lifecycle and operations.

**Key targets:**
- `start`, `stop`, `restart` - Service control
- `local-start`, `local-stop` - Local development mode
- `status`, `logs` - Service monitoring
- `start-service`, `stop-service`, `restart-service` - Individual service control
- `clean`, `clean-reset`, `update` - Maintenance
- Aliases: `up`, `down`, `ps`, `local`

### backup.mk (Backup & Restore)
Handles data backup and restoration operations.

**Key targets:**
- `backup` - Create backup (with optional compression)
- `restore` - Restore from backup
- `restore-service` - Restore specific service
- `restore-n8n`, `restore-webui`, `restore-traefik` - Service-specific restore
- `restore-nodered`, `restore-codeprojectai` - Additional services
- `list-backups` - Show available backups

### testing.mk (Testing & Diagnostics)
Provides testing, health checks, and troubleshooting tools.

**Key targets:**
- `test`, `test-services`, `test-quick`, `test-config` - Testing
- `health` - Comprehensive health check
- `optimize` - Resource optimization
- `troubleshoot` - Interactive troubleshooting
- `show-urls`, `show-passwords` - Information display
- `lint`, `pre-commit-install`, `pre-commit-run` - Code quality

## Usage

All targets are accessible from the main Makefile:

```bash
# From project root
make help              # Show all available commands
make quick-start       # Setup and start
make local-start       # Start in local mode
make backup            # Create backup
make health            # Run health check
```

## Adding New Targets

1. Choose the appropriate module file
2. Add your target with `##` comment for help text:
   ```makefile
   my-target: ## Description of what this does
       @echo "Doing something..."
   ```
3. Test with `make -n my-target`
4. Run regression tests: `./test_makefile_regression.sh`

## Benefits of Modular Structure

1. **Maintainability** - Edit only relevant files
2. **Organization** - Logical grouping by functionality
3. **Readability** - Smaller, focused files
4. **Collaboration** - Easier to work on different features
5. **Testing** - Module-specific testing possible

## Migration Notes

- Original 902-line Makefile split into 4 modules
- Main Makefile reduced to 16 lines (98% reduction)
- All functionality preserved
- Backward compatible - all commands work the same
- Backup available: `Makefile.backup`

## Troubleshooting

If you encounter issues:

1. Check syntax: `make -n help`
2. Verify includes: `ls -la makefiles/`
3. Run tests: `./test_makefile_regression.sh`
4. Rollback: `cp Makefile.backup Makefile`

## Documentation

- Main README: `../README.md`
- Migration guide: `../docs/MAKEFILE_MODULARIZATION.md`
- Architecture: `../docs/ARCHITECTURE.md`
