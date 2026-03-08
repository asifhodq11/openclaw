FROM node:22-bookworm

WORKDIR /app

# Local install is often more stable in constrained build environments
RUN npm install openclaw@latest --omit=dev --no-audit --no-fund

ENV NODE_OPTIONS="--max-old-space-size=350"
ENV PATH="/app/node_modules/.bin:$PATH"

COPY scripts/ ./scripts/
RUN chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "scripts/bootstrap.sh"]
