# VS Code LLM Integration Guide

## 🎯 Overview
This guide shows how to integrate VS Code with local LLMs running in your Docker infrastructure for AI-powered coding assistance, completely private and offline.

## 🚀 Quick Setup

### Prerequisites
- VS Code installed
- Local AI Lab running (`make local-start`)
- Open WebUI accessible at http://localhost:8080

### Essential Extensions

#### 1. Continue - Local AI Code Assistant ✨ **Recommended**
```
Extension ID: Continue.continue
```
**Why**: Best local LLM integration, supports Ollama, completely private

**Setup**:
1. Install Continue extension
2. Open Command Palette (`Cmd+Shift+P`)
3. Run "Continue: Open config.json"
4. Replace with this configuration:

```json
{
  "models": [
    {
      "title": "Local Ollama",
      "provider": "ollama",
      "model": "codellama:7b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Local Ollama - Code",
      "provider": "ollama",
      "model": "deepseek-coder:6.7b",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Tab Autocomplete",
    "provider": "ollama",
    "model": "codellama:7b",
    "apiBase": "http://localhost:11434"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://localhost:11434"
  }
}
```

**Features**:
- Chat with your code
- Inline code completion
- Code explanations
- Refactoring suggestions
- Works completely offline

#### 2. Cline - Autonomous AI Agent ✨ **Alternative**
```
Extension ID: saoudrizwan.claude-dev
```
**Why**: Autonomous agent with Plan & Act workflow, transparent decision-making

**Setup**:
1. Install Cline extension
2. Configure API key (Claude, OpenAI, or local models)
3. Grant file system permissions when prompted

**Features**:
- **Plan Mode**: AI analyzes and proposes strategy without changing code
- **Act Mode**: Autonomous execution after user approval
- Terminal command execution
- Multi-file refactoring
- Cost tracking with token counts

### Continue vs Cline: Key Differences

| Feature | Continue | Cline |
|---------|----------|-------|
| **Philosophy** | Governance-first, granular control | Autonomy-first, strategic planning |
| **Workflow** | Generate → Show diff → User approves each change | Plan → User approves strategy → Execute autonomously |
| **Multi-file changes** | Requires approval per file | Single approval for entire strategy |
| **Terminal access** | No command execution | Can run tests, linting, builds |
| **IDE support** | VS Code + JetBrains + CLI | VS Code only |
| **Best for** | Teams, compliance, audit trails | Solo developers, large refactoring |
| **Autonomy level** | Manual approval per change | Autonomous execution after plan approval |
| **Enterprise features** | Team configuration, governance | Transparent cost tracking |

### When to Choose Continue:
✅ You need granular control over every code change
✅ Working in teams with compliance requirements
✅ Using multiple IDEs (PyCharm, IntelliJ, WebStorm)
✅ Need audit trails for code changes
✅ Prefer step-by-step approval workflow
✅ Want centralized team configuration

### When to Choose Cline:
✅ You trust AI to execute multi-step plans autonomously
✅ Working on large refactoring projects (20+ files)
✅ Want transparent cost tracking (token counts)
✅ Need terminal command execution (testing, building)
✅ Prefer "plan once, execute without interruption"
✅ Solo developer or small team (<5 people)

### Example Workflow Comparison

**Task**: Refactor authentication across 15 files

**With Continue**:
1. Describe task → Continue generates code for file 1 → User approves
2. Continue generates code for file 2 → User approves
3. Repeat for all 15 files (15 approval steps)
4. Manually run tests and fix issues
5. **Time**: ~30 minutes of active user involvement

**With Cline**:
1. Describe task → Cline analyzes codebase (Plan Mode)
2. Cline proposes strategy: "Refactor files A-C first, then D-O"
3. User reviews plan and approves once
4. Cline executes autonomously, runs tests, fixes failures
5. **Time**: ~5 minutes of user involvement

#### 3. Codeium - Free AI Assistant
```
Extension ID: Codeium.codeium
```
**Why**: Free tier, good autocomplete, can work with local models

**Setup**:
1. Install Codeium extension
2. Sign up for free account
3. Configure to use local endpoint (if supported)

#### 3. Tabnine - AI Code Completion
```
Extension ID: TabNine.tabnine-vscode
```
**Why**: Local model option available, privacy-focused

**Setup**:
1. Install Tabnine extension
2. Choose local model option in settings
3. Configure for offline usage

#### 4. GitHub Copilot (Alternative)
```
Extension ID: GitHub.copilot
```
**Note**: Requires subscription, sends code to GitHub servers

## 🔧 Advanced Configuration

### Continue Extension Deep Dive

#### Best Models for Coding
```json
{
  "models": [
    {
      "title": "DeepSeek Coder 6.7B",
      "provider": "ollama",
      "model": "deepseek-coder:6.7b",
      "apiBase": "http://localhost:11434",
      "contextLength": 16384
    },
    {
      "title": "Code Llama 13B",
      "provider": "ollama",
      "model": "codellama:13b",
      "apiBase": "http://localhost:11434",
      "contextLength": 16384
    },
    {
      "title": "Phind CodeLlama 34B",
      "provider": "ollama",
      "model": "phind-codellama:34b",
      "apiBase": "http://localhost:11434",
      "contextLength": 16384
    }
  ]
}
```

#### Custom System Messages
```json
{
  "systemMessage": "You are a senior software engineer helping with code. Be concise, provide working code examples, and explain your reasoning. Focus on best practices, security, and maintainability."
}
```

#### Slash Commands Configuration
```json
{
  "slashCommands": [
    {
      "name": "edit",
      "description": "Edit selected code"
    },
    {
      "name": "comment",
      "description": "Add comments to code"
    },
    {
      "name": "share",
      "description": "Share code context"
    },
    {
      "name": "cmd",
      "description": "Generate terminal commands"
    }
  ]
}
```

### OpenAI API Compatible Setup

If using Open WebUI's OpenAI-compatible API:

```json
{
  "models": [
    {
      "title": "Local WebUI",
      "provider": "openai",
      "model": "gpt-3.5-turbo",
      "apiKey": "sk-dummy-key",
      "apiBase": "http://localhost:8080/ollama/v1"
    }
  ]
}
```

## 🤖 Recommended AI Models for Coding

### Download via Open WebUI or Ollama CLI

#### Small Models (8GB RAM)
```bash
# In Open WebUI or via CLI
ollama pull codellama:7b          # General coding
ollama pull deepseek-coder:6.7b   # Excellent for code
ollama pull codeup:13b            # Code understanding
```

#### Medium Models (16GB RAM)
```bash
ollama pull codellama:13b         # Better reasoning
ollama pull deepseek-coder:33b    # Professional grade
ollama pull phind-codellama:34b   # Web development focused
```

#### Large Models (32GB+ RAM)
```bash
ollama pull codellama:70b         # Best performance
ollama pull deepseek-coder:67b    # Enterprise grade
```

### Model Comparison

| Model | Size | Best For | RAM Needed |
|-------|------|----------|------------|
| codellama:7b | 3.8GB | General coding, fast responses | 8GB |
| deepseek-coder:6.7b | 3.8GB | Code completion, debugging | 8GB |
| codellama:13b | 7.3GB | Complex reasoning, refactoring | 16GB |
| phind-codellama:34b | 19GB | Web dev, full-stack projects | 32GB |
| deepseek-coder:33b | 19GB | Enterprise development | 32GB |

## 🛠️ VS Code Settings for AI Development

### Settings.json Configuration
```json
{
  // Continue extension settings
  "continue.enableTabAutocomplete": true,
  "continue.manuallyTriggerCompletion": false,

  // Editor settings for AI assistance
  "editor.inlineSuggest.enabled": true,
  "editor.suggestSelection": "first",
  "editor.tabCompletion": "on",
  "editor.wordBasedSuggestions": false,

  // Copilot settings (if using)
  "github.copilot.enable": {
    "*": true,
    "yaml": false,
    "plaintext": false
  }
}
```

### Keybindings for AI Features
```json
[
  {
    "key": "cmd+i",
    "command": "continue.continueGUIView.focus"
  },
  {
    "key": "cmd+shift+i",
    "command": "continue.acceptVerticalDiffBlock"
  },
  {
    "key": "cmd+shift+backspace",
    "command": "continue.rejectVerticalDiffBlock"
  }
]
```

## 🔌 Integration with Local AI Lab Services

### Connect to Open WebUI
```json
{
  "models": [
    {
      "title": "Open WebUI",
      "provider": "openai",
      "model": "gpt-3.5-turbo",
      "apiKey": "dummy",
      "apiBase": "http://localhost:8080/ollama/v1"
    }
  ]
}
```

### Connect to N8N Workflows
Create N8N workflows that:
- Process code snippets
- Generate documentation
- Run code analysis
- Create test cases

### Connect to Future Services
When you add these services from the roadmap:
- **Langfuse**: Track AI coding assistance usage
- **Dify**: Build custom coding assistants
- **Jupyter Lab**: Analyze code patterns

## 📝 Usage Examples

### 1. Code Explanation
Select code and ask: "Explain this function"

### 2. Code Generation
Type comment: `// Create a function that validates email addresses`
Then trigger AI completion

### 3. Refactoring
Select code and ask: "Refactor this to be more efficient"

### 4. Bug Fixing
Select problematic code: "Find and fix the bug in this code"

### 5. Documentation
Select function: "Generate JSDoc comments for this function"

### 6. Test Generation
Select function: "Generate unit tests for this function"

## 🚀 Workflow Tips

### Best Practices
1. **Start Small**: Use 7B models first, upgrade as needed
2. **Context Matters**: Select relevant code before asking questions
3. **Be Specific**: "Fix the authentication bug" vs "Fix this"
4. **Iterate**: Use AI suggestions as starting points
5. **Review**: Always review AI-generated code

### Keyboard Shortcuts
- `Cmd+I`: Open Continue chat
- `Cmd+Shift+I`: Accept AI suggestion
- `Cmd+L`: Select current line for context
- `Cmd+A`: Select all for full file context

### Performance Optimization
- Use smaller models for autocomplete
- Use larger models for complex reasoning
- Keep context window reasonable (don't select entire large files)
- Close unused AI extensions to save resources

## 🔒 Privacy & Security

### Why Local LLMs?
- **Complete Privacy**: Code never leaves your machine
- **No Internet Required**: Works offline
- **No Subscriptions**: Free after initial setup
- **Custom Models**: Train on your codebase
- **Enterprise Safe**: No data sharing concerns

### Security Best Practices
- Never include API keys in prompts
- Review generated code for security issues
- Use local models for sensitive projects
- Keep AI models updated
- Monitor resource usage

## 🚨 Troubleshooting

### Continue Extension Issues
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Restart Continue extension
# Command Palette > "Developer: Reload Window"
```

### Model Not Responding
1. Check Open WebUI is running: http://localhost:8080
2. Verify model is downloaded in Open WebUI
3. Check Continue config.json syntax
4. Restart VS Code

### Performance Issues
1. Use smaller models (7B instead of 13B+)
2. Reduce context length in config
3. Close other resource-heavy applications
4. Check Docker resource limits

### Connection Issues
```bash
# Test local endpoints
curl http://localhost:8080/ollama/v1/models
curl http://localhost:11434/api/tags
```

## 🎯 Future Enhancements

### When VS Code Server is Added (Phase 4)
- Browser-based development with AI
- Remote development with local AI
- Team collaboration with shared AI models

### Integration with Roadmap Services
- **Langfuse**: Track AI coding metrics
- **Dify**: Custom coding assistants
- **Flowise**: Visual AI workflows for code
- **Jupyter**: Code analysis and insights

## 📚 Additional Resources

- [Continue Documentation](https://continue.dev/docs)
- [Ollama Model Library](https://ollama.ai/library)
- [VS Code AI Extensions](https://marketplace.visualstudio.com/search?term=ai&target=VSCode)
- [Local AI Development Best Practices](https://github.com/continue-dev/continue)

---

**Ready to start?** Install Continue extension and run `make local-start` to begin AI-powered coding!
