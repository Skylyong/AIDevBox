#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_docker() {
  command -v docker >/dev/null 2>&1 || die "docker command not found"
  docker info >/dev/null 2>&1 || die "cannot reach Docker daemon"
}

show_disk_usage() {
  docker system df
}

write_used_image_ids() {
  local output_file="$1"

  : > "$output_file"
  docker container ls -aq | while IFS= read -r container_id; do
    [ -n "$container_id" ] || continue
    docker inspect -f '{{.Image}}' "$container_id"
  done | sort -u > "$output_file"
}

remove_images_not_used_by_containers() {
  local used_image_ids_file="$1"

  docker image ls -aq --no-trunc | sort -u | while IFS= read -r image_id; do
    [ -n "$image_id" ] || continue

    if grep -Fxq "$image_id" "$used_image_ids_file"; then
      printf 'Keep active image: %s\n' "$image_id"
      continue
    fi

    printf 'Remove unused image: %s\n' "$image_id"
    remove_image_id "$image_id" || printf 'Skip image that Docker refused to remove: %s\n' "$image_id" >&2
  done
}

remove_image_id() {
  local image_id="$1"
  local refs_file
  local status=0

  refs_file="$(mktemp "${TMPDIR:-/tmp}/docker-image-refs.XXXXXX")"

  docker image ls -a --no-trunc --format '{{.ID}} {{.Repository}}:{{.Tag}}' |
    while IFS=' ' read -r listed_image_id image_ref; do
      [ "$listed_image_id" = "$image_id" ] || continue
      [ "$image_ref" != "<none>:<none>" ] || continue
      printf '%s\n' "$image_ref"
    done | sort -u > "$refs_file"

  while IFS= read -r image_ref; do
    [ -n "$image_ref" ] || continue
    docker image rm "$image_ref" || status=1
  done < "$refs_file"

  rm -f "$refs_file"

  if docker image inspect "$image_id" >/dev/null 2>&1; then
    docker image rm "$image_id" || status=1
  fi

  return "$status"
}

main() {
  require_docker

  local used_image_ids_file
  used_image_ids_file="$(mktemp "${TMPDIR:-/tmp}/docker-used-images.XXXXXX")"
  trap 'rm -f "$used_image_ids_file"' EXIT

  log "Docker disk usage before cleanup"
  show_disk_usage

  log "Recording image IDs referenced by existing containers"
  write_used_image_ids "$used_image_ids_file"

  log "Pruning images not associated with any container"
  docker image prune -a -f

  log "Removing any remaining images not referenced by containers"
  remove_images_not_used_by_containers "$used_image_ids_file" || true

  log "Pruning Docker build cache"
  docker builder prune -a -f

  log "Docker disk usage after cleanup"
  show_disk_usage

  log "Remaining containers"
  docker container ls -a --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'

  log "Remaining images"
  docker image ls -a --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'
}

main "$@"
