# Codeforward Dev Tools

Bootstrap installer for Codeforward developer tools.

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/codeforward-dev-tools/main/install.sh)"
```

## Menu Options

1. **Setup customer project** - Clone existing or create new Odoo project
2. **Update Odoo worktrees** - Fetch and reset all Odoo source worktrees
3. **Add Odoo worktree** - Add community/enterprise worktrees for a specific version
4. **Sync Claude Code configuration** - Sync team CLAUDE.md, settings, and MCP servers
5. **Exit**

## Requirements

- macOS (Linux support planned)
- Git
- GitHub CLI (`gh`) - installed automatically if missing
- GitHub organization access to `codeforward-bv`

## Usage

After installation, run the tools anytime:

```bash
cf-dev-tools
```

Or re-run the installer to update:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/codeforward-dev-tools/main/install.sh)"
```
