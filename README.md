# ClawdSquad

<p align="center">
  <a href="https://github.com/clawdsquad/registry/actions/workflows/ci.yml?branch=main"><img src="https://img.shields.io/github/actions/workflow/status/clawdsquad/registry/ci.yml?branch=main&style=for-the-badge" alt="CI status"></a>
</p>

ClawdSquad is the **public agent registry for Clawdbot**: publish, version, and search complete AI agents (with SOUL.md, USER.md, skills, memory, and configuration).
It's designed for fast browsing + a CLI-friendly API, with moderation hooks and vector search.

Live: `https://clawdsquad.com`

## What you can do

- Browse agents + render their SOUL.md and README.
- Publish new agent versions with changelogs + tags (including `latest`).
- Search via embeddings (vector index) instead of brittle keywords.
- Install agents to your Clawdbot workspace with one command.
- Star + comment; admins/mods can curate and approve agents.

## Agent Structure

A ClawdSquad agent includes:
- `SOUL.md` - Persona and voice
- `USER.md` - User preferences  
- `SKILL.md` - Skills reference
- `AGENTS.md` - Agent behavior
- `memory/` - Persistent memory
- `config/` - Configuration files
- `skills/` - Nested skills

## CLI Commands

```bash
clawdsquad search "trading"        # Search agents
clawdsquad install trading-master  # Install agent
clawdsquad list                    # List installed agents
clawdsquad publish ./my-agent      # Publish agent
```
- Soul bundles only accept `SOUL.md` for now (no extra files).

## How it works (high level)

- Web app: TanStack Start (React, Vite/Nitro).
- Backend: Convex (DB + file storage + HTTP actions) + Convex Auth (GitHub OAuth).
- Search: OpenAI embeddings (`text-embedding-3-small`) + Convex vector search.
- API schema + routes: `packages/schema` (`clawdsquad-schema`).

## Telemetry

ClawdSquad tracks minimal **install telemetry** (to compute install counts) when you run `clawdsquad sync` while logged in.
Disable via:

```bash
export MOLTHUB_DISABLE_TELEMETRY=1
```

Details: `docs/telemetry.md`.

## Repo layout

- `src/` — TanStack Start app (routes, components, styles).
- `convex/` — schema + queries/mutations/actions + HTTP API routes.
- `packages/schema/` — shared API types/routes for the CLI and app.
- `docs/spec.md` — product + implementation spec (good first read).

## Local dev

Prereqs: Bun + Convex CLI.

```bash
bun install
cp .env.local.example .env.local

# terminal A: web app
bun run dev

# terminal B: Convex dev deployment
bunx convex dev
```

## Auth (GitHub OAuth) setup

Create a GitHub OAuth App, set `AUTH_GITHUB_ID` / `AUTH_GITHUB_SECRET`, then:

```bash
bunx auth --deployment-name <deployment> --web-server-url http://localhost:3000
```

This writes `JWT_PRIVATE_KEY` + `JWKS` to the deployment and prints values for your local `.env.local`.

## Environment

- `VITE_CONVEX_URL`: Convex deployment URL (`https://<deployment>.convex.cloud`).
- `VITE_CONVEX_SITE_URL`: Convex site URL (`https://<deployment>.convex.site`).
- `VITE_SOULHUB_SITE_URL`: onlycrabs.ai site URL (`https://onlycrabs.ai`).
- `VITE_SOULHUB_HOST`: onlycrabs.ai host match (`onlycrabs.ai`).
- `VITE_SITE_MODE`: Optional override (`skills` or `souls`) for SSR builds.
- `CONVEX_SITE_URL`: same as `VITE_CONVEX_SITE_URL` (auth + cookies).
- `SITE_URL`: App URL (local: `http://localhost:3000`).
- `AUTH_GITHUB_ID` / `AUTH_GITHUB_SECRET`: GitHub OAuth App.
- `JWT_PRIVATE_KEY` / `JWKS`: Convex Auth keys.
- `OPENAI_API_KEY`: embeddings for search + indexing.

## Nix plugins (nixmode skills)

ClawdSquad can store a nix-moltbot plugin pointer in SKILL frontmatter so the registry knows which
Nix package bundle to install. A nix plugin is different from a regular skill pack: it bundles the
skill pack, the CLI binary, and its config flags/requirements together.

Add this to `SKILL.md`:

```yaml
---
name: peekaboo
description: Capture and automate macOS UI with the Peekaboo CLI.
metadata: {"moltbot":{"nix":{"plugin":"github:moltbot/nix-steipete-tools?dir=tools/peekaboo","systems":["aarch64-darwin"]}}}
---
```

Install via nix-moltbot:

```nix
programs.moltbot.plugins = [
  { source = "github:moltbot/nix-steipete-tools?dir=tools/peekaboo"; }
];
```

You can also declare config requirements + an example snippet:

```yaml
---
name: padel
description: Check padel court availability and manage bookings via Playtomic.
metadata: {"moltbot":{"config":{"requiredEnv":["PADEL_AUTH_FILE"],"stateDirs":[".config/padel"],"example":"config = { env = { PADEL_AUTH_FILE = \\\"/run/agenix/padel-auth\\\"; }; };"}}}
---
```

To show CLI help (recommended for nix plugins), include the `cli --help` output:

```yaml
---
name: padel
description: Check padel court availability and manage bookings via Playtomic.
metadata: {"moltbot":{"cliHelp":"padel --help\\nUsage: padel [command]\\n"}}
---
```

`metadata.moltbot` is preferred, but `metadata.moltbot` is accepted as an alias for compatibility.

## Scripts

```bash
bun run dev
bun run build
bun run test
bun run coverage
bun run lint
```
