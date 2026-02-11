---
name: readme-generator
description: Generates professional README.md files for projects with customizable templates
version: 1.0.0
author: cli_sync
---

# README Generator

## Overview
This skill generates comprehensive README.md files for projects. It provides customizable templates for different project types including Python, Node.js, CLI tools, and libraries. The generated READMEs follow best practices and include all essential sections.

## Parameters
- `project_name`: Name of the project (required)
- `project_type`: Type of project - python, nodejs, cli, library, or generic (optional, default: "generic")
- `description`: Brief description of the project (optional)
- `author`: Author name (optional, default: "Unknown")
- `include_screenshots`: Whether to include screenshot placeholders (optional, default: true)
- `license`: License type (optional, default: "MIT")

## Usage Examples

### Basic usage
```
readme_generator --project_name "my_project" --project_type "python"
```

### Full options
```
readme_generator --project_name "my_cli_tool" --project_type "cli" --description "A powerful CLI tool" --author "John Doe" --license "MIT"
```

### Generate for Node.js library
```
readme_generator --project_name "my_library" --project_type "library" --include_screenshots false
```

## Templates

### Python Project
Includes: Installation, Usage, Testing, Contributing sections

### Node.js Project
Includes: Installation, CLI usage, API reference, Scripts

### CLI Tool
Includes: Installation (via Homebrew/npm), Commands reference, Examples

### Library
Includes: API documentation, Examples, Type definitions

### Generic
Includes: Basic sections suitable for any project type

## Generated Sections
All templates include:
- Badges (build, license, version)
- Description
- Features
- Installation
- Usage
- Configuration (if applicable)
- Testing
- Contributing
- License
- Contact

## Tips
- Customize the generated README to match your project's specific needs
- Add screenshots in the designated places for visual documentation
- Keep the README updated as the project evolves
- Consider adding a CONTRIBUTION.md for larger projects
