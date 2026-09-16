#!/usr/bin/env bash
set -euo pipefail

# gitlab_variables.sh — list CI/CD variables for a GitLab project
#
# Auth:
#   export GITLAB_ACCESS_TOKEN="glpat-xxxxx"
#
# Usage:
#   ./gitlab_variables.sh <repository-url>
#   ./gitlab_variables.sh https://gitlab.com/group/subgroup/project
#   ./gitlab_variables.sh git@gitlab.com:group/project.git
#
# Env (optional):
#   GITLAB_BASE_URL   override the host parsed from the repository URL

: "${GITLAB_ACCESS_TOKEN:?Set GITLAB_ACCESS_TOKEN (a GitLab personal access token) in your environment}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need_cmd curl

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then HAVE_JQ=1; fi

urlencode() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import urllib.parse,sys; sys.stdout.write(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
  elif command -v jq >/dev/null 2>&1; then
    jq -nr --arg v "$1" '$v|@uri'
  else
    echo "${1// /%20}"
  fi
}

parse_repo() {
  # Extract host, path, and base URL from HTTPS or SSH repository URL.
  local url="$1"
  local scheme="" authority="" path=""

  if [[ "$url" == *://* ]]; then
    scheme="${url%%://*}"
    local rest="${url#*://}"
    authority="${rest%%/*}"
    path="${rest#*/}"
  else
    authority="${url#*@}"
    path="${authority#*:}"
    authority="${authority%%:*}"
  fi

  REPO_PATH="${path%.git}"
  REPO_HOST="${authority%%:*}"
  if [[ -n "$scheme" ]]; then
    GITLAB_BASE_URL="${scheme}://${authority}"
  else
    GITLAB_BASE_URL="https://${authority}"
  fi
}

fetch_variables() {
  local enc; enc="$(urlencode "$REPO_PATH")"
  local uri prefix; prefix="${GITLAB_BASE_URL%/}/api/v4/projects/${enc}/variables"
  local page=1 chunk n
  local -a pages=()

  while :; do
    local code
    chunk="$(curl -sS -w '\n%{http_code}' \
      -H "PRIVATE-TOKEN: ${GITLAB_ACCESS_TOKEN}" \
      "${prefix}?per_page=100&page=${page}")"
    code="${chunk##*$'\n'}"
    chunk="${chunk%$'\n'*}"
    if [[ "$code" != "200" ]]; then
      echo "API error (HTTP $code): $chunk" >&2
      exit 1
    fi
    [[ -z "$chunk" || "$chunk" == "[]" ]] && break
    pages+=("$chunk")
    if [[ "$HAVE_JQ" -eq 1 ]]; then
      n="$(jq 'length' <<<"$chunk")"
      (( n < 100 )) && break
    else
      break
    fi
    page=$((page + 1))
  done

  if (( ${#pages[@]} == 0 )); then
    echo "No CI/CD variables found for $REPO_PATH" >&2
    exit 0
  fi

  if [[ "$HAVE_JQ" -eq 1 ]]; then
    jq -s 'add' <<<"${pages[*]}"
  else
    for c in "${pages[@]}"; do echo "$c"; done
  fi
}

main() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    echo "Usage: $0 <repository-url>" >&2
    echo "  e.g. $0 https://gitlab.com/group/subgroup/project" >&2
    exit 1
  fi

  parse_repo "$repo"
  : "${GITLAB_BASE_URL:?could not determine server from '$repo'}"

  echo "Project: $REPO_PATH ($GITLAB_BASE_URL)" >&2
  fetch_variables
}

main "$@"