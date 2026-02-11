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

[Add your license information here]