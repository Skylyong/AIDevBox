FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    TERM=xterm-256color

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # version control
    git \
    # network
    curl \
    wget \
    httpie \
    # editors
    vim \
    nano \
    # terminal multiplexers
    screen \
    tmux \
    # build toolchain
    build-essential \
    cmake \
    pkg-config \
    # json / yaml
    jq \
    yq \
    # process / system utilities
    htop \
    tree \
    less \
    unzip \
    zip \
    tar \
    gzip \
    # network debugging
    net-tools \
    iputils-ping \
    dnsutils \
    openssh-client \
    openssh-server \
    # sandbox
    bubblewrap \
    # infrastructure
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ── Ghostty terminfo (so TERM=xterm-ghostty works over SSH / docker exec) ───
COPY terminfo/78/xterm-ghostty /usr/share/terminfo/x/xterm-ghostty

# ── Node.js 20 LTS (for OpenCode & Codex CLI) ───────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# ── uv – fast Python package manager ─────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# ── pipx ──────────────────────────────────────────────────────────────────────
RUN pip install --no-cache-dir pipx \
    && pipx ensurepath

# ── Python AI development packages (installed with uv into system Python) ────
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# ── Users ─────────────────────────────────────────────────────────────────────
RUN echo 'root:root@123' | chpasswd \
    && useradd -m -s /bin/bash dev \
    && echo 'dev:dev@123' | chpasswd \
    && su - dev -c "pipx ensurepath" \
    && echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> /home/dev/.bashrc \
    && echo "alias claude-d='claude --dangerously-skip-permissions'" >> /home/dev/.bashrc \
    && echo 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' >> /home/dev/.bash_profile

# ── AI coding CLI tools（以 dev 身份安装，无需 root 权限即可 npm install -g）──
# npm prefix 指向 dev 自有目录，update / install 完全由 dev 用户控制
RUN su - dev -c " \
    npm config set prefix '/home/dev/.npm-global' \
    && npm install -g @anthropic-ai/claude-code opencode-ai @openai/codex \
    "

# ── SSH server ─────────────────────────────────────────────────────────────────
RUN mkdir -p /run/sshd /root/.ssh /home/dev/.ssh \
    && chmod 700 /root/.ssh /home/dev/.ssh \
    && chown dev:dev /home/dev/.ssh \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
EXPOSE 22

# ── Workspace ─────────────────────────────────────────────────────────────────
RUN mkdir -p /workspace && chown dev:dev /workspace
WORKDIR /workspace

CMD ["bash"]
