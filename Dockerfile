FROM node:22-bookworm-slim

WORKDIR /app

# Use pnpm for global install as it's more memory efficient
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm add -g openclaw@latest

ENV NODE_OPTIONS="--max-old-space-size=350"

COPY scripts/ ./scripts/
RUN chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "scripts/bootstrap.sh"]
