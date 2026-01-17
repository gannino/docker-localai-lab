# Public Tunnel Solutions - Expose Local Services Securely

## 🎯 Overview

This guide covers open-source and free alternatives to ngrok for exposing your local AI services to the public internet securely.

---

## 🏆 Recommended Solution: Cloudflare Tunnel

### Why Cloudflare Tunnel?
- ✅ **Free forever** (no bandwidth limits)
- ✅ **No port forwarding** required
- ✅ **DDoS protection** included
- ✅ **Automatic HTTPS** with Cloudflare SSL
- ✅ **Zero-trust access** policies
- ✅ **No firewall changes** needed
- ✅ **Works behind NAT/CGNAT**
- ✅ **Enterprise-grade** reliability

### Quick Setup

#### 1. Install Cloudflared
```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Or via Docker (recommended for this project)
# Already integrated in docker-compose
```

#### 2. Authenticate
```bash
cloudflared tunnel login
```

#### 3. Create Tunnel
```bash
cloudflared tunnel create local-ai-lab
```

#### 4. Configure DNS
```bash
# Point your domain to the tunnel
cloudflared tunnel route dns local-ai-lab ai.yourdomain.com
```

#### 5. Run Tunnel
```bash
cloudflared tunnel run local-ai-lab
```

### Docker Integration

Add to `docker-compose.yml`:

```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - traefik-public
    depends_on:
      - traefik
```

### Configuration File (`config.yml`)

```yaml
tunnel: local-ai-lab
credentials-file: /root/.cloudflared/tunnel-credentials.json

ingress:
  # Open WebUI
  - hostname: webui.yourdomain.com
    service: http://traefik:80
    originRequest:
      noTLSVerify: true

  # N8N
  - hostname: n8n.yourdomain.com
    service: http://traefik:80
    originRequest:
      noTLSVerify: true

  # Portainer
  - hostname: portainer.yourdomain.com
    service: http://traefik:80
    originRequest:
      noTLSVerify: true

  # Catch-all
  - service: http_status:404
```

### Access Policies (Zero-Trust)

```yaml
# Restrict access by email domain
policies:
  - name: "Team Access"
    decision: allow
    include:
      - email_domain: yourdomain.com

  - name: "Block Everyone Else"
    decision: deny
    include:
      - everyone: true
```

---

## 🔐 Alternative 1: Tailscale Funnel

### Why Tailscale Funnel?
- ✅ **Free** (up to 100 devices)
- ✅ **Peer-to-peer VPN**
- ✅ **Easy team access**
- ✅ **No public exposure** (private network)
- ✅ **MagicDNS** for easy naming
- ✅ **ACLs** for access control

### Quick Setup

```bash
# Install Tailscale
brew install tailscale

# Start Tailscale
sudo tailscale up

# Enable Funnel (public access)
tailscale funnel 8080
```

### Docker Integration

```yaml
  tailscale:
    image: tailscale/tailscale:latest
    restart: unless-stopped
    hostname: local-ai-lab
    environment:
      - TS_AUTHKEY=${TAILSCALE_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_SERVE_CONFIG=/config/serve.json
    volumes:
      - tailscale_data:/var/lib/tailscale
      - ./tailscale-config:/config
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    networks:
      - traefik-public
```

### Serve Configuration

```json
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "webui.local-ai-lab.ts.net": {
      "Handlers": {
        "/": {
          "Proxy": "http://traefik:80"
        }
      }
    }
  }
}
```

---

## 🚀 Alternative 2: Bore (Self-Hosted)

### Why Bore?
- ✅ **Open source** (MIT license)
- ✅ **Self-hosted** option
- ✅ **Simple** and lightweight
- ✅ **TCP tunneling**
- ✅ **No dependencies**

### Quick Setup

```bash
# Install Bore
cargo install bore-cli

# Or use Docker
docker run -p 7835:7835 ekzhang/bore server

# Expose a service
bore local 8080 --to bore.pub
```

### Docker Integration

```yaml
  bore-server:
    image: ekzhang/bore:latest
    restart: unless-stopped
    command: server
    ports:
      - "7835:7835"
    networks:
      - traefik-public

  bore-client:
    image: ekzhang/bore:latest
    restart: unless-stopped
    command: local 80 --to bore-server --port 7835
    networks:
      - traefik-public
    depends_on:
      - bore-server
      - traefik
```

---

## 🌐 Alternative 3: LocalTunnel

### Why LocalTunnel?
- ✅ **No signup** required
- ✅ **Custom subdomains**
- ✅ **Simple CLI**
- ✅ **Quick temporary** tunnels

### Quick Setup

```bash
# Install LocalTunnel
npm install -g localtunnel

# Expose a service
lt --port 8080 --subdomain my-ai-lab
```

### Docker Integration

```yaml
  localtunnel:
    image: node:alpine
    restart: unless-stopped
    command: >
      sh -c "npm install -g localtunnel &&
             lt --port 80 --host http://traefik --subdomain local-ai-lab"
    networks:
      - traefik-public
    depends_on:
      - traefik
```

---

## 🔧 Alternative 4: FRP (Fast Reverse Proxy)

### Why FRP?
- ✅ **Open source**
- ✅ **Self-hosted**
- ✅ **High performance**
- ✅ **Multiple protocols** (TCP, UDP, HTTP, HTTPS)
- ✅ **Load balancing**

### Quick Setup

#### Server (VPS)
```ini
# frps.ini
[common]
bind_port = 7000
vhost_http_port = 80
vhost_https_port = 443
```

```bash
./frps -c frps.ini
```

#### Client (Local)
```ini
# frpc.ini
[common]
server_addr = your-vps-ip
server_port = 7000

[webui]
type = http
local_ip = traefik
local_port = 80
custom_domains = webui.yourdomain.com

[n8n]
type = http
local_ip = traefik
local_port = 80
custom_domains = n8n.yourdomain.com
```

```bash
./frpc -c frpc.ini
```

### Docker Integration

```yaml
  frpc:
    image: snowdreamtech/frpc:latest
    restart: unless-stopped
    volumes:
      - ./frpc.ini:/etc/frp/frpc.ini
    networks:
      - traefik-public
    depends_on:
      - traefik
```

---

## 🛡️ Alternative 5: Rathole

### Why Rathole?
- ✅ **Rust-based** (fast and secure)
- ✅ **Noise protocol** encryption
- ✅ **Low resource** usage
- ✅ **Self-hosted**

### Quick Setup

#### Server (VPS)
```toml
# server.toml
[server]
bind_addr = "0.0.0.0:2333"

[server.services.webui]
bind_addr = "0.0.0.0:8080"
```

#### Client (Local)
```toml
# client.toml
[client]
remote_addr = "your-vps-ip:2333"

[client.services.webui]
local_addr = "traefik:80"
```

### Docker Integration

```yaml
  rathole-client:
    image: rapiz1/rathole:latest
    restart: unless-stopped
    command: --client /app/client.toml
    volumes:
      - ./rathole-client.toml:/app/client.toml
    networks:
      - traefik-public
    depends_on:
      - traefik
```

---

## 📊 Comparison Matrix

| Solution | Cost | Setup | Performance | Security | Self-Hosted |
|----------|------|-------|-------------|----------|-------------|
| **Cloudflare Tunnel** | Free | Easy | Excellent | Excellent | No |
| **Tailscale Funnel** | Free* | Easy | Excellent | Excellent | No |
| **Bore** | Free | Easy | Good | Good | Yes |
| **LocalTunnel** | Free | Very Easy | Fair | Fair | No |
| **FRP** | VPS Cost | Medium | Excellent | Good | Yes |
| **Rathole** | VPS Cost | Medium | Excellent | Excellent | Yes |

*Free up to 100 devices

---

## 🎯 Recommendation by Use Case

### Personal Projects (Free)
→ **Cloudflare Tunnel** - Best overall free solution

### Team Collaboration
→ **Tailscale Funnel** - Easy team access with VPN

### Quick Testing
→ **LocalTunnel** - No setup, instant tunnels

### Self-Hosted (Privacy)
→ **Rathole** or **FRP** - Full control, requires VPS

### High Performance
→ **Cloudflare Tunnel** or **FRP** - Enterprise-grade

---

## 🚀 Implementation Plan

### Phase 1: Cloudflare Tunnel (Recommended)
```bash
# Week 1: Setup
make setup-cloudflare-tunnel

# Configure domains
make configure-tunnel-domains

# Test access
make test-tunnel
```

### Phase 2: Tailscale (Team Access)
```bash
# Week 2: Setup
make setup-tailscale

# Configure team access
make configure-tailscale-acl

# Share with team
make share-tailscale
```

### Phase 3: Self-Hosted (Optional)
```bash
# Week 3: Setup FRP/Rathole
make setup-frp-server
make setup-frp-client

# Or Rathole
make setup-rathole-server
make setup-rathole-client
```

---

## 🔒 Security Best Practices

### 1. Always Use HTTPS
- Cloudflare Tunnel: Automatic
- Others: Use Let's Encrypt with Traefik

### 2. Enable Authentication
```yaml
# Traefik BasicAuth
labels:
  - "traefik.http.middlewares.auth.basicauth.users=user:$$apr1$$..."
  - "traefik.http.routers.service.middlewares=auth"
```

### 3. IP Whitelisting
```yaml
# Traefik IP Whitelist
labels:
  - "traefik.http.middlewares.ipwhitelist.ipwhitelist.sourcerange=1.2.3.4/32"
```

### 4. Rate Limiting
```yaml
# Traefik Rate Limit
labels:
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.middlewares.ratelimit.ratelimit.burst=50"
```

### 5. Access Logs
```yaml
# Enable access logging
environment:
  - TRAEFIK_ACCESSLOG=true
  - TRAEFIK_ACCESSLOG_FILEPATH=/var/log/traefik/access.log
```

---

## 📝 Makefile Commands (Future)

```bash
# Cloudflare Tunnel
make setup-cloudflare-tunnel      # Initial setup
make start-tunnel                  # Start tunnel
make stop-tunnel                   # Stop tunnel
make tunnel-status                 # Check status

# Tailscale
make setup-tailscale              # Initial setup
make start-tailscale              # Start Tailscale
make tailscale-status             # Check status

# LocalTunnel (Quick)
make quick-tunnel PORT=8080       # Quick temporary tunnel

# FRP (Self-Hosted)
make setup-frp-server             # Setup FRP server
make setup-frp-client             # Setup FRP client
make frp-status                   # Check status
```

---

## 🆘 Troubleshooting

### Cloudflare Tunnel Not Connecting
```bash
# Check tunnel status
cloudflared tunnel info local-ai-lab

# Check logs
docker logs cloudflared

# Recreate tunnel
cloudflared tunnel delete local-ai-lab
cloudflared tunnel create local-ai-lab
```

### Tailscale Connection Issues
```bash
# Check status
tailscale status

# Restart
sudo tailscale down
sudo tailscale up

# Check logs
docker logs tailscale
```

### Port Already in Use
```bash
# Find process using port
lsof -i :7835

# Kill process
kill -9 <PID>
```

---

## 📚 Additional Resources

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Tailscale Docs](https://tailscale.com/kb/)
- [Bore GitHub](https://github.com/ekzhang/bore)
- [FRP GitHub](https://github.com/fatedier/frp)
- [Rathole GitHub](https://github.com/rapiz1/rathole)

---

**Last Updated**: 2024
**Recommended**: Cloudflare Tunnel for production, LocalTunnel for quick testing
**Next Steps**: Implement Cloudflare Tunnel in Phase 1
