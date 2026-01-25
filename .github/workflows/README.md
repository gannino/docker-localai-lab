# CI/CD Workflows

This directory contains GitHub Actions workflows for automated testing and security scanning.

## Workflows

### 🧪 CI Pipeline (`ci.yml`)
**Triggers**: Push to `main`/`develop`, Pull requests to `main`

**Steps**:
1. **Setup** - Checkout code, setup Docker, install pre-commit
2. **Ollama Setup** - Run standalone Ollama container with tinyllama model
3. **Configuration** - Use CI-specific nginx config (nginx-ollama-ci.conf)
4. **Service Testing** - Start and verify ollama-proxy health
5. **Full Stack** - Start all services with `make quick-start`
6. **Smoke Tests** - Test N8N, Portainer, WebUI endpoints
7. **AI Inference** - End-to-end test via ollama-proxy
8. **Integration Tests** - Database connectivity, benchmarks
9. **Health Check** - Container stats and status

**Key Features**:
- Uses `nginx-ollama-ci.conf` for CI-specific Ollama routing
- Tests AI inference with tinyllama model
- Validates all service endpoints
- Runs pre-commit hooks

### 🔒 Security Scan (`ci.yml` - security job)
**Triggers**: Same as CI pipeline

**Steps**:
1. **Trivy Scan** - Filesystem vulnerability scanning
2. **SARIF Upload** - Results uploaded to GitHub Security tab

## CI-Specific Configuration

### nginx-ollama-ci.conf
Simplified nginx config for CI that only uses `ollama:11434` upstream (no model-runner.docker.internal).

### Port Mappings (Local Development)
- Traefik: 8081
- Portainer: 9000
- N8N: 5678
- Node-RED: 1880
- WebUI: 8080
- Ollama Proxy: 8082
- CodeProject.AI: 32168

## Running Locally

```bash
# Run all tests
make test

# Run smoke tests
make smoke-test

# Run integration tests
make test-integration

# Run benchmarks
make benchmark
```

## Troubleshooting

**Ollama-proxy fails to start**:
- Ensure Ollama container is running and accessible
- Check nginx config is copied: `cp nginx-ollama-ci.conf nginx-ollama.conf`
- Verify network: `docker network inspect traefik-public`

**Service health checks fail**:
- Increase wait times in workflow
- Check service logs: `docker compose logs <service>`
- Verify port mappings in docker-compose.local.yml

**AI inference test fails**:
- Ensure tinyllama model is pulled: `docker exec ollama ollama list`
- Test Ollama directly: `curl http://localhost:11434/api/tags`
- Check ollama-proxy logs: `docker compose logs ollama-proxy`
