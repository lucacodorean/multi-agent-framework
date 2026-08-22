# Normalize project-context contracts

## Purpose

Ensure agents consume project knowledge through stable project-context contracts rather than direct assumptions about project files.

## Tasks

Review how framework agents and skills access project information.

Where appropriate, introduce a consistent mechanism for resolving project context.

Possible project-context categories include:

- architecture;
- development;
- repository structure;
- testing;
- infrastructure;
- deployment;
- conventions.

Do not assume this exact list if the current framework requires different categories.

Consider introducing a project-context manifest if it simplifies references.

Example:

project:
  name: "<project-name>"

context:
  architecture: project-context/architecture.md
  development: project-context/development.md
  testing: project-context/testing.md

Agents should preferably depend on concepts such as:

`project architecture context`

rather than independently hardcoding:

`docs/some-project/architecture.md`

## Requirements

Preserve all existing relationships between:

- agents;
- skills;
- workflows;
- documentation.

Do not introduce an abstraction unless there is a real consumer for it.

Prefer the smallest architecture that provides stable project-context resolution.

## Validation

Confirm that:

- no agent unnecessarily depends on the original project's structure;
- project-context references resolve correctly;
- framework-owned artifacts remain project-agnostic;
- changing projects would require changing project context, not framework logic.

## Output

Implement the normalized context contracts and summarize the resulting project-context structure.