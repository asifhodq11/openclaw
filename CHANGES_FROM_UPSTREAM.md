# Changes From Upstream (openclaw/openclaw)

> Track record of every change made in `railway-edition` vs `openclaw/openclaw:main`.
> Use this file when syncing future upstream updates.

## How to Sync Future Upstream Updates

```bash
# 1. Fetch latest upstream changes
git fetch upstream

# 2. Merge into railway-edition (NOT into main — keep main as clean mirror)
git checkout railway-edition
git merge upstream/main

# 3. Review ONLY the files listed below — those are the ones with conflicts
# 4. Run build to verify: pnpm install && pnpm build
# 5. Push
```

> [!IMPORTANT]
> **Never auto-merge upstream into railway-edition.** Always review the files listed below manually after any merge.

---

## Modified Files

| File | What We Changed | Flaw Fixed | Review on Sync |
|------|----------------|-----------|---------------|
| `Dockerfile` | 2-stage build, removed Bun, removed A2UI, added scripts/ COPY | D-03, D-04 | YES — upstream may add new COPY stages |
| `package.json` | Removed native app workspace references | D-03 | YES — upstream may add new workspaces |

---

## New Files (upstream will never have these — safe to keep after sync)

| File | Purpose |
|------|---------|
| `scripts/bootstrap.sh` | Env-var → openclaw.json generator. Eliminates wizard. |
| `scripts/merge-overlay.js` | Deep-merge JSON for Android config overlay |
| `scripts/android-setup.sh` | DORMANT. Android/Termux one-time setup. Zero Railway impact. |
| `railway.toml` | Railway-native deploy config |
| `.env.railway.example` | Env var reference with all providers documented |
| `CHANGES_FROM_UPSTREAM.md` | This file |
| `DEPLOY_RAILWAY.md` | 5-step Railway deploy guide |

---

## Deleted Directories (DO NOT restore on upstream sync)

| Directory | Why Deleted |
|-----------|------------|
| `apps/macos/` | macOS Swift companion app — irrelevant on server |
| `apps/ios/` | iOS app — irrelevant on server |
| `apps/android/` | Android native app — irrelevant (we use Termux approach instead) |
| `apps/shared/OpenClawKit/` | Swift/Kotlin shared libs — only for native apps |
| `extensions/bluebubbles/` | macOS-only iMessage bridge |
| `vendor/a2ui/` | Canvas visual workspace bundle — biggest build bottleneck |

> [!CAUTION]
> If upstream sync restores any of these directories, delete them again immediately. They will add 1GB+ to the Docker build and cause OOM on Railway.

---

## Known Upstream Flaws We Fixed Differently

| Flaw ID | Upstream Behavior | Our Fix |
|---------|------------------|---------|
| D-01 | Interactive wizard required on first boot | `bootstrap.sh` generates config from env vars |
| D-03 | Build requires 2GB+ RAM (OOM on Railway) | Stripped Dockerfile: ~800MB |
| D-06 | `allowedOrigins` crash on PaaS | Set via `$RAILWAY_STATIC_URL` in bootstrap |
| M-02 | `memoryFlush: false` by default | Set to `true` in generated config |
| M-03 | ENOENT crash on fresh container | `mkdir -p` + `touch` in bootstrap |
| SEC-01 | Config in plaintext | `chmod 600` in bootstrap |
| SEC-03 | DM open to all users | `allowFrom` + `directPolicy: allowlist` in bootstrap |
| A-03 | Telegram long-polling crashes every 20-30min | Webhook mode auto-configured when `$RAILWAY_STATIC_URL` set |

---

*Created: 2026-03-08 | Branch: railway-edition | Upstream: openclaw/openclaw main*
