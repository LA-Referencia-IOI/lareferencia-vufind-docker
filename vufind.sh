#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

DEFAULT_VUFIND_REPO_URL="https://github.com/LA-Referencia-IOI/vufind"
DEFAULT_VUFIND_REF="v11.0.1"

usage() {
  cat <<USAGE
Usage: ./vufind.sh <command> [options]

Commands:
  install                    Clone/update VuFind, build images, and start services
  update                     Update VuFind, rebuild without cache, and recreate services
  rebuild                    Rebuild images with current code and recreate services
  restart                    Restart existing containers
  start                      Start existing containers
  stop                       Stop containers without removing volumes or data
  logs [args...]             Show logs
  health                     Check VuFind and external Solr endpoints
  shell                      Open a shell in the VuFind container
  help                       Show this help

Required in .env:
  SOLR_EXTERNAL_URL=http://your-solr:8983/solr
USAGE
}

ensure_env_file() {
  if [ ! -f "${ENV_FILE}" ]; then
    if [ -f "${ENV_EXAMPLE}" ]; then
      cp "${ENV_EXAMPLE}" "${ENV_FILE}"
    else
      touch "${ENV_FILE}"
    fi
  fi
}

get_env_var() {
  local key="$1"
  local default_value="$2"
  local value=""

  if [ -f "${ENV_FILE}" ]; then
    local found
    found="$(awk -F= -v k="${key}" '$1 ~ "^[[:space:]]*"k"[[:space:]]*$" {v=$2} END {gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^"|"$/, "", v); print v}' "${ENV_FILE}" || true)"
    if [ -n "${found}" ]; then
      value="${found}"
    fi
  fi

  if [ -z "${value}" ]; then
    value="${default_value}"
  fi

  printf "%s\n" "${value}"
}

ensure_docker_installed() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not available in PATH." >&2
    exit 1
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "Error: docker compose plugin v2 is required." >&2
    exit 1
  fi
}

external_solr_url() {
  printf "%s\n" "${SOLR_EXTERNAL_URL:-$(get_env_var SOLR_EXTERNAL_URL "")}"
}

require_external_solr() {
  local solr_url
  solr_url="$(external_solr_url)"

  if [ -z "${solr_url}" ]; then
    echo "Error: SOLR_EXTERNAL_URL is required. Set it in ${ENV_FILE}." >&2
    exit 1
  fi

  export SOLR_EXTERNAL_URL="${solr_url}"
}

export_runtime_env() {
  ensure_env_file

  local project_name
  local web_port
  local db_port
  local site_url

  project_name="${COMPOSE_PROJECT_NAME:-$(get_env_var COMPOSE_PROJECT_NAME vufind)}"
  web_port="${VUFIND_WEB_PORT:-$(get_env_var VUFIND_WEB_PORT 8080)}"
  db_port="${VUFIND_DB_PORT:-$(get_env_var VUFIND_DB_PORT 3307)}"
  site_url="${VUFIND_SITE_URL:-$(get_env_var VUFIND_SITE_URL "")}"

  if [ -z "${site_url}" ]; then
    site_url="http://localhost:${web_port}"
  fi

  export COMPOSE_PROJECT_NAME="${project_name}"
  export VUFIND_WEB_PORT="${web_port}"
  export VUFIND_DB_PORT="${db_port}"
  export VUFIND_SITE_URL="${site_url}"
}

dc() {
  export_runtime_env
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" "$@"
}

dir_has_content() {
  local dir="$1"
  find "${dir}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .
}

vufind_dir() {
  printf "%s\n" "${SCRIPT_DIR}/vufind"
}

get_vufind_repo_url() {
  printf "%s\n" "${VUFIND_REPO_URL:-$(get_env_var VUFIND_REPO_URL "${DEFAULT_VUFIND_REPO_URL}")}"
}

get_vufind_ref() {
  printf "%s\n" "${VUFIND_REF:-$(get_env_var VUFIND_REF "${DEFAULT_VUFIND_REF}")}"
}

ensure_vufind_checkout() {
  local target_dir
  local repo_url
  local repo_ref

  target_dir="$(vufind_dir)"
  ensure_env_file

  if [ -f "${target_dir}/composer.json" ]; then
    return 0
  fi

  if [ -d "${target_dir}" ] && dir_has_content "${target_dir}"; then
    echo "Error: ${target_dir} exists but is not a VuFind checkout." >&2
    echo "Move it aside or provide a valid checkout with composer.json." >&2
    exit 1
  fi

  repo_url="$(get_vufind_repo_url)"
  repo_ref="$(get_vufind_ref)"

  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is not available in PATH; cannot clone VuFind." >&2
    exit 1
  fi

  echo "Cloning VuFind ${repo_ref} from ${repo_url}..."
  git clone --quiet --branch "${repo_ref}" --single-branch "${repo_url}" "${target_dir}"
}

ensure_clean_vufind_checkout() {
  local target_dir

  target_dir="$(vufind_dir)"

  if [ ! -d "${target_dir}/.git" ]; then
    echo "Error: ${target_dir} is not a Git checkout; cannot update VuFind." >&2
    exit 1
  fi

  if [ -n "$(git -C "${target_dir}" status --porcelain)" ]; then
    echo "Error: local changes found in ${target_dir}; commit, stash, or remove them before update." >&2
    exit 1
  fi
}

update_vufind_checkout() {
  local target_dir
  local repo_url
  local repo_ref
  local target_ref
  local target_commit

  ensure_env_file
  ensure_vufind_checkout
  ensure_clean_vufind_checkout

  target_dir="$(vufind_dir)"
  repo_url="$(get_vufind_repo_url)"
  repo_ref="$(get_vufind_ref)"

  echo "Updating VuFind ${repo_ref} from ${repo_url}..."
  git -C "${target_dir}" remote set-url origin "${repo_url}"
  git -C "${target_dir}" fetch --tags origin

  if git -C "${target_dir}" show-ref --verify --quiet "refs/remotes/origin/${repo_ref}"; then
    target_ref="refs/remotes/origin/${repo_ref}"
    target_commit="$(git -C "${target_dir}" rev-parse "${target_ref}")"

    if git -C "${target_dir}" show-ref --verify --quiet "refs/heads/${repo_ref}"; then
      git -C "${target_dir}" checkout "${repo_ref}"
      ensure_clean_vufind_checkout
    fi

    if ! git -C "${target_dir}" merge-base --is-ancestor HEAD "${target_commit}"; then
      echo "Error: ${target_dir} has local commits that are not in origin/${repo_ref}." >&2
      echo "Resolve them before running update." >&2
      exit 1
    fi

    if ! git -C "${target_dir}" show-ref --verify --quiet "refs/heads/${repo_ref}"; then
      git -C "${target_dir}" checkout -B "${repo_ref}" "${target_ref}"
    fi

    git -C "${target_dir}" pull --ff-only origin "${repo_ref}"
  elif git -C "${target_dir}" show-ref --verify --quiet "refs/tags/${repo_ref}"; then
    target_ref="refs/tags/${repo_ref}"
    target_commit="$(git -C "${target_dir}" rev-list -n 1 "${target_ref}")"

    if ! git -C "${target_dir}" merge-base --is-ancestor HEAD "${target_commit}"; then
      echo "Error: ${target_dir} has local commits that are not in tag ${repo_ref}." >&2
      echo "Resolve them before running update." >&2
      exit 1
    fi

    git -C "${target_dir}" checkout --detach "${target_ref}"
  else
    echo "Error: VUFIND_REF '${repo_ref}' was not found in ${repo_url}." >&2
    exit 1
  fi
}

build_vufind_image() {
  local no_cache="${1:-false}"
  local args

  args=(build)
  if [ "${no_cache}" = true ]; then
    args+=(--no-cache)
  fi

  dc "${args[@]}" vufind-web
}

start_environment() {
  dc up -d vufind-db vufind-web
  echo "VuFind: ${VUFIND_SITE_URL}"
  echo "Solr:    ${SOLR_EXTERNAL_URL}"
}

recreate_environment() {
  dc up -d --force-recreate vufind-db vufind-web
  echo "VuFind: ${VUFIND_SITE_URL}"
  echo "Solr:    ${SOLR_EXTERNAL_URL}"
}

cmd="${1:-help}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "${cmd}" in
  help|-h|--help)
    usage
    ;;

  install)
    ensure_docker_installed
    require_external_solr
    update_vufind_checkout
    build_vufind_image false
    start_environment
    ;;

  update)
    ensure_docker_installed
    require_external_solr
    update_vufind_checkout
    build_vufind_image true
    recreate_environment
    ;;

  rebuild)
    ensure_docker_installed
    require_external_solr
    ensure_vufind_checkout
    build_vufind_image false
    recreate_environment
    ;;

  restart)
    ensure_docker_installed
    dc restart vufind-db vufind-web
    ;;

  start)
    ensure_docker_installed
    dc start vufind-db vufind-web
    ;;

  stop)
    ensure_docker_installed
    dc stop vufind-web vufind-db
    ;;

  logs)
    ensure_docker_installed
    if [ "$#" -eq 0 ]; then
      dc logs -f vufind-web vufind-db
    else
      dc logs "$@"
    fi
    ;;

  health)
    ensure_docker_installed
    require_external_solr
    dc ps
    echo
    curl -fsS -o /dev/null -w "VuFind: ${VUFIND_SITE_URL} -> %{http_code}\n" "${VUFIND_SITE_URL}/" || true
    curl -fsS -o /dev/null -w "Solr:    ${SOLR_EXTERNAL_URL} -> %{http_code}\n" "${SOLR_EXTERNAL_URL}/admin/info/system" || true
    ;;

  shell)
    ensure_docker_installed
    dc exec vufind-web bash
    ;;

  *)
    usage
    exit 1
    ;;
esac
