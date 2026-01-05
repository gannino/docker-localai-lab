# 🚀 Getting Started - Complete Beginner's Guide

## ⚠️ **Important Disclaimer**

**This software is provided "AS IS" without warranty of any kind. We are not responsible for any issues, damages, or problems that may arise from using this project. Use at your own risk.**

Welcome! This guide will help you set up your own AI-powered workspace on your Mac, even if you've never used Docker or command-line tools before.

## 🎯 What You'll Get

After following this guide, you'll have:

```
┌─────────────────────────────────────────────────────────────┐
│                    Your AI Workspace                        │
├─────────────────────────────────────────────────────────────┤
│  🤖 AI Chat Interface    │  🔄 Workflow Automation         │
│  (Like ChatGPT)          │  (Automate tasks)               │
│  http://localhost:8080   │  http://localhost:5678          │
├─────────────────────────────────────────────────────────────┤
│  🔍 Node-RED Flows       │  📷 Computer Vision             │
│  (Visual Programming)    │  (Image Analysis)               │
│  http://localhost:1880   │  http://localhost:32168         │
├─────────────────────────────────────────────────────────────┤
│  🐳 Container Manager    │  📊 System Dashboard            │
│  (Manage services)       │  (Monitor everything)           │
│  http://localhost:9000   │  http://localhost:8081          │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Before We Start

### What You Need:
- ✅ A Mac computer (any recent version)
- ✅ Internet connection
- ✅ About 30 minutes of time
- ✅ Admin password for your Mac
- ✅ **Docker Model Runner** (included - no separate Ollama installation needed)

### What You DON'T Need:
- ❌ Programming knowledge
- ❌ Docker experience
- ❌ Command-line expertise
- ❌ Any paid subscriptions
- ❌ Separate Ollama installation

## 🛠️ Step 1: Install Docker Desktop

Docker is like a virtual container system that keeps all our AI tools organized and isolated.

### Download and Install:

1. **Go to Docker's website**: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

2. **Click "Download for Mac"**
   - Choose "Apple Chip" if you have a newer Mac (M1, M2, M3)
   - Choose "Intel Chip" if you have an older Mac

3. **Install Docker Desktop**:
   ```
   📁 Downloads folder → Docker.dmg → Drag Docker to Applications
   ```

4. **Start Docker Desktop**:
   - Open Applications folder
   - Double-click Docker
   - Wait for it to start (you'll see a whale icon in your menu bar)

### Verify Installation:
1. Press `Cmd + Space` to open Spotlight
2. Type "Terminal" and press Enter
3. In the black window that opens, type: `docker --version`
4. You should see something like "Docker version 24.x.x"

## 📥 Step 2: Download This Project

1. **Download the project**:
   - Click the green "Code" button on this page
   - Select "Download ZIP"
   - The file will download to your Downloads folder

2. **Extract and move**:
   ```
   📁 Downloads → local-ai-lab-main.zip → Double-click to extract
   📁 Move the "local-ai-lab-main" folder to your Desktop
   ```

3. **Open Terminal in the project folder**:
   - Right-click on the "local-ai-lab-main" folder
   - Select "New Terminal at Folder" (or "Services" → "New Terminal at Folder")

## 🚀 Step 3: One-Command Setup

In the Terminal window that opened, copy and paste this command:

```bash
make first-time
```

Press Enter and follow the prompts. This will:
- ✅ Check that Docker is working
- ✅ Create secure passwords automatically
- ✅ Download and start all AI services
- ✅ Show you where to access everything

**This takes about 5-10 minutes** depending on your internet speed.

### 🐳 Container Manager
**Open**: http://localhost:9000
- See all running services
- Monitor resource usage
- Restart services if needed
- **Create an admin account when prompted**

## 🎉 Step 4: Access Your AI Workspace

Once setup is complete, open these links in your web browser:

### 🤖 AI Chat Interface
**Open**: http://localhost:8080
- Chat with AI models like ChatGPT
- Upload and analyze documents
- Generate images and content
- **No login required for local use**
- **AI models run via Docker Model Runner** (no separate Ollama needed)

### 🔄 Workflow Automation
**Open**: http://localhost:5678
- Create automated workflows
- Connect different services
- Process data automatically
- **Create an account when prompted**

### 🔍 Node-RED Visual Programming
**Open**: http://localhost:1880
- Flow-based visual programming
- IoT and automation platform
- Drag-and-drop interface
- **No login required**

### 📷 CodeProject.AI Computer Vision
**Open**: http://localhost:32168
- Analyze images and video
- Object detection and recognition
- Face detection and analysis
- **No login required**
- **Integrates with workflows**

## 🆘 If Something Goes Wrong

### Quick Fixes:

**Services won't start?**
```bash
make troubleshoot
```
Follow the interactive guide to fix common issues.

**Can't access the websites?**
```bash
make health
```
This checks if everything is working properly.

**Want to start over?**
```bash
make clean-reset
make quick-start
```
This removes everything and starts fresh.

## 💡 Daily Usage

### Starting Your AI Workspace:
```bash
make local-start
```

### Stopping Your AI Workspace:
```bash
make local-stop
```

### Checking Status:
```bash
make status
```

### Getting Help:
```bash
make help
```

## 🔧 Understanding What's Running

```
┌─────────────────────────────────────────────────────────────┐
│                    How It All Works                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Your Mac                                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Docker Desktop                                     │    │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │    │
│  │  │   AI Chat   │ │ Workflows   │ │  Database   │   │    │
│  │  │   Service   │ │   Service   │ │   Service   │   │    │
│  │  └─────────────┘ └─────────────┘ └─────────────┘   │    │
│  │                                                     │    │
│  │  ┌─────────────┐ ┌─────────────┐                   │    │
│  │  │   Proxy     │ │  Container  │                   │    │
│  │  │   Service   │ │   Manager   │                   │    │
│  │  └─────────────┘ └─────────────┘                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  All services talk to each other securely                  │
│  Your data never leaves your Mac                           │
└─────────────────────────────────────────────────────────────┘
```

## 🔒 Privacy & Security

- **Everything runs locally** - No data sent to external servers
- **Your conversations are private** - Stored only on your Mac
- **No subscriptions needed** - All AI models run on your computer
- **Secure by default** - Services are isolated and protected

## 📚 Next Steps

Once you're comfortable with the basics:

1. **Explore AI Models**: Try different AI models in the chat interface
2. **Create Workflows**: Automate repetitive tasks with N8N
3. **Upload Documents**: Process PDFs, images, and text files with AI
4. **Monitor Usage**: Check resource usage in the container manager

## 🤝 Getting Help

- **Interactive troubleshooting**: `make troubleshoot`
- **Health check**: `make health`
- **View all commands**: `make help`
- **Check service status**: `make status`

---

**🎉 Congratulations!** You now have your own private AI workspace running on your Mac!
