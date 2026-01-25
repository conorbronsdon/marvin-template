# Microsoft 365 Integration

Connect Claude Code to Microsoft 365 (Outlook, Calendar, OneDrive, Teams, SharePoint, etc.)

## Setup

```bash
./.marvin/integrations/ms365/setup.sh
```

## What You Get

- **Outlook** - Read, send, and manage emails
- **Calendar** - View and create events
- **OneDrive** - Access and manage files
- **Teams** - Read channels and messages
- **SharePoint** - Access sites and documents
- **To Do** - Manage tasks
- **OneNote** - Access notebooks
- **Planner** - View and manage plans

## Authentication

Uses Microsoft's device flow authentication:
1. First request opens a browser prompt
2. Enter the device code shown
3. Sign in with your Microsoft account
4. Tokens are cached for future sessions

No API keys or client secrets required.

## Account Types

The `--org-mode` flag enables both:
- Work/School accounts (Microsoft 365 Business)
- Personal Microsoft accounts (outlook.com, hotmail.com)

## Manual Setup

If you prefer to set up manually:

```bash
claude mcp add ms365 -s user -- npx -y @softeria/ms-365-mcp-server --org-mode
```

## Troubleshooting

**"Failed to connect" error:**
- Run `claude mcp remove ms365 -s user` and re-run setup
- Make sure Node.js is installed

**Authentication issues:**
- Clear cached tokens by removing `~/.ms365-mcp/` directory
- Re-authenticate on next request

## More Info

- MCP Package: [@softeria/ms-365-mcp-server](https://www.npmjs.com/package/@softeria/ms-365-mcp-server)
