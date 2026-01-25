# Keycloak REST API with curl

This guide shows how to use the Keycloak Admin REST API with curl commands.

## Authentication

First, you need to obtain an access token from Keycloak:

```bash
# Replace with your Keycloak server URL, realm, and admin credentials
KEYCLOAK_URL="http://localhost:8080"
REALM="master"
CLIENT_ID="admin-cli"
USERNAME="admin"
PASSWORD="admin"

# Get access token
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" | jq -r '.access_token')
```

## API Requests

Once you have the token, you can make requests to admin endpoints:

### List all realms
```bash
curl -s -X GET "$KEYCLOAK_URL/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Get users in a realm
```bash
curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Create a new user
```bash
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "enabled": true,
    "firstName": "New",
    "lastName": "User",
    "email": "newuser@example.com"
  }'
```

### Get clients in a realm
```bash
curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

## Common Endpoints

The base URL pattern is: `{server-url}/admin/realms/{realm}/{resource}`

- **Realms**: `/admin/realms`
- **Users**: `/admin/realms/{realm}/users`
- **Clients**: `/admin/realms/{realm}/clients`
- **Roles**: `/admin/realms/{realm}/roles`
- **Groups**: `/admin/realms/{realm}/groups`

## Notes

- Replace placeholder values with your actual Keycloak configuration
- The `admin-cli` client is used by default for admin operations
- Tokens expire and need to be refreshed periodically
- All admin requests require proper authentication with the Bearer token

## Script Usage
```
# Set authentication
export KEYCLOAK_URL="http://localhost:8080"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="admin"

# Or use a token directly
export KEYCLOAK_TOKEN="your-bearer-token"

# Make the script executable
chmod +x keycloak-api.sh

# Use it
./keycloak-api.sh user list
./keycloak-api.sh user create johndoe john@example.com John Doe
./keycloak-api.sh role create admin "Admin role"

```

## Reference
- https://www.keycloak.org/docs-api/latest/rest-api/index.html
- https://kc-api.github.io/quick-reference/
