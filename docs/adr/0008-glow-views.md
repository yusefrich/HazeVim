# 8. Glow views: start screen, mirror, and ANSI-parsed file view

- Status: Accepted
- Date: 2026-11-22

## Context

The glow pager cannot scroll to the left (`h` means "back"). glow uses the `.gitignore` of the first parent with a `.git` folder, so it lists 0 files for a nested ignored worktree.

## Decision

- Start screen (`<leader>cg`): run glow in a full-screen terminal float. For a nested ignored worktree, run it in a mirror folder in the cache with hard links to the Markdown files that git shows.
- File view (`<leader>cG`): run `glow -` with the buffer text, parse the ANSI output, and put the text in a normal buffer with extmark highlights. Lines do not wrap, so normal motions, horizontal scroll, search and copy work. Wide mode removes the squeeze of tables and code.
- Preview (`:GlowPreview`): ANSI output into a terminal buffer from `nvim_open_term`.
- Each render has a generation counter. Only the newest render draws.

## Consequences

- No external plugin.
- The file view supports only the ANSI codes that glow writes (SGR colours and styles).
