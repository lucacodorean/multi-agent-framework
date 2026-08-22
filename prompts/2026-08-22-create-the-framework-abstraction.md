# Create the project-context abstraction

## Purpose

Using the dependency analysis already performed, separate project-specific knowledge from the reusable framework.

The framework must become project-agnostic.

## Core principle

The architecture should follow:

Framework Core
    ↓ consumes
Project Context

The Framework Core must contain reusable behavior.

Project Context must contain information that changes between projects.

## Tasks

For every dependency previously classified as a project-context requirement:

1. Identify the information actually consumed by the framework.
2. Extract a reusable structure for it.
3. Replace project-specific values with placeholders.
4. Create project-context templates where appropriate.
5. Preserve headings, paths, identifiers, links, and semantic contracts required by agents.

Example:

Instead of:

`Run composer install`

the framework should depend on something conceptually equivalent to:

`dependency_install_command`

whose project-specific value may be:

`composer install`

## Ownership

Clearly distinguish:

### Framework-owned artifacts

Examples:

- agents;
- generic skills;
- orchestration;
- framework rules;
- contracts;
- context templates.

### Project-owned artifacts

Examples:

- architecture;
- technology stack;
- repository structure;
- development commands;
- testing strategy;
- infrastructure;
- deployment;
- coding conventions.

Project initialization must eventually modify only project-owned artifacts.

## Constraints

Do not:

- redesign unrelated framework components;
- introduce PHP assumptions;
- remove dependencies without replacing their purpose;
- duplicate project information unnecessarily.

A new project must eventually be usable without modifying framework-core files.

## Output

Implement the abstraction and provide a concise summary of:

- files created;
- files changed;
- dependencies migrated;
- remaining project-specific assumptions.