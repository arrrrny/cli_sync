---
name: skill_builder
description: A comprehensive guide and template for creating standardized skills
version: 1.0.0
author: cli_sync
---

# Skill Builder

## Overview
This skill provides a comprehensive guide and template for creating standardized skills that follow the cli_sync framework. It explains the proper format, required elements, and best practices for creating effective skills.

## Standard Skill Format

When creating skills for the cli_sync framework, follow this standardized format:

### YAML Front Matter (Required)
```yaml
---
name: unique_skill_name
description: Brief but comprehensive description of what the skill does
version: 1.0.0
author: your_name_or_organization
---
```

### Key Points for Each Field:

#### Name
- Use lowercase with underscores or hyphens for multi-word names
- Make it descriptive and unique
- Examples: `file_backup`, `git_commit_helper`, `docker_manager`

#### Author
- Your name, username, or organization
- Helps track ownership and maintenance
- Examples: `john_doe`, `my_company`, `team_alpha`

#### Version
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Increment appropriately when making changes:
  - MAJOR: Breaking changes
  - MINOR: New features (backward compatible)
  - PATCH: Bug fixes (backward compatible)

#### Description
- Concise but comprehensive explanation of the skill's purpose
- Should clearly state what the skill does
- Limit to 1-2 sentences for clarity
- Focus on the value proposition

### Markdown Content Structure

After the YAML front matter, structure your skill documentation as follows:

1. **Overview** (required): Brief introduction to the skill
2. **Parameters** (if applicable): List of all parameters with descriptions
3. **Usage Examples** (recommended): At least one practical example
4. **Implementation Details** (optional): Technical implementation notes

## Best Practices

### Naming Conventions
- Use descriptive names that clearly indicate the skill's function
- Avoid generic names like "helper" or "tool"
- Use consistent naming patterns across related skills

### Documentation Standards
- Write in clear, concise language
- Use proper markdown formatting
- Include practical examples that users can adapt
- Document all parameters and their expected values
- Mention any prerequisites or dependencies

### Parameter Documentation
When documenting parameters:
- Specify data types where relevant
- Indicate required vs optional parameters
- Provide default values when applicable
- Use consistent terminology

### Example Template

```markdown
---
name: example_skill
description: Performs a specific task with configurable options
version: 1.0.0
author: your_name
---

# Example Skill

## Overview
This skill performs a specific task with configurable options. It is designed to be reusable and adaptable to different contexts.

## Parameters
- `param1`: Description of the first parameter (required)
- `param2`: Description of the second parameter (optional, default: "value")

## Usage Examples

### Basic usage
```
example_skill --param1 "value1"
```

### Advanced usage
```
example_skill --param1 "value1" --param2 "value2"
```

## Implementation
Brief note about how the skill works internally or any special considerations.
```

## Validation Checklist

Before finalizing a skill, ensure it includes:

- [ ] Proper YAML front matter with all required fields
- [ ] Clear and descriptive name
- [ ] Accurate version number
- [ ] Comprehensive but concise description
- [ ] Well-structured markdown content
- [ ] At least one usage example
- [ ] Documentation of all parameters
- [ ] Information about any dependencies

## Common Mistakes to Avoid

- Writing overly vague descriptions
- Forgetting to document required parameters
- Not providing practical usage examples
- Using inconsistent naming conventions
- Neglecting to update version numbers when making changes
- Including sensitive information or hardcoded credentials

## Additional Resources

For more information about skill development:
- Review existing skills in the framework for examples
- Follow the established patterns and conventions
- Test skills thoroughly before deployment
- Consider how the skill integrates with other components
