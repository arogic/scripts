#!/usr/bin/env bash
set -euo pipefail

# gitlab_lookup.sh — lookup groups, users, projects by ID or search term
#
# Auth:
#   export GITLAB_TOKEN="glpat-xxxxx"
#   export GITLAB_BASE_URL="https://gitlab.com"   # or https://gitlab.example.com
#
# Examples:
#   ./gitlab_lookup.sh group 12345
#   ./gitlab_lookup.sh group "Platform Team"
#   ./gitlab_lookup.sh user 42
#   ./gitlab_lookup.sh user "jane.doe"
#   ./gitlab_lookup.sh user "jane@company.com"
#   ./gitlab_lookup.sh project 98765
#   ./gitlab_lookup.sh project "mygroup/myrepo"
#   ./gitlab_lookup.sh project "My Repo Name"

GITLAB_BASE_URL="${GITLAB_BASE_URL:-https://gitlab.com}"
API_BASE="${GITLAB_BASE_URL%/}/api/v4"

: "${GITLAB_TOKEN:?Set GITLAB_TOKEN (a GitLab personal access token) in your environment}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need_cmd curl

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then HAVE_JQ=1; fi

urlencode() {
  # Prefer python3 if present, else fallback to jq, else naive
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1]))
PY
  elif command -v jq >/dev/null 2>&1; then
    jq -nr --arg v "$1" '$v|@uri'
  else
    # naive: spaces only
    echo "${1// /%20}"
  fi
}

print_json() {
  if [[ "$HAVE_JQ" -eq 1 ]]; then jq .; else cat; fi
}

api() {
  local method="$1"; shift
  local path="$1"; shift
  curl -sS \
    -X "$method" \
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    -H "Content-Type: application/json" \
    "${API_BASE}${path}" \
    "$@"
}

is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

usage() {
  cat <<'EOF'
Usage:
  gitlab_lookup.sh group <id|name>
  gitlab_lookup.sh user <id|username|email|name>
  gitlab_lookup.sh project <id|full_path|name>

Notes:
- If you pass an integer, it fetches by ID.
- Otherwise it searches and returns a list of matches.
- For project, you can also pass "group/subgroup/repo" to fetch directly.

Env:
  GITLAB_TOKEN (required)
  GITLAB_BASE_URL (optional) default: https://gitlab.com

Examples:
  ./gitlab_lookup.sh group 12345
  ./gitlab_lookup.sh group "Platform Team"

  ./gitlab_lookup.sh user 42
  ./gitlab_lookup.sh user "jane.doe"
  ./gitlab_lookup.sh user "jane@company.com"

  ./gitlab_lookup.sh project 999
  ./gitlab_lookup.sh project "mygroup/myrepo"
  ./gitlab_lookup.sh project "Repo Name"
EOF
}

# ---------- GROUPS ----------
get_group_by_id() {
  local id="$1"
  api GET "/groups/${id}" | print_json
}

search_groups() {
  local q="$1"
  local enc; enc="$(urlencode "$q")"
  # all_available=true lets admins search beyond membership; harmless if not admin
  api GET "/groups?search=${enc}&per_page=50&all_available=true" | print_json
}

cmd_group() {
  local input="${1:?group id or name required}"
  if is_int "$input"; then
    get_group_by_id "$input"
  else
    search_groups "$input"
  fi
}

# ---------- USERS ----------
get_user_by_id() {
  local id="$1"
  api GET "/users/${id}" | print_json
}

search_users() {
  local q="$1"
  local enc; enc="$(urlencode "$q")"
  # /users?search= matches name/username; email search may require admin privileges
  api GET "/users?search=${enc}&per_page=50" | print_json
}

cmd_user() {
  local input="${1:?user id or search term required}"
  if is_int "$input"; then
    get_user_by_id "$input"
  else
    search_users "$input"
  fi
}

# ---------- PROJECTS ----------
get_project_by_id() {
  local id="$1"
  api GET "/projects/${id}" | print_json
}

get_project_by_path() {
  # GitLab expects URL-encoded full path: group%2Fsubgroup%2Frepo
  local full_path="$1"
  local enc; enc="$(urlencode "$full_path")"
  api GET "/projects/${enc}" | print_json
}

search_projects() {
  local q="$1"
  local enc; enc="$(urlencode "$q")"
  # membership=true narrows to what you can see; remove if you want broader search
  api GET "/projects?search=${enc}&per_page=50&simple=false" | print_json
}

cmd_project() {
  local input="${1:?project id, path, or name required}"
  if is_int "$input"; then
    get_project_by_id "$input"
  elif [[ "$input" == */* ]]; then
    # Treat as fu
