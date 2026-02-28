# Python AI Agent Dev Environment

基于 Docker 的 Python 3.12 AI 智能体开发环境，预装 OpenCode / Claude Code / Codex 三大 AI 编码助手及常用开发工具。

## 快速开始

### 1. 一键构建

```bash
git clone <your-repo-url> my-dev-env && cd my-dev-env
docker compose build
```

### 2. 配置 .env

复制模板并填入配置：

```bash
cp .env.example .env
# 编辑 .env，将 sk-your-key-here 替换为实际的 API Key
```

| 变量 | 说明 |
|------|------|
| `BAILIAN_API_KEY` | 百炼 Coding Plan API Key，三大 AI 开发z工具共用。获取地址：[百炼控制台](https://bailian.console.aliyun.com/cn-beijing/?tab=model#/efm/coding_plan) |
| `SSH_AUTHORIZED_KEYS` | 宿主机 `authorized_keys` 文件路径，挂载到容器内用于 SSH 免密登录。默认 `/home/ubuntu/.ssh/authorized_keys`；若公钥在其他路径，可修改此变量 |

`.env` 文件已在 `.gitignore` 中，不会被提交到 Git。

### 3. 启动开发环境

```bash
docker compose up -d
```

容器在后台运行后，有以下方式进入：

**方式一：docker exec（宿主机本地）**

```bash
docker compose exec dev bash
```

**方式二：SSH（支持远程访问）**

容器将宿主机的 `~/.ssh/authorized_keys` 挂载到容器内，支持免密 SSH 登录：

```bash
ssh -p 22255 root@localhost          # 从宿主机本地
ssh -p 22255 root@<宿主机IP>         # 从远程机器
```

> 前提：宿主机 `~/.ssh/authorized_keys` 中包含你的公钥。

进入容器后即可直接使用 `claude`、`opencode`、`codex` 命令，所有配置已通过仓库内的配置文件和环境变量自动注入，**无需手动登录或配置**。

## 配置文件映射

所有 AI CLI 的配置文件存放在仓库的 `dotfiles/` 目录中，作为只读模板挂载到容器的 `/tmp/`，由 `entrypoint.sh` 在启动时复制到正确位置并注入 API Key：

| 工具 | 仓库模板 | 容器最终路径 | 说明 |
|------|---------|------------|------|
| Claude Code | `dotfiles/claudeCode/.claude/settings.json` | `/root/.claude/settings.json` | 注入 `ANTHROPIC_AUTH_TOKEN` 到 env 块 |
| Claude Code | `dotfiles/claudeCode/.claude.json` | `/root/.claude.json` | 跳过 onboarding |
| Codex | `dotfiles/codex/.codex/config.toml` | `/root/.codex/config.toml` | 通过 `env_key` 读取 `OPENAI_API_KEY` 环境变量 |
| OpenCode | `dotfiles/opencode/opencode.json` | `/root/.config/opencode/opencode.json` | 替换 `YOUR_API_KEY` 占位符为实际 Key |
| 工作区 | `~/projects/` | `/workspace/` | 你的项目文件 |

### API Key 注入机制

三大工具共用一个百炼 Coding Plan API Key，通过 `.env` 文件中的 `BAILIAN_API_KEY` 传入。`entrypoint.sh` 在容器启动时统一处理注入：

| 工具 | 注入方式 |
|------|---------|
| Claude Code | `jq` 将 `BAILIAN_API_KEY` 写入 `settings.json` 的 `env.ANTHROPIC_AUTH_TOKEN` 字段 |
| Codex | `export OPENAI_API_KEY`，config.toml 通过 `env_key` 引用该环境变量 |
| OpenCode | `sed` 将配置模板中的 `YOUR_API_KEY` 占位符替换为实际 Key |

如需修改映射路径或配置，编辑 `docker-compose.yml` 和 `dotfiles/` 下的对应文件即可。

## 预装内容一览

### 系统工具

| 类别 | 工具 |
|------|------|
| 版本控制 | git |
| 网络 | curl, wget, httpie |
| 编辑器 | vim, nano |
| 终端复用 | screen, tmux |
| 编译构建 | build-essential, cmake, pkg-config |
| JSON/YAML | jq, yq |
| 系统工具 | htop, tree, less, unzip, zip |
| 网络调试 | net-tools, iputils-ping, dnsutils, openssh-client |

### 包管理器

| 工具 | 说明 |
|------|------|
| **uv** | 极速 Python 包管理器，替代 pip / pip-tools / virtualenv |
| pipx | 隔离安装 Python CLI 工具 |
| npm | Node.js 20 LTS，用于安装 JS 生态 CLI |

### Python AI 开发包

| 包名 | 用途 |
|------|------|
| openai, anthropic | 大模型 API 客户端 |
| langchain, langchain-openai, langchain-anthropic | Agent 框架 |
| langgraph | Agent 编排 |
| openai-agents | OpenAI Agents SDK |
| opencode-agent-sdk | OpenCode Python SDK |
| httpx, aiohttp | 异步 HTTP |
| pydantic | 数据校验 |
| python-dotenv | 环境变量管理 |
| rich | 终端美化输出 |
| tiktoken | Token 计数 |
| numpy, pandas | 数据处理 |
| jupyter, ipython | 交互式开发 |

### AI 编码 CLI（已预配置百炼 Coding Plan）

| 工具 | 命令 | 说明 |
|------|------|------|
| Claude Code | `claude` | Anthropic 官方 AI 编码助手，通过百炼 Anthropic 兼容接口调用 |
| OpenCode | `opencode` | 开源多模型 AI 编码助手，支持 qwen3.5-plus / kimi-k2.5 等多模型 |
| Codex | `codex` | OpenAI 官方 AI 编码助手（v0.80.0，兼容 Chat API） |

## 常用操作

### 安装额外 Python 包

```bash
uv pip install --system <package-name>
```

### 创建隔离虚拟环境

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### 启动 Jupyter Notebook

```bash
# 需要在 docker-compose.yml 中添加端口映射: ports: ["8888:8888"]
jupyter notebook --ip=0.0.0.0 --allow-root --no-browser
```

### 使用 screen 保持后台任务

```bash
screen -S train          # 创建名为 train 的会话
# ... 运行长时间任务 ...
# Ctrl+A, D              # 分离会话
screen -r train          # 重新连接
```

## 环境迁移

本仓库可安全推送到 GitHub，所有 AI 工具配置（Base URL、模型列表等）均存放在仓库内。敏感信息（API Key）通过宿主机环境变量注入，不会进入版本控制。

迁移到新机器只需：

```bash
git clone <your-repo-url> my-dev-env && cd my-dev-env
docker compose build
cp .env.example .env    # 编辑 .env 填入 API Key
docker compose up -d
docker compose exec dev bash
```

进入容器后所有 AI CLI 即可直接使用，无需额外登录或配置。

## 自定义

- **修改 Python 依赖**：编辑 `requirements.txt`，重新 `docker compose build`
- **修改工作区路径**：编辑 `docker-compose.yml` 中 `~/projects:/workspace`
- **添加端口映射**：在 `docker-compose.yml` 中加入 `ports` 配置
- **切换 Python 版本**：修改 `Dockerfile` 首行的基础镜像标签
- **切换 AI 模型**：编辑 `dotfiles/` 下对应工具的配置文件（如将 `qwen3.5-plus` 改为 `qwen3-coder-next`）
- **更换 API 提供商**：修改配置文件中的 Base URL 和模型列表，并调整 `docker-compose.yml` 中的环境变量
