# AIDevBox

**Dockerized AI Development Environment with Claude Code, Codex, OpenCode & More**

![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)
![built with](https://img.shields.io/badge/built%20with-Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![python](https://img.shields.io/badge/python-3.12-3776AB?style=flat-square&logo=python&logoColor=white)
![powered by](https://img.shields.io/badge/powered%20by-cc--switch-orange?style=flat-square)

[English](#) | [中文](#)

---

## Features

- **Three AI coding assistants** — Claude Code / OpenCode / Codex, ready to use out of the box
- **Hot-swap AI providers** — cc-switch manages all API configs on the host; changes sync instantly, no restart needed
- **Python AI toolkit** — LangChain, LangGraph, OpenAI Agents SDK, and more pre-installed
- **SSH & Docker exec** — access from local or remote machines
- **Proxy-friendly** — optional HTTP/SOCKS5 proxy, auto-injected into shell and git
- **Portable** — clone, build, run. API keys stay on the host, never enter version control

## Quick Start

### 1. Install cc-switch (host machine)

[cc-switch](https://github.com/farion1231/cc-switch) is a desktop app that manages API configurations for Claude Code, Codex, and OpenCode.

**macOS:**

```bash
brew tap farion1231/ccswitch && brew install --cask cc-switch
```

**Linux:** download from [GitHub Releases](https://github.com/farion1231/cc-switch/releases).

Open cc-switch, configure your API Provider and Key. It writes config to `~/.claude/`, `~/.codex/`, `~/.config/opencode/` on the host.

### 2. Clone & Build

```bash
git clone <your-repo-url> aidevbox && cd aidevbox
docker compose build
```

### 3. Configure .env

```bash
cp .env.example .env
```

Edit `.env` with your settings:

| Variable | Description |
|----------|-------------|
| `PROJECT_DIR` | Host project directory, mounted as `/workspace`. Default: `~/projects` |
| `SSH_AUTHORIZED_KEYS` | **Absolute path** to your `.pub` key file. Use ed25519 or RSA |
| `SSH_AGENT_SOCKET` | Optional `ssh-agent` socket visible to Docker. Leave unset on macOS Docker Desktop; set explicitly for Colima/Linux |
| `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` | Optional proxy. Leave empty for direct connection |

Before starting the container, make sure your key is loaded in the host agent:

```bash
ssh-add -l || ssh-add ~/.ssh/id_ed25519
```

For Colima, enable agent forwarding into the Colima VM first, then persist the VM-visible socket in `.env`:

```bash
colima stop
sed -i.bak 's/forwardAgent: false/forwardAgent: true/' ~/.colima/default/colima.yaml
colima start
echo "SSH_AGENT_SOCKET=$(colima ssh -- printenv SSH_AUTH_SOCK)" >> .env
```

For a native Linux Docker engine, persist the host socket in `.env`:

```bash
echo "SSH_AGENT_SOCKET=$SSH_AUTH_SOCK" >> .env
```

### 4. Start

```bash
docker compose up -d
```

### 5. Connect

**Docker exec (local):**

```bash
docker compose exec -u dev dev bash   # as dev user (recommended)
docker compose exec dev bash           # as root
```

**SSH (local or remote):**

```bash
ssh -p 22255 dev@localhost             # as dev user (recommended)
ssh -p 22255 dev@<host-ip>            # from remote machine
```

Once inside, `claude`, `opencode`, and `codex` are ready to use — no additional login or setup required.

## Users & Permissions

| User | Default Password | Notes |
|------|-----------------|-------|
| `dev` | `dev@123` | Daily development, owns `/workspace` |
| `root` | `root@123` | System-level installs only |

## Volume Mounts

| Host Path | Container Path | Description |
|-----------|---------------|-------------|
| `~/.claude/` | `/root/.claude/`, `/home/dev/.claude/` | Claude Code config (cc-switch managed) |
| `~/.codex/` | `/root/.codex/`, `/home/dev/.codex/` | Codex config (cc-switch managed) |
| `~/.config/opencode/` | `/root/.config/opencode/`, `/home/dev/.config/opencode/` | OpenCode config (cc-switch managed) |
| `${PROJECT_DIR}` | `/workspace/` | Your project files |
| `${SSH_AGENT_SOCKET:-/run/host-services/ssh-auth.sock}` | `/ssh-agent` | Host ssh-agent socket for Git/SSH signing inside the container |

## Pre-installed

### AI Coding CLIs

| Tool | Command | Description |
|------|---------|-------------|
| Claude Code | `claude` | Anthropic's AI coding assistant |
| OpenCode | `opencode` | Open-source multi-model AI coding assistant |
| Codex | `codex` | OpenAI's AI coding assistant |

### Python AI Packages

| Package | Purpose |
|---------|---------|
| openai, anthropic | LLM API clients |
| langchain, langchain-openai, langchain-anthropic | Agent framework |
| langgraph | Agent orchestration |
| openai-agents, opencode-agent-sdk | Agent SDKs |
| httpx, aiohttp | Async HTTP |
| pydantic | Data validation |
| numpy, pandas | Data processing |
| jupyter, ipython | Interactive development |
| rich, tiktoken | Terminal output & tokenization |

### System Tools

git, curl, wget, httpie, vim, nano, screen, tmux, build-essential, cmake, jq, yq, htop, tree, uv, pipx, Node.js 20 LTS

## Customization

- **Switch AI model / provider** — use cc-switch, hot-synced, no restart needed
- **Change project directory** — edit `PROJECT_DIR` in `.env`
- **Add Python packages** — edit `requirements.txt`, rebuild with `docker compose build`
- **Add port mappings** — add `ports` in `docker-compose.yml`
- **Change Python version** — modify the base image tag in `Dockerfile`

## License

MIT
