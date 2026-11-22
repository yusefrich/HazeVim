# Architecture decision records

| # | Decision |
|---|---|
| 0000 | [Record architecture decisions](0000-record-architecture-decisions.md) |
| 0001 | [Custom tools are local modules, not external plugins](0001-local-modules-not-plugins.md) |
| 0002 | [No org or machine data in the repo](0002-no-org-data-in-repo.md) |
| 0003 | [The BFF indexer uses the TypeScript compiler API](0003-bff-indexer-typescript-compiler-api.md) |
| 0004 | [BFF config is local and keyed by the main checkout](0004-bff-local-config-keyed-by-main-checkout.md) |
| 0005 | [Express route graph and reachability](0005-bff-route-graph-and-reachability.md) |
| 0006 | [BFF index staleness by mtime on BufEnter](0006-bff-staleness-by-mtime-on-bufenter.md) |
| 0007 | [Each worktree opens in its own tab](0007-worktree-per-tab.md) |
| 0008 | [Glow views: start screen, mirror, and ANSI-parsed file view](0008-glow-views.md) |
| 0009 | [Read git paths with -z](0009-git-nul-output.md) |

## Template

```markdown
# N. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context

## Decision

## Consequences
```
