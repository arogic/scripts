# GitLab Shell Scripts

## Prerequisites

- `curl` (required)
- `jq` (optional, pretty-prints JSON output)
- A GitLab personal access token with `api` scope

## Authentication

Both scripts use the `PRIVATE-TOKEN` header to authenticate. Create a token at:

- **gitlab.com**: https://gitlab.com/-/user_settings/personal_access_tokens
- **Self-managed**: `https://<host>/-/user_settings/personal_access_tokens`

Export the token in your shell:

```sh
export GITLAB_ACCESS_TOKEN="glpat-..."
```

Add it to `~/.zshrc` or `~/.bashrc` to persist across sessions.

## Scripts

### gitlab.sh

Look up GitLab groups, users, or projects by ID or search term.

```sh
./gitlab.sh group <id|name>
./gitlab.sh user  <id|username|email|name>
./gitlab.sh project <id|full_path|name>
```

Examples:

```sh
./gitlab.sh group 12345
./gitlab.sh group "Platform Team"
./gitlab.sh user 42
./gitlab.sh user "jane@company.com"
./gitlab.sh project 98765
./gitlab.sh project "mygroup/myrepo"
```

Uses `GITLAB_BASE_URL` (default: `https://gitlab.com`).

### gitlab_variables.sh

List CI/CD variables for a project. Pass a full repository URL (HTTPS or SSH).

```sh
./gitlab_variables.sh <repository-url>
```

Examples:

```sh
./gitlab_variables.sh https://gitlab.com/group/subgroup/project
./gitlab_variables.sh git@gitlab.com:group/project.git
```

Variables are paginated automatically (100 per page) and merged into a single JSON array.
