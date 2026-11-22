# Context and glossary

This file defines the terms that this repo uses. The code, the README, the ADRs and the issues use these terms with these meanings only.

## Domain

| Term | Meaning |
|---|---|
| **BFF** | Backend for frontend. A TypeScript service that a frontend calls. It calls one or more upstream services. |
| **BFF links** | The feature in `lua/tools/bff`. It shows how the routes of a BFF connect to the upstream calls that they make. |
| **Route** | An HTTP endpoint that the BFF serves (method + path). Found from TSOA, NestJS or Express code. |
| **Handler** | The function that runs for a route. In Express, a route can have more than one handler (middleware + final handler). |
| **Upstream** | A service or resource that the BFF calls: a generated SDK, an npm client package, Prisma, AWS SDK v3, or `fetch`. |
| **Op (operation)** | One upstream endpoint or call target, for example `GET /users/{id}` of an SDK, or a `fetch` URL. Each op has an `id`. |
| **Call site** | A place in the BFF source that calls an op. |
| **Spec** | An OpenAPI file. An **upstream spec** describes an upstream service. The **own spec** describes the routes of the BFF itself (for example the TSOA `swagger.json`). |
| **SDK** | A generated OpenAPI client in the repo (hey-api `sdk.gen.ts` style). Each SDK function links to its op in the spec. |
| **Client package** | An npm package that is an upstream client. The name ends in `-client` or `-sdk`, or the config lists it in `clientPackages`. |
| **Generated client** | A client package or SDK that a tool makes from the spec of a backend. The backend, the spec and the client can be in separate repos. |
| **Hop** | One step in the call graph between a handler and a call site (a service or helper function). |
| **Reach** | The set of ops that a node calls, directly or through hops. |

## Indexer

| Term | Meaning |
|---|---|
| **Index** | The JSON that `indexer.cjs` writes for one project: routes, call sites, ops, nodes and reverse maps. |
| **Node** | A function in the call graph. The id is `file:line:name`. |
| **Synthetic node** | A node for code with no named declaration: an inline handler, or a route with more than one handler. |
| **Edge** | A call from one node to another node. |
| **Direct** | The ops that a node calls itself, with no hop. |
| **Mount** | `app.use(prefix, router)` in Express. It adds a prefix to all routes of the child router. |
| **Router key** | A key that identifies a router: its declaration, and the factory function that made it. |
| **Project** | One entry in the local config: a folder with a `tsconfig.json`, the frameworks, and the upstream settings. A monorepo can have more than one project. |
| **Stale** | The index is older than the newest watched file or folder. The index is built again on the next `BufEnter`. |

## Git and worktrees

| Term | Meaning |
|---|---|
| **Main checkout** | The first worktree of a repo (the folder with the `.git` folder). The BFF config entry key is its path. |
| **Linked worktree** | A worktree that `git worktree add` made. It has a `.git` file, not a `.git` folder. |
| **Nested ignored worktree** | A linked worktree inside the main checkout, in a folder that the main checkout ignores (for example `.claude/worktrees/<name>`). |
| **Trunk** | The remote default branch: `origin/HEAD`, else `origin/main`, else `origin/master`. |
| **Tab-local cwd** | The cwd that `:tcd` sets for one tab. Each worktree opens in its own tab with its own cwd. |

## Glow

| Term | Meaning |
|---|---|
| **glow** | The `glow` CLI from Charm. It renders Markdown in the terminal. |
| **Start screen** | The glow file list (TUI), full screen, for the current worktree (`<leader>cg`). |
| **Mirror** | A folder in `~/.cache/nvim/glow/` with hard links to the Markdown files of a nested ignored worktree. glow lists it because no `.gitignore` applies there. |
| **File view** | The current buffer, rendered by glow, in a normal Neovim buffer with highlights (`<leader>cG`). |
| **Wide mode** | A file-view mode where glow does not squeeze tables and code to the window width. |
| **Preview** | The glow render of the current file in a split terminal buffer (`:GlowPreview`). |
| **Generation counter** | A number that goes up for each render request. A result with an older number is ignored. |

## Config

| Term | Meaning |
|---|---|
| **Local config** | `bff-links.local.json` in the Neovim config folder. It is git-ignored, because it contains local paths and project names. |
| **Org data** | Company names, work paths, work emails, local repo or project names. It must not go into this repo, its PRs or its issues. |
