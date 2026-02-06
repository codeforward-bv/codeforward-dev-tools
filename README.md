# Codeforward Dev Tools

Bootstrap installer for Codeforward developer tools.

## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/cf-dev-tools/main/install.sh)"
```

## Menu Options

1. **Setup customer project** - Clone existing or create new Odoo project
2. **Manage Odoo worktrees** - Update all worktrees or add new versions
3. **Sync Claude Code configuration** - Sync team CLAUDE.md, settings, and MCP servers
4. **Exit**

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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/codeforward-bv/cf-dev-tools/main/install.sh)"
```
