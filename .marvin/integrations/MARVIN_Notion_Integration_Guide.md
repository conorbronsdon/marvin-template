# MARVIN Integration Guide: Notion

## Goal

Add a Notion integration to the MARVIN template so that MARVIN can interact with Notion (pages, databases, notes, knowledge base) via Notion's MCP server.

---

## Before You Start

1. **Read the required integration patterns:**
   - `.marvin/integrations/CLAUDE.md` — setup script and README requirements (6 setup.sh rules, 9 README sections, Danger Zone format)
   - `.marvin/integrations/README.md` — full documentation, contribution guidelines, and the integrations table to update
   - `.marvin/integrations/atlassian/` — reference for remote MCP pattern
   - `.marvin/integrations/slack/` — reference for local `npx`-based MCP with token auth (closest to Notion's recommended setup)

2. **Match the existing structure exactly.** Notion follows the Slack pattern most closely: a local MCP server run via `npx` with an API token passed as an environment variable.

---

## MCP Server Details

Notion provides **two official MCP server options:**

### Option A — Official hosted remote MCP server (OAuth)

| Property | Value |
|----------|-------|
| **Endpoint** | `https://mcp.notion.com/mcp` |
| **Transport** | HTTP (streamable) |
| **Auth** | OAuth 2.1 — interactive browser flow |
| **Docs** | https://developers.notion.com/guides/mcp/get-started-with-mcp |

**Known issue:** Some users report the OAuth flow with Claude Code can be flaky and may require multiple attempts. If it doesn't work on first try, the local server option is more reliable.

### Option B — Official open-source local MCP server (recommended)

| Property | Value |
|----------|-------|
| **Package** | `@notionhq/notion-mcp-server` |
| **Transport** | stdio (via `npx`) |
| **Auth** | Internal integration token |
| **GitHub** | https://github.com/makenotion/notion-mcp-server |
| **Current version** | 2.0.0 (Notion API 2025-09-03, data sources as primary abstraction) |

**Why this is recommended:** More reliable than OAuth, gives you explicit control over which pages the integration can access, works in headless/remote environments, and doesn't depend on Notion's hosted MCP server availability.

### Why recommend the local server over OAuth?

1. **Reliability** — the local server runs via `npx` and connects directly to Notion's API. No intermediary OAuth server to be flaky.
2. **Explicit scope control** — with an internal integration token, you choose exactly which pages and databases to share. OAuth grants broader access.
3. **Headless-friendly** — API token works in any environment; OAuth needs a browser.
4. **Simpler debugging** — if something breaks, the error is between `npx` and the Notion API, not a three-party OAuth dance.

### How to create a Notion integration token

1. Go to https://www.notion.so/profile/integrations
2. Click **"New integration"**
3. Name it (e.g., `MARVIN`)
4. Select the workspace it should access
5. Under **Capabilities**, ensure "Read content", "Update content", and "Insert content" are enabled
6. Click **Submit** and copy the integration token (starts with `ntn_`)
7. **Critical step — share pages with the integration:**
   - Go to each Notion page or database you want MARVIN to access
   - Click the `...` menu → **Connections** → add your `MARVIN` integration
   - The integration can **only** see pages you explicitly share with it
   - Sharing a parent page shares all child pages beneath it

This page-sharing step is the **#1 source of "why can't MARVIN find my pages?"** issues. The setup script reminds users about it.

### Available MCP Tools (v2.0.0)

| Tool | What It Does |
|------|--------------|
| Search pages | Find pages and databases by text query |
| Retrieve page | Get full page content (blocks, properties, metadata) |
| Create page | Create new pages in a database or as children of another page |
| Update page | Modify page properties (title, status, tags, etc.) |
| Append blocks | Add content blocks (text, headings, lists, code, etc.) to existing pages |
| Query database | Filter and sort database entries with Notion's query syntax |
| Retrieve database | Get database schema, properties, and metadata |
| Create/read comments | Post and read comments on pages |
| Manage data source items | CRUD operations on data source entries (v2.0.0 abstraction) |

---

## Target Capabilities for MARVIN

Once connected, MARVIN should be able to:

- **Pull notes into context** — query a notes database, retrieve content, and use it in conversations and briefings
- **Update docs** — edit strategy docs, append meeting notes, update page properties
- **Search across Notion** — find relevant pages to pull context into conversations (e.g., "what did I write about the Q1 roadmap?")
- **Query databases with filters** — "show me all notes from this week tagged with 'modular'" or "what items in my project tracker are marked 'In Progress'?"
- **Create pages** — draft new docs, meeting notes, or knowledge base entries from conversation context
- **Add comments** — leave notes on pages for follow-up

---

## Files to Create

Following the pattern from `.marvin/integrations/CLAUDE.md`:

```
.marvin/integrations/notion/
├── README.md       # User-facing docs (9 required sections)
└── setup.sh        # Interactive setup script (6 required patterns)
```

---

## README.md (complete, ready to use)

The following content fulfills all 9 required sections from `.marvin/integrations/CLAUDE.md`:

```markdown
# Notion Integration

Connect MARVIN to your Notion workspace for pages, databases, and notes.

## What It Does

- **Search** — Find pages and databases across your connected workspace
- **Read** — View full page content, database entries, and properties
- **Create** — Make new pages and database entries
- **Update** — Edit page properties, append content blocks, modify entries
- **Query databases** — Filter and sort database entries (e.g., by date, tag, status)
- **Comment** — Add and read comments on pages

## Who It's For

Anyone who uses Notion for notes, documentation, wikis, project tracking, or as a knowledge base and wants MARVIN to read, search, and update their Notion workspace.

## Prerequisites

- A Notion account
- **Option A (recommended — API token):** A Notion internal integration token and Node.js installed (for `npx`)
- **Option B (OAuth):** Nothing else — the browser flow handles auth

## Setup

```bash
./.marvin/integrations/notion/setup.sh
```

The script will:
1. Check that Node.js is available (needed for the local MCP server)
2. Ask whether you want API token auth (recommended) or OAuth
3. If API token: prompt for the token, validate the format, and save it
4. Register the Notion MCP server with Claude Code
5. Remind you to share Notion pages with the integration

**Important:** After setup, you must share specific Notion pages/databases with your integration. The integration can only access pages you explicitly connect it to. See "Sharing Pages" below.

## Sharing Pages with the Integration

This is the most common setup mistake — the integration token is valid, but MARVIN can't find any pages because none have been shared.

**To share a page or database:**
1. Open the page in Notion
2. Click the `...` menu in the top-right corner
3. Click **Connections**
4. Search for and add your integration (e.g., `MARVIN`)

**Tips:**
- Sharing a parent page automatically shares all child pages beneath it
- Share your top-level workspace pages to give MARVIN broad access
- Or share only specific pages/databases for more targeted access

## Try It

After setup, try these commands with MARVIN:

- "Search my Notion for meeting notes"
- "What's in my project tracker database?"
- "Create a new Notion page called 'Weekly Review' under my notes"
- "Show me all entries in my tasks database tagged 'urgent'"
- "Add a section to my roadmap page about the new API integration"
- "What did I write about onboarding last week?"

## Danger Zone

This integration can perform actions that affect your shared Notion workspace:

| Action | Risk Level | Who's Affected |
|--------|------------|----------------|
| Create pages | **Medium** | New pages appear in shared workspaces; collaborators may see them |
| Update pages | **Medium** | Changes are visible to all workspace collaborators |
| Append content | **Medium** | Adds blocks to existing pages; collaborators see changes |
| Add comments | **Medium** | Mentioned users and page followers get notified |
| Search and read pages | Low | No external impact |
| Query databases | Low | No external impact |

MARVIN will always confirm before creating, updating, or appending to pages.

## Troubleshooting

**"Can't find any pages" or empty search results**
- This is almost always a permissions issue. Make sure you've shared the pages/databases with your Notion integration (see "Sharing Pages" above).
- Sharing a parent page shares all its children — this is the fastest way to grant broad access.

**"Invalid token" or "Unauthorized"**
- Verify the token in `.env` starts with `ntn_` and hasn't been revoked
- Go to https://www.notion.so/profile/integrations and check that the integration is still active
- Generate a fresh token if needed and re-run the setup script

**"npx: command not found"**
- Install Node.js from https://nodejs.org (includes `npx`)
- Verify with: `node --version && npx --version`

**OAuth flow doesn't complete**
- The OAuth flow can be flaky with Claude Code. If it fails after 2-3 attempts, switch to the API token method — re-run the setup script and choose Option A.

**MCP server crashes or times out**
- Check your Node.js version: `node --version` (requires v18+)
- Try clearing the npx cache: `npx clear-npx-cache` then re-run setup
- Run `claude mcp list` to verify `notion` is registered

**Pages are outdated or stale**
- The MCP server fetches live data from Notion's API on each request — there's no cache. If content seems stale, the page may not have been saved in Notion yet.

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

Additionally, it checks for Node.js (required for the `npx`-based local server) following the Slack setup.sh pattern.

```bash
#!/bin/bash
# Notion MCP Setup Script
# Connect MARVIN to Notion for pages, databases, and notes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Notion MCP Setup${NC}"
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

# Check Node.js (needed for npx-based local server)
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js installed$(node --version 2>/dev/null | sed 's/^/ /')${NC}"
else
    echo -e "${RED}✗ Node.js not found${NC}"
    echo "Node.js is required for the Notion MCP server."
    echo "Install from: https://nodejs.org"
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
echo "How would you like to authenticate with Notion?"
echo ""
echo "  1) API token — internal integration token (recommended)"
echo "  2) OAuth — browser login"
echo ""
echo -e "${YELLOW}Choice [1]:${NC}"
read -r AUTH_CHOICE
AUTH_CHOICE=${AUTH_CHOICE:-1}

# Remove existing if present
claude mcp remove notion 2>/dev/null || true

if [[ "$AUTH_CHOICE" == "2" ]]; then
    echo ""
    echo -e "${BLUE}Adding Notion MCP to Claude Code (OAuth)...${NC}"

    # Add remote OAuth MCP server
    claude mcp add notion $SCOPE_FLAG \
        --transport http \
        https://mcp.notion.com/mcp

    echo -e "${GREEN}✓ Notion MCP added${NC}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Authentication${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Now you need to authenticate with Notion."
    echo ""
    echo -e "${YELLOW}Run this command:${NC}"
    echo ""
    echo "    claude mcp"
    echo ""
    echo "Then:"
    echo "  1. Find 'notion' in the list and select it"
    echo "  2. Choose 'Authenticate'"
    echo "  3. Complete the login in your browser"
    echo "  4. Select which pages to grant access to"
    echo ""
    echo -e "${YELLOW}Note: If the OAuth flow fails, re-run this script and choose Option 1 (API token) instead.${NC}"
    echo ""
    read -p "Press Enter once you've authenticated (or 's' to skip)... " AUTH_RESPONSE

    if [[ "$AUTH_RESPONSE" == "s" || "$AUTH_RESPONSE" == "S" ]]; then
        echo ""
        echo -e "${YELLOW}Skipped authentication.${NC}"
        echo "Remember to run 'claude mcp' and authenticate before using Notion."
    fi
else
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Step 1: Create a Notion Integration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "You need an internal integration token from Notion."
    echo ""
    echo "  1. Go to: https://www.notion.so/profile/integrations"
    echo "  2. Click 'New integration'"
    echo "  3. Name it (e.g., 'MARVIN')"
    echo "  4. Select your workspace"
    echo "  5. Under Capabilities, enable: Read, Update, and Insert content"
    echo "  6. Click 'Submit' and copy the token (starts with ntn_)"
    echo ""
    echo -e "${YELLOW}Paste your Notion integration token:${NC}"
    read -rs NOTION_TOKEN
    echo ""

    # Validate token format
    if [[ ! "$NOTION_TOKEN" =~ ^ntn_ ]]; then
        echo -e "${RED}✗ Token should start with 'ntn_'${NC}"
        echo "Make sure you're copying the Internal Integration Secret."
        exit 1
    fi

    echo -e "${GREEN}✓ Token format looks good${NC}"

    # Save to .env
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ENV_FILE="$(cd "$SCRIPT_DIR/../../.." && pwd)/.env"

    if [[ -f "$ENV_FILE" ]]; then
        # Update existing .env
        if grep -q "^NOTION_TOKEN=" "$ENV_FILE" || grep -q "^NOTION_API_KEY=" "$ENV_FILE"; then
            sed -i.bak "s|^NOTION_TOKEN=.*|NOTION_TOKEN=$NOTION_TOKEN|" "$ENV_FILE"
            sed -i.bak "s|^NOTION_API_KEY=.*|NOTION_API_KEY=$NOTION_TOKEN|" "$ENV_FILE"
            rm -f "$ENV_FILE.bak"
        else
            echo "NOTION_TOKEN=$NOTION_TOKEN" >> "$ENV_FILE"
        fi
    else
        echo "NOTION_TOKEN=$NOTION_TOKEN" > "$ENV_FILE"
    fi
    echo -e "${GREEN}✓ Token saved to .env${NC}"

    echo ""
    echo -e "${BLUE}Adding Notion MCP to Claude Code (local server)...${NC}"

    # Add local Notion MCP server via npx
    claude mcp add notion $SCOPE_FLAG \
        -e NOTION_TOKEN="$NOTION_TOKEN" \
        -- npx -y @notionhq/notion-mcp-server

    echo -e "${GREEN}✓ Notion MCP added with API token auth${NC}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Step 2: Share Pages with the Integration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}⚠  This step is critical!${NC}"
    echo ""
    echo "Your Notion integration can ONLY access pages you explicitly share with it."
    echo ""
    echo "For each page or database you want MARVIN to access:"
    echo "  1. Open the page in Notion"
    echo "  2. Click the '...' menu → Connections"
    echo "  3. Add your integration (e.g., 'MARVIN')"
    echo ""
    echo "Tip: Sharing a parent page shares all child pages beneath it."
    echo ""
    read -p "Press Enter once you've shared your pages (or 's' to do this later)... " SHARE_RESPONSE

    if [[ "$SHARE_RESPONSE" == "s" || "$SHARE_RESPONSE" == "S" ]]; then
        echo ""
        echo -e "${YELLOW}Remember to share pages before trying to search or read them!${NC}"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Try these commands with MARVIN:"
echo -e "  ${YELLOW}\"Search my Notion for meeting notes\"${NC}"
echo -e "  ${YELLOW}\"What's in my project tracker?\"${NC}"
echo -e "  ${YELLOW}\"Create a new page called 'Ideas'\"${NC}"
echo ""
echo -e "${GREEN}You're all set!${NC}"
echo ""
```

---

## Environment Variables

| Variable | Required? | Value | Where to get it |
|----------|-----------|-------|-----------------|
| `NOTION_TOKEN` | Only if using API token auth | `ntn_xxxxxxxxxxxx` | https://www.notion.so/profile/integrations |

**Note:** The `.env.example` currently uses `NOTION_API_KEY` as the variable name. For consistency with the official Notion MCP server (which expects `NOTION_TOKEN`), both names are handled by the setup script. Update `.env.example` to document both:

```
# Notion
NOTION_TOKEN=              # Internal integration token (for Notion MCP server)
NOTION_API_KEY=            # Alias — same value, used by some tools
```

---

## Files to Update in the Repo

### 1. `.marvin/integrations/README.md` — Add to the integrations table

Add this row to the "Available Integrations" table:

```markdown
| [Notion](./notion/) | Pages, databases, notes, knowledge base | `./.marvin/integrations/notion/setup.sh` |
```

Also remove `Notion` from the "Integration Ideas" list at the bottom (it's no longer just an idea).

### 2. Root `README.md` — Add to the integrations table

Add this row:

```markdown
| [Notion](.marvin/integrations/notion/) | Pages, databases, notes | `/help` then follow prompts |
```

### 3. Root `CLAUDE.md` — Update the integrations table

Add this row to the integrations table in the "Integrations" section:

```markdown
| Notion | Pages, databases, notes |
```

Also verify that the "Safety Guidelines" table already covers Notion actions. The existing row for "Publishing content" with "Confluence, Notion, blogs" already includes Notion — no change needed.

---

## Implementation Notes

- **Notion is more complex than Linear** primarily because of the page-sharing permission model. The integration token can be perfectly valid, but if the user hasn't shared pages with it in Notion's UI, every search returns empty. The setup script and README both emphasize this heavily.
- **The local `npx` server is recommended over OAuth** for reliability. The OAuth flow with Claude Code has been reported as flaky. The local server also gives better error messages when things go wrong.
- **Node.js is required** for the local server path. The setup script checks for this upfront (following the Slack integration pattern). The OAuth path does NOT need Node.js.
- **The `@notionhq/notion-mcp-server` package uses `NOTION_TOKEN`** as its environment variable, while `.env.example` currently has `NOTION_API_KEY`. The setup script writes both to `.env` for compatibility, and the `claude mcp add` command passes the correct one.
- **v2.0.0 introduced "data sources"** as the primary abstraction over databases. This simplifies querying and is the default behavior — no special configuration needed.
- **Notion databases are powerful** and MARVIN can leverage them for structured queries (filter by date, tag, status, person, etc.). This makes Notion especially useful as a knowledge base or task tracker that MARVIN can query during briefings.

---

## Testing Checklist

After implementation, verify these operations work:

- [ ] Search pages — `"Search my Notion for meeting notes"`
- [ ] Read a page — `"Show me the contents of my Roadmap page"`
- [ ] Create a page — `"Create a new Notion page called 'Test Page'"`
- [ ] Update a page — `"Add a heading to my Test Page: 'Section One'"`
- [ ] Query a database — `"Show all items in my tasks database with status 'In Progress'"`
- [ ] Handle missing permissions — searching for a page NOT shared with the integration returns a helpful message, not a crash
- [ ] MARVIN confirms before create/update/append actions (Danger Zone compliance)

---

## Conformance Checklist (from `.marvin/integrations/CLAUDE.md`)

- [x] `setup.sh` includes scope selection prompt
- [x] `setup.sh` uses correct color codes and banner format
- [x] `setup.sh` removes existing MCP before adding
- [x] `README.md` has all 9 required sections (Title, What It Does, Who It's For, Prerequisites, Setup, Try It, Danger Zone, Troubleshooting, Attribution)
- [ ] Added integration to the table in `.marvin/integrations/README.md`
- [ ] Tested on a fresh install
