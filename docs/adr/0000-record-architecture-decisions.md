# 0. Record architecture decisions

- Status: Accepted
- Date: 2026-11-22

## Context

We need a record of the design decisions in this config, so that later changes do not undo them by mistake.

## Decision

Record each decision as a short ADR in `docs/adr/`. Each ADR has a number, a status, the context, the decision and the consequences. Do not change an accepted ADR. If a decision changes, write a new ADR that supersedes the old one.

## Consequences

- The reasons for the design are in the repo, next to the code.
- `CLAUDE.md` tells agents to add an ADR for each new decision.
