# 2. No org or machine data in the repo

- Status: Accepted
- Date: 2026-11-22

## Context

This config is public. The user uses it at work. Paths, repo names and project names of the employer must not go into the repo, the PRs or the issues. An earlier version had an org-named folder, and the history was rewritten to remove it.

## Decision

- Keep the tools product agnostic. Detect the layout, or read it from a local config.
- Machine-local data goes in `*.local.json`, which `.gitignore` excludes.
- Commits use a personal email.
- Scan text and diffs for org data before each commit, push, PR edit or issue.

## Consequences

- A new repo needs a one-time `:BffSetup`.
- GitHub keeps the edit history of PR bodies. A leak there needs a manual delete of the history.
