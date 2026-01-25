#!/bin/bash

# Keycloak REST API Interaction Script

# Supports CRUD operations for common Keycloak resources

#

# Environment Variables:

# KEYCLOAK_URL - Base URL of Keycloak server (e.g., http://localhost:8080)

# KEYCLOAK_REALM - Target realm (default: master)

# KEYCLOAK_USER - Admin username (for password auth)

# KEYCLOAK_PASSWORD - Admin password (for password auth)

# KEYCLOAK_TOKEN - Bearer token (alternative to user/password)

# KEYCLOAK_CLIENT_ID - Client ID for token requests (default: admin-cli)

set -e

# Configuration

KEYCLOAK_URL=”${KEYCLOAK_URL:-http://localhost:8080}”
KEYCLOAK_REALM=”${KEYCLOAK_REALM:-master}”
KEYCLOAK_CLIENT_ID=”${KEYCLOAK_CLIENT_ID:-admin-cli}”
BASE_URL=”${KEYCLOAK_URL}/admin/realms”
AUTH_URL=”${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token”

# Helper Functions

error() {
printf ‘\033[0;31mError: %s\033[0m\n’ “$1” >&2
exit 1
}

success() {
printf ‘\033[0;32m%s\033[0m\n’ “$1”
}

warn() {
printf ‘\033[1;33m%s\033[0m\n’ “$1”
}

# Get access token

get_token() {
if [ -n “$KEYCLOAK_TOKEN” ]; then
echo “$KEYCLOAK_TOKEN”
return
fi

```
if [ -z "$KEYCLOAK_USER" ] || [ -z "$KEYCLOAK_PASSWORD" ]; then
    error "Either KEYCLOAK_TOKEN or both KEYCLOAK_USER and KEYCLOAK_PASSWORD must be set"
fi

local response
response=$(curl -s -X POST "$AUTH_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KEYCLOAK_USER" \
    -d "password=$KEYCLOAK_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=$KEYCLOAK_CLIENT_ID")

echo "$response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4
```

}

# Generic API call function

api_call() {
local method=”$1”
local endpoint=”$2”
local data=”$3”
local token

```
token=$(get_token)
if [ -z "$token" ]; then
    error "Failed to obtain access token"
fi

local args=()
args+=(-s)
args+=(-X "$method")
args+=(-H "Authorization: Bearer $token")
args+=(-H "Content-Type: application/json")

if [ -n "$data" ]; then
    args+=(-d "$data")
fi

local response
local http_code

response=$(curl -w "\n%{http_code}" "${args[@]}" "$endpoint")
http_code=$(echo "$response" | tail -n1)
local body=$(echo "$response" | sed '$d')

if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$body"
else
    error "API call failed with status $http_code: $body"
fi
```

}

# ============================================================================

# REALM OPERATIONS

# ============================================================================

realm_list() {
api_call GET “${KEYCLOAK_URL}/admin/realms”
}

realm_get() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call GET “${KEYCLOAK_URL}/admin/realms/${realm}”
}

realm_create() {
local realm_name=”$1”
local enabled=”${2:-true}”

```
[ -z "$realm_name" ] && error "Realm name required"

local data="{\"realm\":\"$realm_name\",\"enabled\":$enabled,\"displayName\":\"$realm_name\"}"
api_call POST "${KEYCLOAK_URL}/admin/realms" "$data"
success "Realm '$realm_name' created successfully"
```

}

realm_delete() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call DELETE “${KEYCLOAK_URL}/admin/realms/${realm}”
success “Realm ‘$realm’ deleted successfully”
}

# ============================================================================

# USER OPERATIONS

# ============================================================================

user_list() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call GET “${BASE_URL}/${realm}/users”
}

user_get() {
local user_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
api_call GET "${BASE_URL}/${realm}/users/${user_id}"
```

}

user_search() {
local username=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$username" ] && error "Username required"
api_call GET "${BASE_URL}/${realm}/users?username=${username}"
```

}

user_create() {
local username=”$1”
local email=”$2”
local firstname=”$3”
local lastname=”$4”
local realm=”${5:-$KEYCLOAK_REALM}”

```
[ -z "$username" ] && error "Username required"

local data="{\"username\":\"$username\",\"email\":\"$email\",\"firstName\":\"$firstname\",\"lastName\":\"$lastname\",\"enabled\":true,\"emailVerified\":false}"
api_call POST "${BASE_URL}/${realm}/users" "$data"
success "User '$username' created successfully"
```

}

user_update() {
local user_id=”$1”
local data=”$2”
local realm=”${3:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
[ -z "$data" ] && error "Update data required (JSON)"

api_call PUT "${BASE_URL}/${realm}/users/${user_id}" "$data"
success "User updated successfully"
```

}

user_delete() {
local user_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
api_call DELETE "${BASE_URL}/${realm}/users/${user_id}"
success "User deleted successfully"
```

}

user_reset_password() {
local user_id=”$1”
local password=”$2”
local temporary=”${3:-false}”
local realm=”${4:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
[ -z "$password" ] && error "Password required"

local data="{\"type\":\"password\",\"value\":\"$password\",\"temporary\":$temporary}"
api_call PUT "${BASE_URL}/${realm}/users/${user_id}/reset-password" "$data"
success "Password reset successfully"
```

}

# ============================================================================

# CLIENT OPERATIONS

# ============================================================================

client_list() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call GET “${BASE_URL}/${realm}/clients”
}

client_get() {
local client_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$client_id" ] && error "Client ID required"
api_call GET "${BASE_URL}/${realm}/clients/${client_id}"
```

}

client_create() {
local client_id=”$1”
local name=”$2”
local realm=”${3:-$KEYCLOAK_REALM}”

```
[ -z "$client_id" ] && error "Client ID required"

local data="{\"clientId\":\"$client_id\",\"name\":\"$name\",\"enabled\":true,\"publicClient\":false,\"standardFlowEnabled\":true,\"directAccessGrantsEnabled\":true}"
api_call POST "${BASE_URL}/${realm}/clients" "$data"
success "Client '$client_id' created successfully"
```

}

client_delete() {
local client_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$client_id" ] && error "Client ID required"
api_call DELETE "${BASE_URL}/${realm}/clients/${client_id}"
success "Client deleted successfully"
```

}

client_secret() {
local client_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$client_id" ] && error "Client ID required"
api_call GET "${BASE_URL}/${realm}/clients/${client_id}/client-secret"
```

}

# ============================================================================

# ROLE OPERATIONS

# ============================================================================

role_list() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call GET “${BASE_URL}/${realm}/roles”
}

role_get() {
local role_name=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$role_name" ] && error "Role name required"
api_call GET "${BASE_URL}/${realm}/roles/${role_name}"
```

}

role_create() {
local role_name=”$1”
local description=”$2”
local realm=”${3:-$KEYCLOAK_REALM}”

```
[ -z "$role_name" ] && error "Role name required"

local data="{\"name\":\"$role_name\",\"description\":\"$description\"}"
api_call POST "${BASE_URL}/${realm}/roles" "$data"
success "Role '$role_name' created successfully"
```

}

role_delete() {
local role_name=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$role_name" ] && error "Role name required"
api_call DELETE "${BASE_URL}/${realm}/roles/${role_name}"
success "Role deleted successfully"
```

}

user_add_role() {
local user_id=”$1”
local role_name=”$2”
local realm=”${3:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
[ -z "$role_name" ] && error "Role name required"

# First get the role details
local role_data
role_data=$(role_get "$role_name" "$realm")

api_call POST "${BASE_URL}/${realm}/users/${user_id}/role-mappings/realm" "[$role_data]"
success "Role '$role_name' added to user"
```

}

# ============================================================================

# GROUP OPERATIONS

# ============================================================================

group_list() {
local realm=”${1:-$KEYCLOAK_REALM}”
api_call GET “${BASE_URL}/${realm}/groups”
}

group_get() {
local group_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$group_id" ] && error "Group ID required"
api_call GET "${BASE_URL}/${realm}/groups/${group_id}"
```

}

group_create() {
local group_name=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$group_name" ] && error "Group name required"

local data="{\"name\":\"$group_name\"}"
api_call POST "${BASE_URL}/${realm}/groups" "$data"
success "Group '$group_name' created successfully"
```

}

group_delete() {
local group_id=”$1”
local realm=”${2:-$KEYCLOAK_REALM}”

```
[ -z "$group_id" ] && error "Group ID required"
api_call DELETE "${BASE_URL}/${realm}/groups/${group_id}"
success "Group deleted successfully"
```

}

user_join_group() {
local user_id=”$1”
local group_id=”$2”
local realm=”${3:-$KEYCLOAK_REALM}”

```
[ -z "$user_id" ] && error "User ID required"
[ -z "$group_id" ] && error "Group ID required"

api_call PUT "${BASE_URL}/${realm}/users/${user_id}/groups/${group_id}"
success "User added to group"
```

}

# ============================================================================

# MAIN COMMAND DISPATCHER

# ============================================================================

show_usage() {
cat <<‘EOF’
Keycloak REST API Script

Usage: $0 <resource> <operation> [arguments…]

Resources and Operations:

realm list
realm get [realm_name]
realm create <realm_name> [enabled]
realm delete [realm_name]

user list [realm]
user get <user_id> [realm]
user search <username> [realm]
user create <username> <email> <firstname> <lastname> [realm]
user update <user_id> <json_data> [realm]
user delete <user_id> [realm]
user reset-password <user_id> <password> [temporary] [realm]
user add-role <user_id> <role_name> [realm]
user join-group <user_id> <group_id> [realm]

client list [realm]
client get <client_id> [realm]
client create <client_id> <name> [realm]
client delete <client_id> [realm]
client secret <client_id> [realm]

role list [realm]
role get <role_name> [realm]
role create <role_name> <description> [realm]
role delete <role_name> [realm]

group list [realm]
group get <group_id> [realm]
group create <group_name> [realm]
group delete <group_id> [realm]

Environment Variables:
KEYCLOAK_URL      - Base URL (default: http://localhost:8080)
KEYCLOAK_REALM    - Target realm (default: master)
KEYCLOAK_USER     - Admin username
KEYCLOAK_PASSWORD - Admin password
KEYCLOAK_TOKEN    - Bearer token (alternative to user/password)
KEYCLOAK_CLIENT_ID - Client ID (default: admin-cli)

Examples:
$0 user list
$0 user create john.doe john@example.com John Doe
$0 role create admin “Administrator role”
$0 client list myrealm
EOF
}

# Main command dispatcher

main() {
if [ $# -lt 2 ]; then
show_usage
exit 1
fi

```
local resource="$1"
local operation="$2"
shift 2

local cmd="${resource}_${operation//-/_}"

if declare -f "$cmd" > /dev/null; then
    $cmd "$@"
else
    error "Unknown command: $resource $operation"
fi
```

}

main “$@”
