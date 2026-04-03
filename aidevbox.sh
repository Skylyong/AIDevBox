#!/bin/bash
# AIDevBox — common commands
# Usage: ./aidevbox.sh <command>

set -e

CMD="${1:-help}"

case "$CMD" in
  build)
    docker compose build
    ;;
  up)
    docker compose up -d
    ;;
  down)
    docker compose down
    ;;
  restart)
    docker compose down && docker compose up -d
    ;;
  rebuild)
    docker compose down && docker compose build && docker compose up -d
    ;;
  shell)
    docker compose exec -u dev dev bash
    ;;
  root)
    docker compose exec dev bash
    ;;
  ssh)
    ssh -p 22255 dev@localhost
    ;;
  logs)
    docker compose logs -f dev
    ;;
  status)
    docker compose ps
    ;;
  help)
    cat <<'EOF'
AIDevBox — Dockerized AI Development Environment

Usage: ./aidevbox.sh <command>

Commands:
  build     Build the Docker image
  up        Start the container in background
  down      Stop and remove the container
  restart   Restart the container
  rebuild   Full rebuild (down + build + up)
  shell     Enter container as dev user
  root      Enter container as root
  ssh       SSH into container as dev user
  logs      Follow container logs
  status    Show container status
EOF
    ;;
  *)
    echo "Unknown command: $CMD"
    echo "Run './aidevbox.sh help' for usage."
    exit 1
    ;;
esac
