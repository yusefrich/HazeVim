# CLAUDE.md

Instructions for Claude Code (and other agents) that work in this repo.
For the terms used here, see [CONTEXT.md](CONTEXT.md). For the reasons behind the design, see [docs/adr/](docs/adr/).

## What this repo is

A personal Neovim config on top of LazyVim. Most files are LazyVim plugin specs. The custom code is in `lua/tools/`:

| Path | What it does |
|---|---|
| `lua/tools/bff/indexer.cjs` | Node script. Uses the TypeScript compiler API to index a BFF: routes, call sites, upstream ops, and the call graph. Writes JSON to stdout. |
| `lua/tools/bff/init.lua` | Runs the indexer, draws the annotations (extmarks), and gives the pickers and commands. |
| `lua/tools/bff/config.lua` | Reads and writes `bff-links.local.json`. |
| `lua/tools/glow.lua` | The glow start screen, the glow file view, and the split preview. |
| `lua/tools/worktree.lua` | The worktree switcher and `<leader>gD` (diff against the trunk). |
| `lua/plugins/*.lua` | lazy.nvim specs. `bff.lua`, `glow.lua` and `worktree.lua` attach the tools above. |

`README.md` has the command and keymap matrix. When you add or change a command or keymap, update that matrix in the same commit.

## Rules

### No org or machine data in the repo

- Never commit company names, work paths, work emails, local repo names, or project names.
- Machine-local data goes in `*.local.json` files. `.gitignore` excludes them. Example: `bff-links.local.json`.
- Before each commit, push, PR edit, or issue, scan the text and the diff for org data. See [ADR 0002](docs/adr/0002-no-org-data-in-repo.md).
- Commits use the personal email that is set in the repo git config. Do not change it.

### Code

- Keep the tools product agnostic. Detect the layout, or read it from the local config. Do not hard-code a framework path or a repo name.
- Neovim 0.12 or later. Use `vim.system`, `vim.fs`, `vim.uv` and `vim.json`.
- When you read git output that contains paths, use `-z` and split on `"\0"`. Without `-z`, git quotes non-ASCII names. See [ADR 0009](docs/adr/0009-git-nul-output.md).
- Async renders (glow, the indexer) must ignore a result that is older than the newest request. Use a generation counter.
- Decode the index JSON with `{ luanil = { object = true, array = true } }`. Without it, a JSON `null` becomes `vim.NIL`, which is truthy.
- The indexer runs with the repo's own `typescript` package. Do not bundle TypeScript. See [ADR 0003](docs/adr/0003-bff-indexer-typescript-compiler-api.md).

### Docs

- Write README text, ADRs and `CONTEXT.md` in ASD-STE100 Simplified Technical English.
- Record each new design decision as an ADR in `docs/adr/` (next free number, same template).
- Add new terms to `CONTEXT.md`.

## Tests

There is no test framework. Use headless Neovim and small scripts:

```sh
nvim --headless "+Lazy! load bff-links" +qa          # load test, no errors expected
node --check lua/tools/bff/indexer.cjs                # indexer syntax
git check-ignore -v bff-links.local.json              # the local config is ignored
```

To test the indexer, make a small TypeScript project in a temp folder and run:

```sh
NODE_PATH=<folder with node_modules/typescript> \
  node lua/tools/bff/indexer.cjs <project-root> '{"dir":".","frameworks":["express"],"source":["src"],"fetch":true}'
```

The output JSON has `routes`, `callsites`, `ops`, `nodes`, `nodeRoutes`, `opRoutes` and `specs`.

To test Lua modules headless:

```sh
nvim --headless -u NONE --cmd "set rtp^=$HOME/.config/nvim" -l test.lua
```

## Commits and PRs

- Conventional commit subjects (`feat:`, `fix:`, `docs:`).
- Commit only when the user asks.
