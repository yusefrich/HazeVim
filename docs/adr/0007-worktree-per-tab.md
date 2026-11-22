# 7. Each worktree opens in its own tab

- Status: Accepted
- Date: 2026-11-22

## Context

LSP servers, linters and the BFF indexer must use the `node_modules` and generated files of the worktree, not of the main checkout.

## Decision

- `:Worktrees` opens the selected worktree in a new tab with a tab-local cwd (`:tcd`). If a tab already has that cwd, it goes to that tab.
- From a folder of repos, it lists the worktrees of each child repo.
- `<leader>gD` diffs the worktree against the merge base with the trunk, with `--imply-local`, so the right side is the working tree.

## Consequences

- Many worktrees can be open at the same time.
- Uncommitted changes show in the trunk diff.
