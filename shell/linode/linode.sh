#!/bin/sh
set -eu

API="https://api.linode.com/v4"

# Defaults
REGION="eu-central"      # Frankfurt
TYPE="g6-nanode-1"       # smallest
IMAGE="linode/ubuntu22.04"

TOKEN="${LINODE_TOKEN:?LINODE_TOKEN is not set}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/linode"
mkdir -p "$STATE_DIR"

SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: missing required command: $1" >&2
    exit 1
  }
}

rand_pass() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 32 | tr -d '\n'
  else
    dd if=/dev/urandom bs=48 count=1 2>/dev/null | base64 | tr -d '\n'
  fi
}

api() {
  method="$1"
  path="$2"
  data="${3:-}"

  if [ "$method" = "GET" ]; then
    curl -sS "$API$path" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json"
  elif [ "$method" = "POST" ]; then
    curl -sS -X POST "$API$path" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  elif [ "$method" = "DELETE" ]; then
    curl -sS -X DELETE "$API$path" \
      -H "Authorization: Bearer $TOKEN"
  fi
}

usage() {
  cat <<EOF
Usage:
  $0 list
  $0 create <linode-label>
  $0 delete <linode-label>

Env:
  LINODE_TOKEN   (required)
  SSH_KEY_FILE   (optional, default: ~/.ssh/id_ed25519.pub)

Defaults:
  Region: $REGION
  Type:   $TYPE
  Image:  $IMAGE
EOF
  exit 2
}

list_linodes() {
  need_cmd jq
  need_cmd curl

  api GET "/linode/instances?page_size=500" \
  | jq -r '
    .data
    | sort_by(.label)
    | (["ID","LABEL","REGION","TYPE","STATUS","IPV4"] | @tsv),
      (.[] | [
        (.id|tostring),
        .label,
        .region,
        .type,
        .status,
        (.ipv4[0] // "-")
      ] | @tsv)
  ' | column -t
}

create_linode() {
  label="$1"

  need_cmd jq
  need_cmd curl

  [ -f "$SSH_KEY_FILE" ] || {
    echo "Error: SSH public key not found: $SSH_KEY_FILE" >&2
    exit 1
  }

  ssh_key="$(cat "$SSH_KEY_FILE")"
  root_pass="$(rand_pass)"

  resp="$(api POST "/linode/instances" "{
    \"label\": \"${label}\",
    \"region\": \"${REGION}\",
    \"type\": \"${TYPE}\",
    \"image\": \"${IMAGE}\",
    \"root_pass\": \"${root_pass}\",
    \"authorized_keys\": [\"${ssh_key}\"]
  }")"

  if echo "$resp" | jq -e '.errors? // empty' >/dev/null 2>&1; then
    echo "$resp" | jq
    exit 1
  fi

  id="$(echo "$resp" | jq -r '.id')"
  ip="$(echo "$resp" | jq -r '.ipv4[0] // empty')"

  echo "$id" > "$STATE_DIR/${label}.id"

  echo "Created Linode:"
  echo "  label: $label"
  echo "  id:    $id"
  [ -n "$ip" ] && echo "  ipv4:  $ip"
  echo
  echo "SSH:"
  [ -n "$ip" ] && echo "  ssh root@${ip}" || echo "  (IP not assigned yet)"
}

resolve_id_by_label() {
  label="$1"

  if [ -f "$STATE_DIR/${label}.id" ]; then
    cat "$STATE_DIR/${label}.id"
    return 0
  fi

  resp="$(curl -sS "$API/linode/instances" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Filter: {\"label\":\"$label\"}")"

  count="$(echo "$resp" | jq -r '.data | length')"

  if [ "$count" -eq 0 ]; then
    echo ""
    return 0
  fi
  if [ "$count" -gt 1 ]; then
    echo "Error: multiple Linodes found with label '$label'" >&2
    echo "$resp" | jq -r '.data[] | "  id=\(.id) region=\(.region) status=\(.status)"' >&2
    exit 1
  fi

  echo "$resp" | jq -r '.data[0].id'
}

delete_linode() {
  label="$1"

  need_cmd jq
  need_cmd curl

  id="$(resolve_id_by_label "$label")"
  [ -n "$id" ] || {
    echo "No Linode found with label '$label'" >&2
    exit 1
  }

  api DELETE "/linode/instances/$id" >/dev/null
  rm -f "$STATE_DIR/${label}.id"

  echo "Deleted Linode:"
  echo "  label: $label"
  echo "  id:    $id"
}

cmd="${1:-}"
label="${2:-}"

case "$cmd" in
  list)   list_linodes ;;
  create) [ -n "$label" ] || usage; create_linode "$label" ;;
  delete) [ -n "$label" ] || usage; delete_linode "$label" ;;
  *) usage ;;
esac
