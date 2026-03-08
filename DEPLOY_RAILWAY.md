# DEPLOY_RAILWAY.md

Follow these 5 steps to deploy OpenClaw Railway Edition. No setup wizard, just environment variables.

1. **Fork this repo** into your own GitHub account.
2. **Deploy on Railway:**
   - Go to Railway.com → New → Deploy from GitHub repo.
   - Select your fork.
   - **CRITICAL:** Ensure the deployment branch is set to `railway-edition`, not main.
3. **Set Environment Variables:**
   - Go to your service's **Variables** tab.
   - Add all keys provided in `.env.railway.example` (TELEGRAM_BOT_TOKEN, API keys, etc.).
   - Make sure to set `OPENCLAW_GATEWAY_TOKEN` to a secure string.
4. **Add Persistent Storage:**
   - Go to the **Volumes** tab in your service.
   - Add a 1GB volume and mount it exactly at `/data`.
   - *This ensures your history and Smart Router state survives redeploys.*
5. **Verify the Deployment:**
   - Watch the deploy logs for: `[gateway] listening on 0.0.0.0`
   - Send `Hello` to the Telegram bot.
   - Test failovers and the `/status` command.

### Warnings:
- ⚠️ **Never enable `gateway.tls.enabled: true`** — This breaks all CLI access permanently (an upstream bug).
- ⚠️ **Never add custom keys to `openclaw.json`** — The `openclaw doctor --fix` command silently deletes unknown keys.
- ⚠️ **ClawHub skill registry has a rate limit on free tier** — Do not auto-install skills on every boot.
