# 6. BFF index staleness by mtime on BufEnter

- Status: Accepted
- Date: 2026-11-22

## Context

The index must follow file changes, also changes from other tools (for example Claude Code in another pane). A file-system watcher for each repo is fragile on macOS and costs resources for each worktree.

## Decision

- On `BufEnter`, compare the newest mtime of the watched paths with the index time.
- Watched paths: files with a TS, JS or JSON extension, and folders (a delete changes only the parent folder mtime). `node_modules`, dot folders and `watchSkip` are excluded.
- If the index is stale, build it again.

## Consequences

- No background watcher.
- A change shows on the next buffer switch, not at once.
