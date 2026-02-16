# MARVIN Integration Guide: Linear

## Goal

Add a Linear integration to the MARVIN template so that MARVIN can interact with Linear (project management — issues, projects, cycles, teams) via Linear's MCP server.

---

## Before You Start

1. **Read the required integration patterns:**
   - `.marvin/integrations/CLAUDE.md` — setup script and README requirements (6 setup.sh rules, 9 README sections, Danger Zone format)
   - `.marvin/integrations/README.md` — full documentation, contribution guidelines, and the integrations table to update
   - `.marvin/integrations/atlassian/` — closest reference implementation (remote MCP server, browser-based auth)

2. **Match the existing structure exactly.** Linear follows the same pattern as Atlassian: a remote MCP server with no local package installation required.

---

## MCP Server Details

Linear provides an **official remote MCP server** — no local `npx` package needed.

| Property | Value |
|----------|-------|
| **SSE endpoint** | `https://mcp.linear.app/sse` |
| **Streamable HTTP endpoint (preferred)** | `https://mcp.linear.app/mcp` |
| **Auth (Option A)** | OAuth 2.1 with dynamic client registration — interactive browser flow |
| **Auth (Option B)** | Linear API key via `Authorization: Bearer <token>` header |
| **Official docs** | https://linear.app/docs/mcp |

### Why two auth options?

- **OAuth (Option A)** is simplest for personal use — no token to manage, scopes handled automatically, browser popup authenticates in seconds. This is the same pattern Atlassian uses.
- **API key (Option B)** is better for headless/scripted setups or when you want explicit control over what the key can access. It also avoids the occasional flakiness of OAuth browser flows in terminal environments.

### How to generate a Linear API key

1. Open Linear → **Settings** → **Account** → **Security & Access** → **API Keys**
2. Click **Create Key**
3. Give it a descriptive name (e.g., `MARVIN`)
4. Copy the key — it starts with `lin_api_`
5. Store it in `.env` as `LINEAR_API_KEY`

### Available MCP Tools (provided by Linear's server)

Linear's MCP server exposes these tool categories (Linear is actively adding more):

| Tool | What It Does |
|------|--------------|
| Search issues | Find issues by text, filter, assignee, project, team |
| Get issue details | Retrieve full issue data (title, description, status, priority, labels, comments) |
| Create issues | Create new issues with title, description, assignee, priority, labels, project, team |
| Update issues | Change status, priority, assignee, labels, estimates, etc. |
| Add comments | Post comments on existing issues |
| Search projects | Find projects by name or team |
| List teams | Retrieve available teams and their identifiers |

---

## Target Capabilities for MARVIN

Once connected, MARVIN should be able to:

- **Create and assign tickets** — with team, project, priority, labels, and description pulled from conversation context
- **Update issue status** — move issues through workflow states (e.g., "mark LIN-42 as done")
- **Add context via comments** — post notes, decisions, or follow-ups directly to issues
- **Search and query issues** — find issues assigned to the user, filter by status/priority/project
- **Pull issue details into briefings** — during `/start`, surface open issues, blockers, or items nearing deadline
- **Work alongside Linear's Slack integration** — MARVIN creates/updates in Linear; Linear's own Slack app handles notifications automatically. No extra wiring needed.

---

## Files to Create

Following the pattern from `.marvin/integrations/CLAUDE.md`:

```
.marvin/integrations/linear/
├── README.md       # User-facing docs (9 required sections)
└── setup.sh        # Interactive setup script (6 required patterns)
```

---

## README.md (complete, ready to use)

The following content fulfills all 9 required sections from `.marvin/integrations/CLAUDE.md`:

```markdown
# Linear Integration

Connect MARVIN to Linear for issue tracking and project management.

## What It Does

- **Search issues** — Find issues by keyword, assignee, status, project, or team
- **Create issues** — File new issues with title, description, priority, labels, and assignee
- **Update issues** — Change status, priority, assignee, and other fields
- **Comment on issues** — Add notes and context to existing issues
- **Browse projects and teams** — List projects, cycles, and team structures

## Who It's For

Anyone who uses Linear for project management and wants MARVIN to create, search, and update issues as part of their daily workflow.

## Prerequisites

- A Linear account with access to the workspace you want to connect
- **Option A (OAuth):** Nothing else — the browser flow handles auth
- **Option B (API key):** A Linear API key (the setup script will guide you)

## Setup

```bash
./.marvin/integrations/linear/setup.sh
```

The script will:
1. Ask whether you want OAuth (browser flow) or API key auth
2. If API key: prompt for your key, validate the format, and save it
3. Register the Linear MCP server with Claude Code
4. Walk you through authentication if using OAuth

## Try It

After setup, try these commands with MARVIN:

- "Show me my open Linear issues"
- "Create a Linear issue: Update the onboarding flow — priority high, assign to me"
- "What's the status of ENG-47?"
- "Add a comment to ENG-47: Decided to use the new API endpoint instead"
- "Search Linear for issues about authentication"
- "What issues are in the current cycle?"

## Danger Zone

This integration can perform actions that affect your team:

| Action | Risk Level | Who's Affected |
|--------|------------|----------------|
| Create issues | **Medium** | Team sees new issues, may get notifications |
| Update issues (status, assignee, priority) | **Medium** | Team sees changes, workflow automations may trigger |
| Add comments | **Medium** | Mentioned users and subscribers get notified |
| Search and read issues | Low | No external impact |

MARVIN will always confirm before creating, updating, or commenting on issues.

## Troubleshooting

**"Unauthorized" or "Authentication failed"**
- **OAuth:** Re-authenticate by running `claude mcp` → select `linear` → choose "Authenticate" → complete the browser flow
- **API key:** Verify the key is correct in `.env` and hasn't been revoked. Generate a new one at Linear → Settings → Account → Security & Access → API Keys.

**Can't find issues or projects**
- Make sure you're authenticated to the correct Linear workspace
- Check that your account has access to the team/project you're querying

**OAuth browser flow doesn't open**
- Try the API key option instead — run the setup script again and choose Option B
- If using a remote/headless environment, the API key approach is more reliable

**"MCP server not found" after setup**
- Restart Claude Code after running the setup script
- Run `claude mcp list` to verify `linear` appears in the server list

---

*Contributed by Conor Bronsdon*
```

---

## setup.sh (complete, ready to use)

The following script fulfills all 6 required patterns from `.marvin/integrations/CLAUDE.md`:

1. Standard header with colors
2. Claude Code check
3. Scope selection (REQUIRED)
4. Remove before add
5. Blue banners for sections
6. End with success message

```bash
#!/bin/bash
# Linear MCP Setup Script
# Connect MARVIN to Linear for issue tracking and project management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Linear MCP Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Claude Code
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installed${NC}"
else
    echo -e "${RED}✗ Claude Code not found${NC}"
    echo "Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Scope selection
echo ""
echo "Where should this integration be available?"
echo "  1) All projects (user-scoped)"
echo "  2) This project only (project-scoped)"
echo ""
echo -e "${YELLOW}Choice [1]:${NC}"
read -r SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

if [[ "$SCOPE_CHOICE" == "1" ]]; then
    SCOPE_FLAG="-s user"
else
    SCOPE_FLAG=""
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Authentication Method${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "How would you like to authenticate with Linear?"
echo ""
echo "  1) OAuth — browser login, no key needed (recommended)"
echo "  2) API key — paste a personal API key"
echo ""
echo -e "${YELLOW}Choice [1]:${NC}"
read -r AUTH_CHOICE
AUTH_CHOICE=${AUTH_CHOICE:-1}

# Remove existing if present
claude mcp remove linear 2>/dev/null || true

if [[ "$AUTH_CHOICE" == "2" ]]; then
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  API Key Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "To create an API key:"
    echo "  1. Open Linear → Settings → Account → Security & Access → API Keys"
    echo "  2. Click 'Create Key'"
    echo "  3. Copy the key (starts with lin_api_)"
    echo ""
    echo -e "${YELLOW}Paste your Linear API key:${NC}"
    read -rs LINEAR_API_KEY
    echo ""

    # Validate key format
    if [[ ! "$LINEAR_API_KEY" =~ ^lin_api_ ]]; then
        echo -e "${RED}✗ Key should start with 'lin_api_'${NC}"
        echo "Make sure you're copying the full API key from Linear."
        exit 1
    fi

    echo -e "${GREEN}✓ Key format looks good${NC}"

    # Save to .env
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ENV_FILE="$(cd "$SCRIPT_DIR/../../.." && pwd)/.env"

    if [[ -f "$ENV_FILE" ]]; then
        # Update existing .env
        if grep -q "^LINEAR_API_KEY=" "$ENV_FILE"; then
            sed -i.bak "s|^LINEAR_API_KEY=.*|LINEAR_API_KEY=$LINEAR_API_KEY|" "$ENV_FILE"
            rm -f "$ENV_FILE.bak"
        else
            echo "LINEAR_API_KEY=$LINEAR_API_KEY" >> "$ENV_FILE"
        fi
    else
        echo "LINEAR_API_KEY=$LINEAR_API_KEY" > "$ENV_FILE"
    fi
    echo -e "${GREEN}✓ API key saved to .env${NC}"

    echo ""
    echo -e "${BLUE}Adding Linear MCP to Claude Code (API key auth)...${NC}"

    # Add with API key header using streamable HTTP transport
    claude mcp add linear $SCOPE_FLAG \
        --transport http \
        --header "Authorization: Bearer ${LINEAR_API_KEY}" \
        https://mcp.linear.app/mcp

    echo -e "${GREEN}✓ Linear MCP added with API key auth${NC}"
else
    echo ""
    echo -e "${BLUE}Adding Linear MCP to Claude Code (OAuth)...${NC}"

    # Add with SSE transport for OAuth flow
    claude mcp add linear $SCOPE_FLAG \
        --transport sse \
        https://mcp.linear.app/sse

    echo -e "${GREEN}✓ Linear MCP added${NC}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Authentication${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Now you need to authenticate with Linear."
    echo ""
    echo -e "${YELLOW}Run this command:${NC}"
    echo ""
    echo "    claude mcp"
    echo ""
    echo "Then:"
    echo "  1. Find 'linear' in the list and select it"
    echo "  2. Choose 'Authenticate'"
    echo "  3. Complete the login in your browser"
    echo ""
    read -p "Press Enter once you've authenticated (or 's' to skip)... " AUTH_RESPONSE

    if [[ "$AUTH_RESPONSE" == "s" || "$AUTH_RESPONSE" == "S" ]]; then
        echo ""
        echo -e "${YELLOW}Skipped authentication.${NC}"
        echo "Remember to run 'claude mcp' and authenticate before using Linear."
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Try these commands with MARVIN:"
echo -e "  ${YELLOW}\"Show me my open Linear issues\"${NC}"
echo -e "  ${YELLOW}\"Create a Linear issue: Fix login bug — priority high\"${NC}"
echo -e "  ${YELLOW}\"What's the status of ENG-47?\"${NC}"
echo ""
echo -e "${GREEN}You're all set!${NC}"
echo ""
```

---

## Environment Variables

| Variable | Required? | Value | Where to get it |
|----------|-----------|-------|-----------------|
| `LINEAR_API_KEY` | Only if using API key auth | `lin_api_xxxxxxxxxxxx` | Linear → Settings → Account → Security & Access → API Keys |

Already present in `.env.example` — no changes needed there.

---

## Files to Update in the Repo

### 1. `.marvin/integrations/README.md` — Add to the integrations table

Add this row to the "Available Integrations" table:

```markdown
| [Linear](./linear/) | Issues, projects, cycles | `./.marvin/integrations/linear/setup.sh` |
```

Also remove `Linear` from the "Integration Ideas" list at the bottom (it's no longer just an idea).

### 2. Root `README.md` — Add to the integrations table

Add this row:

```markdown
| [Linear](.marvin/integrations/linear/) | Issues, projects, cycles | `/help` then follow prompts |
```

### 3. Root `CLAUDE.md` — Update the integrations table

Add this row to the integrations table in the "Integrations" section:

```markdown
| Linear | Issues, projects, cycles |
```

Also verify that the "Safety Guidelines" table already covers Linear actions. The existing row for "Modifying tickets/issues" with "Jira, Linear, GitHub" already includes Linear — no change needed.

---

## Implementation Notes

- **Linear is the simpler integration.** It uses a remote MCP server (like Atlassian), so there's no local package to install, no Node.js dependency for the server itself, and no `npx` command. Start here before tackling Notion.
- **OAuth uses SSE transport; API key uses HTTP transport.** The SSE endpoint (`/sse`) supports the OAuth browser flow. The HTTP endpoint (`/mcp`) is for direct API key auth via headers. The setup script handles this branching.
- **No `mcp-remote` needed.** Unlike some MCP servers that require `npx @anthropic-ai/mcp-remote` as a bridge, Linear's SSE endpoint works directly with `claude mcp add --transport sse`.
- **Linear's Slack integration is separate.** When MARVIN creates or updates issues in Linear, Linear's own Slack app sends notifications. No extra configuration needed on MARVIN's side.
- **The setup script follows the Atlassian pattern closely** — the OAuth path mirrors Atlassian's browser auth flow, and the API key path adds the Slack-style token prompt on top.

---

## Testing Checklist

After implementation, verify these operations work:

- [ ] Search issues — `"Show my open Linear issues"`
- [ ] Create an issue — `"Create a bug: Login page crashes on mobile"`
- [ ] Update an issue — `"Mark ENG-47 as done"`
- [ ] Add a comment — `"Comment on ENG-47: Deployed the fix to staging"`
- [ ] Read issue details — `"What's the description of ENG-47?"`
- [ ] MARVIN confirms before create/update/comment actions (Danger Zone compliance)

---

## Conformance Checklist (from `.marvin/integrations/CLAUDE.md`)

- [x] `setup.sh` includes scope selection prompt
- [x] `setup.sh` uses correct color codes and banner format
- [x] `setup.sh` removes existing MCP before adding
- [x] `README.md` has all 9 required sections (Title, What It Does, Who It's For, Prerequisites, Setup, Try It, Danger Zone, Troubleshooting, Attribution)
- [ ] Added integration to the table in `.marvin/integrations/README.md`
- [ ] Tested on a fresh install
