# Contributing

## Development setup

```bash
git clone https://github.com/janpaepke/haunt.git
cd haunt
./install.sh   # symlinks to ~/.local/bin when run from the repo
```

## Project structure

```
haunt              # main script — tab switching, fzf UI, hook orchestration
install.sh         # installer (symlinks locally, downloads tarball remotely)
test.sh            # integration tests
hooks/             # bundled hook plugins
  claude-status/   # Claude Code status indicators
    decorate       # adds working/attention indicators based on tab/terminal name
    on-focus       # clears attention when a tab is focused
    on-start       # resets state files on haunt startup
    on-stop        # cleans up state files on haunt exit
```

## Hooks architecture

Hooks are the extension mechanism for haunt. Each hook is a directory under `hooks/` containing executable scripts that haunt calls at specific lifecycle points:

| Hook | When | Input | Purpose |
|------|------|-------|---------|
| `decorate` | Each refresh | `tabId\ttabName\ttermName\tfocused` on stdin | Output `tabId\tindicator` lines to add indicators |
| `attention` | `--next` command | (none) | Output tab IDs that need attention (one per line) |
| `on-focus` | Tab selected | `<tab_id>` as arg | React to tab focus (e.g. clear notifications) |
| `on-start` | haunt launches | (none) | Initialize state |
| `on-stop` | haunt exits | (none) | Clean up state |

All bundled hooks are enabled by default. Users can override this in `~/.config/haunt/config`:

```bash
HOOKS="claude-status"    # enable specific hooks
HOOKS=""                 # disable all hooks
```

### Writing a hook

1. Create a directory under `hooks/` with your hook name
2. Add any of the lifecycle scripts above (must be executable)
3. Hooks manage their own state files (use `$TMPDIR` for temp data)
4. Decorator output uses ANSI escape codes for styling

## Tests

```bash
./test.sh
```

Tests cover: help/version output, hook discovery, shellcheck, and hook logic (state transitions, indicator output). Run tests before submitting PRs.

## Releasing

1. Update `VERSION` in `haunt`
2. Commit: `git commit -am "release: vX.Y.Z"`
3. Push: `git push`
4. Release (creates tag automatically): `gh release create vX.Y.Z --generate-notes`
5. Fetch the new tag: `git fetch --tags origin`
