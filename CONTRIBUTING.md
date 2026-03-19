# Contributing

## Development setup

```bash
git clone https://github.com/janpaepke/haunt.git
cd haunt
./install.sh   # symlinks to ~/.local/bin when run from the repo
```

## Releasing

1. Update `VERSION` in `haunt`
2. Commit: `git commit -am "release: vX.Y.Z"`
3. Push: `git push`
4. Release (creates tag automatically): `gh release create vX.Y.Z --generate-notes`
5. Fetch the new tag: `git fetch --tags origin`
