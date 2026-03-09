FROM node:22-bookworm-slim
	
WORKDIR /app
	
# --ignore-scripts skips postinstall builds for native modules (sharp, node-pty,
# sqlite-vec) that are not needed for a Telegram text bot. Eliminates exit 254.
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/* \
    && git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ \
    && git config --global --add url."https://github.com/".insteadOf "git@github.com:"

RUN npm install openclaw@latest \
      --ignore-scripts \
      --omit=dev \
      --no-audit \
      --no-fund
	
ENV NODE_OPTIONS="--max-old-space-size=350"
ENV PATH="/app/node_modules/.bin:$PATH"
	
# Runtime config generator
COPY scripts/ ./scripts/
RUN chmod +x ./scripts/bootstrap.sh
	
# Skills plug-and-play mount point.
# To add a feature: create skills/<n>/SKILL.md in this repo and push.
# No changes to Dockerfile, railway.toml, or bootstrap.sh ever needed.
COPY skills/ ./skills/
	
EXPOSE 8080
CMD ["sh", "/app/scripts/bootstrap.sh"]
