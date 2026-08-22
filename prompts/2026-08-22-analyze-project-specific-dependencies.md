# Analyze project-specific dependencies

## Purpose

Analyze the current multi-agent framework and determine which parts are still coupled to the PHP project from which it was extracted.

Do not perform the abstraction yet.

## Tasks

Inspect the complete workspace, including:

- agents;
- skills;
- workflows;
- documentation;
- configuration;
- scripts;
- paths;
- commands;
- environment assumptions;
- testing/deployment instructions;
- references between framework files.

For every project-specific dependency or assumption, classify it as:

1. **Framework invariant**
   - Belongs to the framework and should remain.

2. **Project-context requirement**
   - Information required by the framework but whose value depends on the project.

3. **Configurable framework behavior**
   - Currently hardcoded behavior that should become configurable.

4. **Legacy project artifact**
   - Exists only because of the original project and has no generic framework value.

## Important

Do not blindly remove PHP-specific references.

Determine the semantic purpose of each reference first.

For example:

`composer install`

may represent the generic concept:

`dependency installation command`

rather than something that should simply be deleted.

## Output

Produce a concise analysis containing:

- project-specific dependencies discovered;
- their classification;
- files affected;
- proposed abstraction for each dependency;
- potential risks when removing or modifying them.

Do not implement the abstraction yet.