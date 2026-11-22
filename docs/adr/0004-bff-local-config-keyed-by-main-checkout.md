# 4. BFF config is local and keyed by the main checkout

- Status: Accepted
- Date: 2026-11-22

## Context

Each repo has a different BFF layout (frameworks, SDK folders, specs, base path). Detection is not always correct. A repo can have many worktrees.

## Decision

- `:BffSetup` detects the layout and shows it for edit. A save writes it to `bff-links.local.json`.
- The entry key is the path of the main checkout. All worktrees of the repo use the same entry.
- All paths in an entry are relative, so they apply to each worktree.

## Consequences

- One setup for each repo, not for each worktree.
- The config file stays on the machine.
