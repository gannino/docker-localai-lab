# 🏗️ System Architecture - Visual Guide

This document explains how all the pieces work together in simple terms.

## 🎯 The Big Picture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Your Mac Computer                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Web Browser (Safari, Chrome, etc.)                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │ AI Chat     │ │ Workflows   │ │ Management  │ │ Dashboard   │          │
│  │ :8080       │ │ :5678       │ │ :9000       │ │ :8081       │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
│         │               │               │               │                  │
│         └───────────────┼───────────────┼───────────────┘                  │
│                         │               │                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Docker Desktop                                  │   │
│  │                                                                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │   WebUI     │ │     N8N     │ │ Portainer   │ │   Traefik   │   │   │
│  │  │ (AI Chat)   │ │(Workflows)  │ │(Management) │ │ (Proxy)     │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                   │   │
│  │  │ PostgreSQL  │ │ Ollama      │ │ MCP Gateway │                   │   │
│  │  │ (Database)  │ │ (AI Models) │ │ (Protocols) │                   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Your data is stored in Docker volumes (safe and persistent)               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🧩 What Each Component Does

### 🤖 WebUI (AI Chat Interface)
- **What it is**: Your personal ChatGPT-like interface
- **What it does**:
  - Chat with AI models via Docker Model Runner
  - Upload and analyze documents
  - Generate content and images
- **Where to access**: http://localhost:8080
- **Think of it as**: Your AI assistant's front desk

### 🔄 N8N (Workflow Automation)
- **What it is**: Visual automation builder
- **What it does**:
  - Create automated workflows
  - Connect different services
  - Process data automatically
- **Where to access**: http://localhost:5678
- **Think of it as**: Your personal robot that follows instructions

### 🔍 Node-RED (Visual Programming)
- **What it is**: Flow-based programming platform
- **What it does**:
  - Visual programming with drag-and-drop
  - IoT device integration
  - Simple automation flows
- **Where to access**: http://localhost:1880
- **Think of it as**: Visual coding for non-programmers

### 🐳 Portainer (Container Management)
- **What it is**: Control panel for all services
- **What it does**:
  - Show what's running
  - Start/stop services
  - Monitor resource usage
- **Where to access**: http://localhost:9000
- **Think of it as**: The control room for everything

### 📊 Traefik (Traffic Director)
- **What it is**: Smart router for web traffic
- **What it does**:
  - Routes requests to the right service
  - Handles SSL certificates
  - Provides monitoring dashboard
- **Where to access**: http://localhost:8081
- **Think of it as**: The traffic cop directing requests

### 🗄️ PostgreSQL (Database)
- **What it is**: Data storage system
- **What it does**:
  - Stores your workflows
  - Keeps user settings
  - Maintains system data
- **Where to access**: Not directly (runs in background)
- **Think of it as**: The filing cabinet for all your data

### 🧠 Ollama Proxy (AI Model Bridge)
- **What it is**: Connection between chat interface and AI models via Docker Model Runner
- **What it does**:
  - Manages AI model communication
  - Handles model loading/unloading
  - Provides API compatibility
  - Bridges Docker Model Runner to WebUI
- **Where to access**: Not directly (runs in background)
- **Think of it as**: The translator between your chat and the AI brain

### 📷 CodeProject.AI (Computer Vision)
- **What it is**: AI-powered image and video analysis
- **What it does**:
  - Object detection and recognition
  - Face detection and analysis
  - License plate recognition
  - Scene analysis
- **Where to access**: http://localhost:32168
- **Think of it as**: Your AI vision assistant

## 🔄 How Data Flows

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Data Flow Example                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. You type a message in your browser                                     │
│     ↓                                                                       │
│  2. Browser sends request to WebUI (port 8080)                            │
│     ↓                                                                       │
│  3. WebUI processes your message                                           │
│     ↓                                                                       │
│  4. WebUI sends to Ollama Proxy for AI processing                         │
│     ↓                                                                       │
│  5. Ollama Proxy loads appropriate AI model                               │
│     ↓                                                                       │
│  6. AI model generates response                                            │
│     ↓                                                                       │
│  7. Response travels back: Model → Proxy → WebUI → Browser                │
│     ↓                                                                       │
│  8. You see the AI's response in your chat                                │
│                                                                             │
│  Meanwhile: PostgreSQL saves the conversation for later                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔒 Security & Privacy Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Privacy Boundaries                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Your Mac                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                   Docker Network                            │   │   │
│  │  │                                                             │   │   │
│  │  │  All services communicate securely within this boundary    │   │   │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │   │
│  │  │  │ Service │ │ Service │ │ Service │ │ Service │          │   │   │
│  │  │  │    A    │ │    B    │ │    C    │ │    D    │          │   │   │
│  │  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │   │
│  │  │                                                             │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Your data never leaves this boundary                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ❌ No data sent to external servers                                       │
│  ❌ No tracking or analytics                                               │
│  ❌ No cloud dependencies                                                  │
│  ✅ Everything runs locally                                                │
│  ✅ You control all data                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 File System Layout

```
local-ai-lab/
├── 📄 README.md                    # Main documentation
├── 📄 GETTING_STARTED.md           # Beginner's guide
├── 📄 FAQ.md                       # Common questions
├── 📄 ARCHITECTURE.md              # This file
├── 🐳 docker-compose.yml           # Service definitions
├── 🐳 docker-compose.local.yml     # Local development settings
├── ⚙️ Makefile                     # All commands
├── 🌐 nginx-ollama.conf            # AI model proxy config
├── 📁 data/                        # Persistent data storage
│   ├── 📁 n8n-workflows/           # Your automation workflows
│   ├── 📁 webui-config/            # AI chat settings
│   └── 📁 postgres-backups/        # Database backups
├── 📁 backups/                     # System backups
├── 📁 local-files/                 # Shared file storage
└── 📁 legacy/                      # Old scripts (for reference)
```

## 🔧 Resource Usage

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          System Resources                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Memory (RAM) Usage:                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ WebUI (AI Chat):      ~1-2 GB                                      │   │
│  │ N8N (Workflows):      ~200-500 MB                                  │   │
│  │ PostgreSQL:           ~100-200 MB                                  │   │
│  │ Traefik:              ~50-100 MB                                   │   │
│  │ Other services:       ~200-300 MB                                  │   │
│  │ ─────────────────────────────────────────────────────────────────   │   │
│  │ Total:                ~2-4 GB                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Disk Space:                                                               │
│  • Docker images: ~3-5 GB                                                 │
│  • AI models: ~2-10 GB (downloaded as needed)                             │
│  • Your data: Grows with usage                                            │
│                                                                             │
│  CPU Usage:                                                                │
│  • Idle: Very low                                                         │
│  • AI processing: High (temporary)                                        │
│  • Background: Low to moderate                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Startup Sequence

When you run `make local-start`, here's what happens:

```
1. 🔍 Check Docker is running
   ↓
2. 🌐 Create network for services to communicate
   ↓
3. 🗄️ Start PostgreSQL database
   ↓
4. ⏳ Wait for database to be ready
   ↓
5. 🔄 Start N8N (connects to database)
   ↓
6. 🤖 Start WebUI (AI chat interface)
   ↓
7. 🌉 Start Ollama Proxy (AI model bridge)
   ↓
8. 📊 Start Traefik (traffic router)
   ↓
9. 🐳 Start Portainer (management interface)
   ↓
10. 🌐 Start MCP Gateway (protocol support)
    ↓
11. ✅ All services running and healthy
    ↓
12. 🎉 Ready to use!
```

## 🔄 Service Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Service Dependencies                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                    ┌─────────────┐                                         │
│                    │ PostgreSQL  │                                         │
│                    │ (Database)  │                                         │
│                    └─────────────┘                                         │
│                           │                                                 │
│                           ▼                                                 │
│                    ┌─────────────┐                                         │
│                    │     N8N     │                                         │
│                    │ (Workflows) │                                         │
│                    └─────────────┘                                         │
│                                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                      │
│  │   WebUI     │   │ Ollama      │   │ MCP Gateway │                      │
│  │ (AI Chat)   │   │ (AI Proxy)  │   │ (Protocols) │                      │
│  └─────────────┘   └─────────────┘   └─────────────┘                      │
│         │                  │                  │                            │
│         └──────────────────┼──────────────────┘                            │
│                            ▼                                               │
│                    ┌─────────────┐                                         │
│                    │   Traefik   │                                         │
│                    │ (Router)    │                                         │
│                    └─────────────┘                                         │
│                                                                             │
│  Legend:                                                                   │
│  • PostgreSQL must start first                                            │
│  • N8N waits for PostgreSQL                                               │
│  • Other services can start independently                                 │
│  • Traefik routes traffic to all services                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 💡 Understanding This Helps You:

- **Troubleshoot issues** - Know which service might be causing problems
- **Optimize performance** - Understand resource usage
- **Customize setup** - Modify components you understand
- **Feel confident** - Know what's running on your system

**Remember**: You don't need to understand everything to use the system, but this knowledge helps when things go wrong or when you want to customize your setup!
