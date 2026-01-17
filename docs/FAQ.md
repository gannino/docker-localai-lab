# ❓ Frequently Asked Questions (FAQ)

## 🐛 General Questions

### Q: What exactly is this project?
**A:** It's like having your own private ChatGPT, workflow automation, and file processing system running on your Mac. Everything stays on your computer - no data goes to external companies.

### Q: Do I need to pay for anything?
**A:** No! Everything is free and open-source. You don't need any subscriptions or API keys.

### Q: Will this slow down my Mac?
**A:** It uses about 4-6GB of RAM when running. On modern Macs (8GB+ RAM), you shouldn't notice any slowdown.

### Q: Is my data safe?
**A:** Yes! Everything runs locally on your Mac. Your conversations, files, and data never leave your computer.

### Q: Do I need to install Ollama separately?
**A:** No! This project uses Docker Model Runner, which provides AI model inference without requiring a separate Ollama installation.

## 🛠️ Setup Questions

### Q: I'm getting "Docker not found" error
**A:** You need to install Docker Desktop first:
1. Go to https://www.docker.com/products/docker-desktop/
2. Download and install Docker Desktop
3. Start Docker Desktop (look for whale icon in menu bar)
4. Try the setup again

### Q: The setup is taking forever
**A:** First-time setup downloads several large files (AI models, etc.). This can take 10-30 minutes depending on your internet speed. Be patient!

### Q: I see "port already in use" errors
**A:** Another application is using the same ports. Try:
```bash
make troubleshoot
```
This will help you identify and fix port conflicts.

### Q: Setup failed halfway through
**A:** Start fresh:
```bash
make clean-reset
make quick-start
```

## 🌐 Access Questions

### Q: I can't access http://localhost:8080
**A:** Try these solutions:
1. Wait 2-3 minutes for services to fully start
2. Check if services are running: `make status`
3. Try http://127.0.0.1:8080 instead
4. Run health check: `make health`

### Q: The AI chat isn't responding
**A:** The AI models might still be downloading. Check:
```bash
make logs SERVICE=webui
```
Look for download progress messages.

### Q: N8N is asking for login credentials
**A:** Create a new account - this is your local installation, so use any email/password you want. It's only stored on your Mac.

## 🤖 AI Questions

### Q: Which AI models are available?
**A:** The system supports many open-source models via Docker Model Runner:
- Llama 2/3 (Meta's models)
- Mistral (Fast and efficient)
- CodeLlama (For programming)
- And many others!

Models download automatically when you first use them. No separate Ollama installation required.

### Q: Can I use GPT-4 or Claude?
**A:** This system uses open-source models that run locally. For GPT-4/Claude, you'd need API keys and internet connection, which defeats the privacy purpose.

### Q: The AI responses are slow
**A:** Local AI models are slower than cloud services but more private. Speed depends on:
- Your Mac's processor (M1/M2/M3 are faster)
- Available RAM
- Model size (smaller models are faster)

### Q: Can I upload documents for AI to analyze?
**A:** Yes! The AI chat interface supports:
- PDF files
- Text documents
- Images
- Code files

## 🔧 Technical Questions

### Q: How do I update the system?
**A:**
```bash
make update
```
This downloads the latest versions of all components.

### Q: How do I backup my data?
**A:**
```bash
make backup
```
This saves all your conversations, workflows, and settings.

### Q: How do I free up disk space?
**A:**
```bash
make clean
```
This removes unused Docker images and containers.

### Q: Can I run this on Windows or Linux?
**A:** This guide is Mac-specific, but the Docker setup can work on other systems with minor modifications.

## 🚨 Troubleshooting

### Q: Everything stopped working suddenly
**A:** Try restarting:
```bash
make dev-reset
```
This restarts all services while keeping your data.

### Q: I want to start completely over
**A:** Nuclear option (deletes all data):
```bash
make clean-reset
make quick-start
```

### Q: How do I see what's happening behind the scenes?
**A:** Check the logs:
```bash
make logs                    # All services
make logs SERVICE=webui      # Just AI chat
make logs SERVICE=n8n        # Just workflows
```

### Q: My Mac is running hot/loud
**A:** The AI processing is CPU-intensive. You can:
1. Use smaller AI models
2. Close other applications
3. Run fewer services: `make optimize`

## 💡 Usage Tips

### Q: How do I make workflows in N8N?
**A:** N8N has a visual drag-and-drop interface:
1. Go to http://localhost:5678
2. Click "Add workflow"
3. Drag nodes from the left panel
4. Connect them with lines
5. Configure each node's settings

### Q: What's the difference between N8N and Node-RED?
**A:** Both are automation platforms but with different approaches:
- **N8N** (port 5678): Modern workflow automation, great for API integrations
- **Node-RED** (port 1880): IoT-focused, visual flow programming, simpler interface

Use N8N for complex business workflows, Node-RED for IoT and simple automations.

### Q: Can I access this from other devices on my network?
**A:** By default, it's only accessible from your Mac. For network access, you'd need to modify the configuration (advanced topic).

### Q: What is CodeProject.AI?
**A:** CodeProject.AI is a computer vision service that can:
- Analyze images and detect objects
- Recognize faces and license plates
- Process video streams
- Integrate with N8N workflows for automation

Access it at http://localhost:32168

### Q: How do I know if everything is working?
**A:** Run a health check:
```bash
make health
```
This tests all services and shows their status.

---

## 🆘 Still Need Help?

If your question isn't answered here:

1. **Run interactive troubleshooting**: `make troubleshoot`
2. **Check system health**: `make health`
3. **View all available commands**: `make help`
4. **Check service logs**: `make logs`

Remember: This is designed to be beginner-friendly. Don't be afraid to experiment - you can always reset and start over!
