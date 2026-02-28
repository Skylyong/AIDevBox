#!/bin/bash
set -e

KEY="${BAILIAN_API_KEY}"

# ── Claude Code ───────────────────────────────────────────────────────────────
# Copy template and inject API key into env block
if [ -f /tmp/claude-settings.json ]; then
    mkdir -p /root/.claude
    if [ -n "$KEY" ]; then
        # Add ANTHROPIC_AUTH_TOKEN into the env object
        jq --arg key "$KEY" '.env.ANTHROPIC_AUTH_TOKEN = $key' \
            /tmp/claude-settings.json > /root/.claude/settings.json
    else
        cp /tmp/claude-settings.json /root/.claude/settings.json
    fi
fi
if [ -f /tmp/claude.json ]; then
    cp /tmp/claude.json /root/.claude.json
fi

# ── Codex ─────────────────────────────────────────────────────────────────────
# Copy config and export OPENAI_API_KEY
if [ -f /tmp/codex-config.toml ]; then
    mkdir -p /root/.codex
    cp /tmp/codex-config.toml /root/.codex/config.toml
fi
if [ -n "$KEY" ]; then
    export OPENAI_API_KEY="$KEY"
fi

# ── OpenCode ──────────────────────────────────────────────────────────────────
# Copy template and replace placeholder with actual key
if [ -f /tmp/opencode.json ]; then
    mkdir -p /root/.config/opencode
    if [ -n "$KEY" ]; then
        sed "s|YOUR_API_KEY|${KEY}|g" \
            /tmp/opencode.json > /root/.config/opencode/opencode.json
    else
        cp /tmp/opencode.json /root/.config/opencode/opencode.json
    fi
fi

# ── SSH server ────────────────────────────────────────────────────────────────
if command -v sshd >/dev/null 2>&1 && [ -f /tmp/authorized_keys ]; then
    mkdir -p /root/.ssh
    cp /tmp/authorized_keys /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    chown -R root:root /root/.ssh
    /usr/sbin/sshd
fi

# Keep container alive when no foreground command is given
if [ $# -eq 0 ] || [ "$1" = "bash" -a $# -eq 1 ]; then
    exec sleep infinity
fi

exec "$@"
