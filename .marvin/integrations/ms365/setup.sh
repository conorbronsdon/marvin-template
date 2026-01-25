#!/bin/bash
# Microsoft 365 Setup for Claude Code
# Created by Sterling Chin
#
# This sets up MS 365 MCP for Outlook, Calendar, OneDrive, Teams, etc.
# Uses device flow authentication (no API keys required)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Microsoft 365 Setup for Claude${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if command -v npx &> /dev/null; then
    echo -e "${GREEN}  npx installed${NC}"
else
    echo -e "${RED}  npx not found${NC}"
    echo "  Install Node.js from https://nodejs.org"
    exit 1
fi

if command -v claude &> /dev/null; then
    echo -e "${GREEN}  Claude Code installed${NC}"
else
    echo -e "${RED}  Claude Code not found${NC}"
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Remove existing MCP if present
echo ""
echo -e "${BLUE}Configuring Microsoft 365 MCP...${NC}"
claude mcp remove ms365 2>/dev/null || true

# Add MCP with org-mode (supports work/school accounts)
claude mcp add ms365 -s user \
    -- npx -y @softeria/ms-365-mcp-server --org-mode

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Start Claude Code: ${YELLOW}claude${NC}"
echo ""
echo "  2. First MS 365 request will prompt you to:"
echo "     - Visit a URL"
echo "     - Enter a device code"
echo "     - Sign in with your Microsoft account"
echo ""
echo "  3. Try: ${YELLOW}\"What's on my Outlook calendar today?\"${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} The --org-mode flag enables work/school accounts."
echo "      Personal Microsoft accounts are also supported."
echo ""
