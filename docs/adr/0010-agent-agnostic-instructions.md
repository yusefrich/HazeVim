# 10. Agent instructions are in AGENTS.md

- Status: Accepted
- Date: 2026-11-27

## Context

The repo had its agent instructions in `CLAUDE.md`. Only Claude Code reads that file. Other agents and models (Codex, Copilot, Cursor, Gemini, and others) read `AGENTS.md`, which is the shared convention. Two copies of the same instructions become different over time.

## Decision

- Put all agent instructions in `AGENTS.md`.
- `CLAUDE.md` contains only `@AGENTS.md`. Claude Code imports the file through it.
- Do not add instructions to a tool-specific file. If a tool needs its own file, that file only points to `AGENTS.md`.
- Docs and examples name "a coding agent", not a specific product.

## Consequences

- One source for the instructions, for each agent and model.
- A tool that reads neither `AGENTS.md` nor an import needs its own pointer file.
