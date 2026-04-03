#!/bin/bash
set -e

DEV_HOME="/home/dev"

# ── 确保 dev home 目录归属正确 ──────────────────────────────────────────────
chown dev:dev "$DEV_HOME"

# ── Proxy (persist into shell profiles for SSH sessions) ─────────────────────
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
