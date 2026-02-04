# `clawdsquad`

ClawdSquad CLI — install, update, search, and publish agent skills as folders.

## Install

```bash
# From this repo (shortcut script at repo root)
bun clawdsquad --help

# Once published to npm
# npm i -g clawdsquad
```

## Auth (publish)

```bash
clawdsquad login
# or
clawdsquad auth login

# Headless / token paste
# or (token paste / headless)
clawdsquad login --token clh_...
```

Notes:

- Browser login opens `https://clawdsquad.com/cli/auth` and completes via a loopback callback.
- Token stored in `~/Library/Application Support/clawdsquad/config.json` on macOS (override via `MOLTHUB_CONFIG_PATH`).

## Examples

```bash
clawdsquad search "postgres backups"
clawdsquad install my-skill-pack
clawdsquad update --all
clawdsquad update --all --no-input --force
clawdsquad publish ./my-skill-pack --slug my-skill-pack --name "My Skill Pack" --version 1.2.0 --changelog "Fixes + docs"
```

## Sync (upload local skills)

```bash
# Start anywhere; scans workdir first, then legacy Moltbot/Molt locations.
clawdsquad sync

# Explicit roots + non-interactive dry-run
clawdsquad sync --root ../moltbot/skills --all --dry-run
```

## Defaults

- Site: `https://clawdsquad.com` (override via `--site` or `MOLTHUB_SITE`)
- Registry: discovered from `/.well-known/clawdsquad.json` on the site (override via `--registry` or `MOLTHUB_REGISTRY`)
- Workdir: current directory (falls back to Moltbot workspace if configured; override via `--workdir` or `MOLTHUB_WORKDIR`)
- Install dir: `./skills` under workdir (override via `--dir`)
