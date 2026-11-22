# 9. Read git paths with -z

- Status: Accepted
- Date: 2026-11-22

## Context

Without `-z`, git quotes paths with non-ASCII or special bytes (`"r\303\251sum\303\251.md"`). Such a path does not match the file on disk.

## Decision

When code reads paths from git output (`ls-files`, `worktree list --porcelain`), use `-z` and split on `"\0"` with `vim.system`.

## Consequences

- Non-ASCII file and worktree names work.
- `vim.fn.systemlist` is not used for path lists.
