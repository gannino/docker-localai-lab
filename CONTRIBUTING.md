# 👨‍💻 Developer Setup Guide

This guide is for developers who want to contribute to the Docker AI Lab project.

## 🛠️ Development Environment Setup

### Prerequisites
- Docker Desktop
- Python 3.8+ (for pre-commit hooks)
- Git

### Initial Setup

1. **Clone and setup the repository:**
   ```bash
   git clone <repo-url>
   cd local-ai-lab
   ```

2. **Install development tools:**
   ```bash
   # Install pre-commit
   pip install pre-commit

   # Install pre-commit hooks
   make pre-commit-install
   ```

3. **Install optional linting tools:**
   ```bash
   # macOS
   brew install shellcheck yamllint

   # Ubuntu/Debian
   sudo apt-get install shellcheck yamllint
   ```

## 🧪 Testing Framework

### **Embedded Test Suite in Makefile**
- **Docker availability tests**: Checks Docker and Docker Compose
- **Configuration validation**: Tests YAML syntax and Makefile
- **Service startup tests**: Validates service deployment (optional)
- **Accessibility tests**: Checks if services respond on expected ports
- **Documentation tests**: Ensures required docs exist
- **Color-coded output**: Clear pass/fail indicators

### **Running Tests**

```bash
# Run full test suite
make test

# Test service startup and accessibility
make test-services

# Test configuration files only
make test-config

# Run linting checks
make lint

# Run pre-commit hooks
make pre-commit-run
```

### Test Categories

1. **Configuration Tests**: Validate YAML and Makefile syntax
2. **Docker Tests**: Check Docker availability and network setup
3. **Service Tests**: Test service startup and accessibility
4. **Documentation Tests**: Verify required documentation exists

## 🔍 Pre-commit Hooks

Pre-commit hooks run automatically before each commit to ensure code quality:

- **Trailing whitespace removal**
- **End-of-file fixing**
- **YAML validation**
- **Shell script linting**
- **Docker Compose validation**
- **Makefile syntax checking**

### Manual Hook Execution
```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run shellcheck --all-files
```

## 📁 Project Structure for Developers

```
local-ai-lab/
├── .github/workflows/          # CI/CD pipelines
├── .pre-commit-config.yaml     # Pre-commit configuration
├── test.sh                     # Test framework
├── docker-compose.yml          # Main service definitions
├── docker-compose.local.yml    # Local development overrides
├── Makefile                    # All commands and automation
├── legacy/                     # Deprecated scripts (reference only)
└── docs/                       # Documentation files
```

## 🔄 Development Workflow

### Making Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**

3. **Test your changes:**
   ```bash
   make test
   make lint
   ```

4. **Commit (pre-commit hooks run automatically):**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

5. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Testing Changes

```bash
# Test configuration changes
make test-config

# Test service changes
make clean-reset
make quick-start
make test

# Test documentation changes
make test-quick
```

## 🚀 CI/CD Pipeline

The project uses GitHub Actions for continuous integration:

### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main`

### Pipeline Steps
1. **Code Quality**: Pre-commit hooks, linting
2. **Testing**: Configuration validation, service tests
3. **Security**: Vulnerability scanning with Trivy

### Local CI Simulation
```bash
# Run the same checks as CI
make pre-commit-run
make test
make test-config
```

## 📝 Code Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e`
- Use shellcheck-compliant syntax
- Add comments for complex logic

### YAML Files
- Use 2-space indentation
- Validate with yamllint
- Follow Docker Compose best practices

### Makefile
- Use `.PHONY` for non-file targets
- Add help text: `target: ## Description`
- Use `@` prefix for clean output
- Handle errors gracefully

### Documentation
- Use clear, beginner-friendly language
- Include code examples
- Add visual diagrams where helpful
- Keep README.md updated

## 🐛 Debugging

### Common Issues

**Pre-commit hooks failing:**
```bash
# Skip hooks temporarily (not recommended)
git commit --no-verify

# Fix issues and retry
make lint
git add .
git commit
```

**Tests failing:**
```bash
# Check Docker status
docker info

# View detailed test output
./test.sh

# Check specific service logs
make logs SERVICE=webui
```

**Service startup issues:**
```bash
# Clean restart
make clean-reset
make quick-start

# Check service health
make health
```

## 🔧 Advanced Development

### Adding New Services

1. **Update docker-compose.yml**
2. **Add local development overrides**
3. **Update Makefile commands**
4. **Add tests for the new service**
5. **Update documentation**

### Modifying Tests

Edit `test.sh` to add new test functions:

```bash
test_new_feature() {
    echo "🧪 Testing new feature..."

    if your_test_command; then
        test_result 0 "New feature works"
    else
        test_result 1 "New feature failed"
    fi
}
```

### Adding Pre-commit Hooks

Edit `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: your-custom-hook
      name: Your Custom Check
      entry: your-command
      language: system
```

## 📊 Performance Considerations

- **Test execution time**: Keep tests under 5 minutes
- **Resource usage**: Monitor Docker resource consumption
- **Startup time**: Optimize service dependencies
- **Documentation**: Keep guides concise but complete

---

## 🤝 Contributing Guidelines

1. **Follow the testing framework**
2. **Run pre-commit hooks**
3. **Update documentation**
4. **Test on clean environment**
5. **Write clear commit messages**

**Happy coding! 🚀**
