# 1. Custom tools are local modules, not external plugins

- Status: Accepted
- Date: 2026-11-22

## Context

The BFF links, glow and worktree features need behaviour that no maintained plugin gives. `glow.nvim` is archived. A fork of a plugin adds a second repo to maintain.

## Decision

Put custom code in `lua/tools/`. Attach it through lazy.nvim specs in `lua/plugins/`:
- `bff-links` is a local lazy "plugin" (`dir = .../lua/tools/bff`), so lazy loads it on events, commands and keys.
- glow and worktree attach their keys to the `snacks.nvim` spec. They make their user commands at the top level of the spec file, not in an `init`, because lazy keeps only one `init` for each plugin.

## Consequences

- No extra plugin to update for these features.
- The code must follow Neovim API changes itself.
