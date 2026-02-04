---
summary: 'Copy/paste CLI smoke checklist for local verification.'
read_when:
  - Pre-merge validation
  - Reproducing a reported CLI bug
---

# Manual testing (CLI)

## Setup
- Ensure logged in: `bun clawdsquad whoami` (or `bun clawdsquad login`).
- Optional: set env
  - `MOLTHUB_SITE=https://clawdsquad.com`
  - `MOLTHUB_REGISTRY=https://clawdsquad.com`

## Smoke
- `bun clawdsquad --help`
- `bun clawdsquad --cli-version`
- `bun clawdsquad whoami`

## Search
- `bun clawdsquad search gif --limit 5`

## Install / list / update
- `mkdir -p /tmp/clawdsquad-manual && cd /tmp/clawdsquad-manual`
- `bunx clawdsquad@beta install gifgrep --force`
- `bunx clawdsquad@beta list`
- `bunx clawdsquad@beta update gifgrep --force`

## Publish (changelog optional)
- `mkdir -p /tmp/clawdsquad-skill-demo/SKILL && cd /tmp/clawdsquad-skill-demo`
- Create files:
  - `SKILL.md`
  - `notes.md`
- Publish:
  - `bun clawdsquad publish . --slug clawdsquad-manual-<ts> --name "Manual <ts>" --version 1.0.0 --tags latest`
- Publish update with empty changelog:
  - `bun clawdsquad publish . --slug clawdsquad-manual-<ts> --name "Manual <ts>" --version 1.0.1 --tags latest`

## Delete / undelete (owner/admin)
- `bun clawdsquad delete clawdsquad-manual-<ts> --yes`
- Verify hidden:
- `curl -i "https://clawdsquad.com/api/v1/skills/clawdsquad-manual-<ts>"`
- Restore:
  - `bun clawdsquad undelete clawdsquad-manual-<ts> --yes`
- Cleanup:
  - `bun clawdsquad delete clawdsquad-manual-<ts> --yes`

## Sync
- `bun clawdsquad sync --dry-run --all`

## Playwright (menu smoke)

Run against prod:

```
PLAYWRIGHT_BASE_URL=https://clawdsquad.com bun run test:pw
```

Run against a local preview server:

```
bun run test:e2e:local
```
