# CLI Sync

A collection of synchronization scripts for managing MCP servers and skills in a CLI environment.

## Overview

This project contains scripts for synchronizing various components of an MCP (Multi-Agent Communication Protocol) system, including:

- MCP server configurations
- Skills and their configurations
- Private skills

## Scripts

### `cli_sync.sh`
Main synchronization script for the CLI environment.

### `mcp_sync.sh`
Synchronization script for MCP server configurations.

### `skill_sync.sh`
Synchronization script for skills and their configurations.

## Sync Providers

### MCP Server Sync Providers
The `mcp_sync.sh` script supports synchronization with the following MCP-enabled applications:

- **Zed** - Editor configuration at `~/.config/zed/settings.json`
- **Amp** - Editor configuration at `~/.config/amp/settings.json`
- **Claude** - Assistant configuration at `~/.claude/settings.json`
- **Kiro CLI** - Available at `/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli`
- **Kilo-code** - Editor configuration at `~/.config/kilocode.kilo-code/settings/mcp_settings.json`
- **Factory-droid** - Configuration at `~/.factory/mcp.json`
- **Trae** - Editor configuration at `~/Library/Application Support/Trae/User/mcp.json`
- **Qwen** - Assistant configuration at `~/.qwen/settings.json`
- **OpenCode** - Editor configuration at `~/.config/opencode/opencode.json`
- **Vibe** - Editor configuration at `~/.vibe/config.toml`
- **Codebuddy** - Assistant configuration at `~/.codebuddy/.mcp.json`
- **Antigravity** - Configuration at `~/.gemini/antigravity/mcp_config.json`
- **Qoder** - Assistant configuration at `~/.qoder.json`
- **Auggie** - Assistant configuration at `~/.augment/settings.json`

### Skill Sync Providers
The `skill_sync.sh` script supports synchronization with the following skill-enabled applications:

- **Zed** - Skills directory at `~/.config/zed/skills`
- **Claude** - Skills directory at `~/.claude/skills`
- **Amp** - Skills directory at `~/.config/amp/skills`
- **Kiro** - Skills directory at `~/.kiro/skills`
- **Kilo** - Skills directory at `~/.kilocode/skills`
- **Factory** - Skills directory at `~/.factory/skills`
- **Trae** - Skills directory at `~/Library/Application Support/Trae/User/skills`
- **Qwen** - Skills directory at `~/.qwen/skills`
- **OpenCode** - Skills directory at `~/.config/opencode/skills`
- **Vibe** - Skills directory at `~/.vibe/skills`
- **Codebuddy** - Skills directory at `~/.codebuddy/skills`
- **Auggie** - Skills directory at `~/.augment/skills`
- **Qoder** - Skills directory at `~/.qoder/skills`

## Configuration

Configuration files are located in:
- `mcp_sync_configs/` - MCP server configurations
- `skill_sync_configs/` - Skill configurations
- `private_skills/` - Private skill implementations

## Setup

1. Clone the repository
2. Ensure you have the necessary permissions and dependencies installed
3. Configure your server and skill settings in the respective config directories

## Usage

Run the main sync script to synchronize all components:

```bash
./cli_sync.sh
```

Or run individual sync scripts:

```bash
# Sync MCP servers
./mcp_sync.sh

# Sync skills
./skill_sync.sh
```

## Prerequisites

- Bash-compatible shell
- Git (for version control)
- Appropriate permissions for the target systems

## Contributing

Feel free to submit issues and enhancement requests via GitHub Issues.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.