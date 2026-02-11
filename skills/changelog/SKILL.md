---
name: changelog-updater
description: Updates the changelog file in SEM (Semantic Versioning and Metadata) format
version: 1.0.0
author: cli_sync
---

# Changelog Updater Skill

## Overview
This skill updates the changelog file following SEM (Semantic Versioning and Metadata) format. It adds a new entry with the current date, version number, and change description to the changelog file.

## Parameters
- `file_path`: Path to the changelog file (default: CHANGELOG.md)
- `version`: Version number to add (e.g., 1.2.3)
- `changes`: Array of changes to add under the version
- `change_type`: Type of changes (added, changed, deprecated, removed, fixed, security)

## Usage Examples

### Add a new version with changes
```
changelog_updater \
  --file_path "CHANGELOG.md" \
  --version "1.2.3" \
  --change_type "fixed" \
  --changes "Fixed critical security vulnerability" "Resolved issue with user authentication"
```

### Add multiple types of changes to a version
```
changelog_updater \
  --version "2.0.0" \
  --change_type "added" \
  --changes "Implemented new dashboard UI" "Added support for multi-language"
```

## Implementation
The skill will:
1. Check if the changelog file exists, create it if it doesn't
2. Verify the version isn't already in the changelog
3. Insert the new version entry at the top of the file
4. Format the entry according to SEM standards
5. Preserve existing changelog content below the new entry

## SEM Format
The changelog follows Semantic Versioning with the following sections:
- Added: for new features
- Changed: for changes in existing functionality
- Deprecated: for soon-to-be removed features
- Removed: for now removed features
- Fixed: for bug fixes
- Security: for security enhancements

Each version entry includes:
- Version number with release date
- List of categorized changes
- Proper markdown formatting
