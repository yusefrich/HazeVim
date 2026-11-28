# 3. The BFF indexer uses the TypeScript compiler API

- Status: Accepted
- Date: 2026-11-22

## Context

Route-to-upstream links need real symbol resolution: imports, re-exports, aliases, class methods, dependency injection and generated SDKs. Regex or tree-sitter cannot follow these across files.

## Decision

- `indexer.cjs` is a Node script. It builds a `ts.Program` from the project `tsconfig.json` and uses the type checker.
- It loads the repo's own `typescript` package through `NODE_PATH` (the `node_modules` of the worktree, the main checkout and the repo root). TypeScript is not bundled.
- Relative paths in a tsconfig are resolved from the folder of that tsconfig.
- If a linked worktree has no `node_modules`, a wrapper on `ts.sys` and the compiler host reads missing `<worktree>/node_modules/...` paths from the `NODE_PATH` folders. Source files stay in the worktree.
- The indexer writes JSON to stdout. `init.lua` draws it.

## Consequences

- The index uses the same TypeScript version as the repo.
- A repo with no installed `node_modules` anywhere cannot be indexed.
