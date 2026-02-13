# MARVIN Integration Guide: Linear + Notion

## Goal

Add two new integrations to the MARVIN template fork at `conorbronsdon/marvin-template` so that MARVIN can interact with Linear (project management) and Notion (docs, notes, knowledge base) via MCP servers.

---

## Before You Start

1. **Read the existing integration patterns first:**
   - `.marvin/integrations/CLAUDE.md` — required patterns for new integrations
   - `.marvin/integrations/README.md` — full documentation and contribution guidelines
   - `.marvin/integrations/atlassian/` — reference implementation (Jira/Confluence, closest analog to what we're building)

2. **Match the existing structure exactly.** Each integration should follow whatever conventions the Atlassian integration uses (setup.sh, README, env vars, etc.)

---

## Integration 1: Linear

### What It Does

Connects MARVIN to Linear for project management. Enables creating, finding, updating, and commenting on issues and projects.

### MCP Server Details

Linear provides an **official remote MCP server** — no local package installation needed.

- **Server URL (SSE):** `https://mcp.linear.app/sse`
- **Server URL (Streamable HTTP, preferred):** `https://mcp.linear.app/mcp`
- **Auth:** OAuth 2.1 with dynamic client registration (interactive browser flow)
- **Alternative auth:** Linear API key via `Authorization: Bearer <token>` header
- **Official docs:** https://linear.app/docs/mcp

### Claude Code Registration

Option A — OAuth (interactive, recommended for personal use):
```bash
claude mcp add --transport sse linear-server https://mcp.linear.app/sse
# Then run /mcp in Claude Code to authenticate via browser
```

Option B — API key (headless, better for scripted setup):
```bash
claude mcp add --transport http linear-server https://mcp.linear.app/mcp \
  --header "Authorization: Bearer ${LINEAR_API_KEY}"
```

To generate an API key: Linear → Settings → Account → Security & Access → API Keys

### Available MCP Tools (from Linear's server)

- Find/search issues, projects, comments
- Create issues (with title, description, assignee, priority, labels, project)
- Update issues (status, priority, assignee, etc.)
- Add comments to issues
- More tools actively being added by Linear

### Environment Variables Needed

```
LINEAR_API_KEY=lin_api_xxxxxxxxxxxx  # Only if using API key auth instead of OAuth
```

### Target Capabilities for MARVIN

- Create and assign tickets (with team, project, priority, labels)
- Update issue status and add context/comments from notes
- Search/query issues assigned to user
- Pull issue details for briefings and context
- Works alongside Linear's Slack integration (MARVIN creates/updates in Linear → Linear notifies in Slack automatically)

### Setup Script Behavior (setup.sh)

The setup script should:
1. Check if `npx` / Node.js is available (needed for `mcp-remote` if using SSE transport)
2. Ask user: OAuth flow or API key?
3. If API key: prompt for key, validate it works, save to `.env`
4. Register the MCP server with Claude Code
5. Run `/mcp` or equivalent to verify connection
6. Print confirmation of available tools

---

## Integration 2: Notion

### What It Does

Connects MARVIN to Notion for reading/writing docs, pulling notes from databases, and using Notion as a knowledge/context source.

### MCP Server Details

Notion provides **two options:**

**Option A — Official hosted remote MCP server (OAuth):**
- **Server URL:** `https://mcp.notion.com/mcp`
- **Auth:** OAuth 2.1 (interactive browser flow)
- **Docs:** https://developers.notion.com/guides/mcp/get-started-with-mcp
- **Note:** Some users report the OAuth flow with Claude Code can be flaky; may require multiple attempts

**Option B — Official open-source local MCP server (API token, recommended):**
- **Package:** `@notionhq/notion-mcp-server`
- **Auth:** Internal integration token (more reliable, more control over scope)
- **GitHub:** https://github.com/makenotion/notion-mcp-server
- **Current version:** 2.0.0 (uses Notion API 2025-09-03, data sources as primary abstraction)

### Claude Code Registration

Option A — Remote OAuth:
```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
# Then run /mcp in Claude Code to authenticate via browser
```

Option B — Local with API token (recommended):
```bash
claude mcp add --transport stdio notion \
  --env NOTION_TOKEN=ntn_xxxx \
  -- npx -y @notionhq/notion-mcp-server
```

### How to Get a Notion API Token

1. Go to https://www.notion.so/profile/integrations
2. Create a new internal integration
3. Copy the integration token (starts with `ntn_`)
4. **Critical step:** Go to each Notion page/database you want MARVIN to access → click "..." menu → "Connections" → add your integration. The integration can only see pages you explicitly share with it.

### Available MCP Tools (v2.0.0)

- Search pages and databases
- Retrieve page content, database metadata, data source schemas
- Create and update pages
- Query data sources (databases) with filters and sorting
- Append content blocks to pages
- Create and read comments
- Manage data source items

### Environment Variables Needed

```
NOTION_TOKEN=ntn_xxxxxxxxxxxx  # Internal integration token
```

### Target Capabilities for MARVIN

- **Pull notes:** Query user's notes database, retrieve note content, convert to structured .md files for MARVIN's local knowledge/context
- **Update docs:** Edit strategy docs, append content, update page properties
- **Context source:** Search across connected Notion pages to pull relevant context into conversations and briefings
- **Database queries:** Filter and sort database entries (e.g., "show me all notes from this week tagged with 'modular'")

### Setup Script Behavior (setup.sh)

The setup script should:
1. Check if `npx` / Node.js is available
2. Ask user: OAuth flow or API token?
3. If API token: prompt for token, save to `.env`
4. Register the MCP server with Claude Code
5. Remind user they must share specific Notion pages/databases with the integration (this is the most common setup mistake)
6. Optionally: ask user for their primary notes database ID to store in config for quick access
7. Verify connection by attempting a search
8. Print confirmation of available tools

---

## Files to Create

For each integration, create a directory matching the existing pattern. Based on the Atlassian integration, you likely need at minimum:

```
.marvin/integrations/linear/
├── setup.sh          # Interactive setup script
└── README.md         # User-facing docs (what it does, prerequisites, usage examples)

.marvin/integrations/notion/
├── setup.sh          # Interactive setup script
└── README.md         # User-facing docs (what it does, prerequisites, usage examples)
```

**Check the Atlassian directory for any additional files** (e.g., CLAUDE.md, config templates, verification scripts) and replicate that structure.

---

## Files to Update

1. **README.md** (repo root) — Add Linear and Notion to the integrations table:

| Integration | What It Does | Setup |
|---|---|---|
| Linear | Issues, projects, comments | `/help` then follow prompts |
| Notion | Pages, databases, notes | `/help` then follow prompts |

2. **CLAUDE.md** (repo root) — Update the integrations table that lists setup script paths:

```
./.marvin/integrations/linear/setup.sh    | Linear (issues, projects)
./.marvin/integrations/notion/setup.sh    | Notion (pages, databases, notes)
```

3. **CLAUDE.md** confirmation rules — Linear and Notion are already mentioned in the "actions requiring confirmation" section (modifying tickets in Linear, publishing to Notion). Verify these are still accurate after implementation.

---

## Implementation Notes

- **Start with the Atlassian integration as your template.** Copy its structure and adapt — don't build from scratch.
- **Linear is simpler** — remote MCP server, no local package. Start here.
- **Notion is more involved** — local MCP server recommended for reliability, plus the page-sharing permission step that trips people up.
- **Both integrations should store secrets in `.env`** (which is already gitignored by the template).
- **Test both integrations** with basic operations before considering them done:
  - Linear: search issues, create an issue, update an issue
  - Notion: search pages, read a page, update a page, query a database
- The Linear Slack integration works independently — when MARVIN creates or updates issues in Linear, Slack notifications fire automatically through Linear's own Slack app. No extra wiring needed on MARVIN's side.
