FROM node:22-bookworm-slim

WORKDIR /app

# Use ultra-safe flags for memory-constrained builds.
# --no-bin-links and --no-scripts reduce peak memory and IO during install.
RUN NODE_OPTIONS="--max-old-space-size=1536" npm install openclaw@latest \
    --omit=dev \
    --no-audit \
    --no-fund \
    --no-bin-links \
    --no-scripts

ENV NODE_OPTIONS="--max-old-space-size=350"

# Since we used --no-bin-links, we must link the binary manually
RUN ln -s /app/node_modules/openclaw/openclaw.mjs /usr/local/bin/openclaw && \
    chmod +x /app/node_modules/openclaw/openclaw.mjs

ENV PATH="/app/node_modules/.bin:$PATH"

COPY scripts/ ./scripts/

RUN sed -i 's/\r$//' ./scripts/bootstrap.sh && chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "/app/scripts/bootstrap.sh"]
