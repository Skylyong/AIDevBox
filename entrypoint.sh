#!/bin/bash
set -e

BAILIAN_KEY="${BAILIAN_API_KEY:-}"
OPENAI_KEY="${OPENAI_API_KEY:-${OPENAI_API_KEY_PROJECT:-}}"
DEV_HOME="/home/dev"

# ── Claude Code ───────────────────────────────────────────────────────────────
if [ -f /tmp/claude-settings.json ]; then
    mkdir -p /root/.claude
    if [ -n "$BAILIAN_KEY" ]; then
        jq --arg key "$BAILIAN_KEY" '.env.ANTHROPIC_AUTH_TOKEN = $key' \
            /tmp/claude-settings.json > /root/.claude/settings.json
    else
        cp /tmp/claude-settings.json /root/.claude/settings.json
    fi
    mkdir -p "$DEV_HOME/.claude"
    cp /root/.claude/settings.json "$DEV_HOME/.claude/settings.json"
    chown -R dev:dev "$DEV_HOME/.claude"
fi
if [ -f /tmp/claude.json ]; then
    cp /tmp/claude.json /root/.claude.json
    cp /tmp/claude.json "$DEV_HOME/.claude.json"
    chown dev:dev "$DEV_HOME/.claude.json"
fi

# ── Codex ─────────────────────────────────────────────────────────────────────
if [ -f /tmp/codex-config.toml ]; then
    mkdir -p /root/.codex
    cp /tmp/codex-config.toml /root/.codex/config.toml
    mkdir -p "$DEV_HOME/.codex"
    cp /tmp/codex-config.toml "$DEV_HOME/.codex/config.toml"
    chown -R dev:dev "$DEV_HOME/.codex"
fi
if [ -n "$BAILIAN_KEY" ] || [ -n "$OPENAI_KEY" ]; then
    {
        [ -n "$BAILIAN_KEY" ] && printf 'export BAILIAN_API_KEY="%s"\n' "$BAILIAN_KEY"
        [ -n "$OPENAI_KEY" ] && printf 'export OPENAI_API_KEY="%s"\n' "$OPENAI_KEY"
    } > /etc/profile.d/api-keys.sh
    chmod 644 /etc/profile.d/api-keys.sh
    [ -n "$BAILIAN_KEY" ] && export BAILIAN_API_KEY="$BAILIAN_KEY"
    [ -n "$OPENAI_KEY" ] && export OPENAI_API_KEY="$OPENAI_KEY"
fi

# ── OpenCode ──────────────────────────────────────────────────────────────────
if [ -f /tmp/opencode.json ]; then
    mkdir -p /root/.config/opencode
    if [ -n "$BAILIAN_KEY" ]; then
        sed "s|YOUR_API_KEY|${BAILIAN_KEY}|g" \
            /tmp/opencode.json > /root/.config/opencode/opencode.json
    else
        cp /tmp/opencode.json /root/.config/opencode/opencode.json
    fi
    mkdir -p "$DEV_HOME/.config/opencode"
    cp /root/.config/opencode/opencode.json "$DEV_HOME/.config/opencode/opencode.json"
    chown -R dev:dev "$DEV_HOME/.config"
fi

# ── Proxy (persist into shell profiles for SSH sessions) ─────────────────────
# Normalize upper/lower-case proxy vars so common CLIs see the same values.
[ -n "$HTTP_PROXY" ]  && [ -z "$http_proxy" ]  && http_proxy="$HTTP_PROXY"
[ -n "$HTTPS_PROXY" ] && [ -z "$https_proxy" ] && https_proxy="$HTTPS_PROXY"
[ -n "$ALL_PROXY" ]   && [ -z "$all_proxy" ]   && all_proxy="$ALL_PROXY"
[ -n "$NO_PROXY" ]    && [ -z "$no_proxy" ]    && no_proxy="$NO_PROXY"
[ -n "$http_proxy" ]  && [ -z "$HTTP_PROXY" ]  && HTTP_PROXY="$http_proxy"
[ -n "$https_proxy" ] && [ -z "$HTTPS_PROXY" ] && HTTPS_PROXY="$https_proxy"
[ -n "$all_proxy" ]   && [ -z "$ALL_PROXY" ]   && ALL_PROXY="$all_proxy"
[ -n "$no_proxy" ]    && [ -z "$NO_PROXY" ]    && NO_PROXY="$no_proxy"

if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$ALL_PROXY" ]; then
    cat > /etc/profile.d/proxy.sh <<PROXYEOF
export HTTP_PROXY="${HTTP_PROXY}"
export HTTPS_PROXY="${HTTPS_PROXY}"
export ALL_PROXY="${ALL_PROXY}"
export NO_PROXY="${NO_PROXY}"
export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export all_proxy="${all_proxy}"
export no_proxy="${no_proxy}"
PROXYEOF

    git config --global http.proxy  "$HTTP_PROXY"  2>/dev/null || true
    git config --global https.proxy "$HTTPS_PROXY" 2>/dev/null || true
    su - dev -c "git config --global http.proxy  '$HTTP_PROXY'"  2>/dev/null || true
    su - dev -c "git config --global https.proxy '$HTTPS_PROXY'" 2>/dev/null || true
fi

# ── dev user .profile ────────────────────────────────────────────────────────
cat > "$DEV_HOME/.profile" <<'PROFILE'
[ -f /etc/profile ] && . /etc/profile
[ -d /workspace ] && cd /workspace
PROFILE
chown dev:dev "$DEV_HOME/.profile"

# ── SSH server ────────────────────────────────────────────────────────────────
if command -v sshd >/dev/null 2>&1 && [ -f /tmp/authorized_keys ]; then
    mkdir -p /root/.ssh
    cp /tmp/authorized_keys /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    chown -R root:root /root/.ssh

    mkdir -p "$DEV_HOME/.ssh"
    cp /tmp/authorized_keys "$DEV_HOME/.ssh/authorized_keys"
    chmod 700 "$DEV_HOME/.ssh"
    chmod 600 "$DEV_HOME/.ssh/authorized_keys"
    chown -R dev:dev "$DEV_HOME/.ssh"

    /usr/sbin/sshd
fi

# Keep container alive when no foreground command is given
if [ $# -eq 0 ] || [ "$1" = "bash" -a $# -eq 1 ]; then
    exec sleep infinity
fi

exec "$@"
