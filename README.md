# Codeforward Dev Tools

Bootstrap installer for Codeforward developer tools.

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/codeforward-dev-tools/main/install.sh)"
```

This installs and runs the Codeforward Dev Tools menu, which provides:

- **Setup customer dev environment** - Clone repo, configure Odoo, create venv, install DB
- **Create new customer repository** - Scaffold a new Odoo project from template
- **Update Odoo worktrees** - Fetch and reset all Odoo source worktrees
- **Add Odoo worktree** - Add community/enterprise worktrees for a specific version
- **Sync Claude Code configuration** - Sync team CLAUDE.md, settings, and MCP servers

## Requirements

- macOS (Linux support planned)
- Git
- GitHub CLI (`gh`) - installed automatically if missing
- GitHub organization access to `codeforward-bv`

## Re-running

After installation, run the tools anytime:

```bash
cf-dev-tools
```

Or re-run the installer to update:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/codeforward-dev-tools/main/install.sh)"
```
