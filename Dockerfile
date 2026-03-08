FROM node:22-bookworm

WORKDIR /app

# Local install is more stable in constrained build environments
RUN npm install openclaw@latest --omit=dev --no-audit --no-fund

ENV NODE_OPTIONS="--max-old-space-size=350"
ENV PATH="/app/node_modules/.bin:$PATH"

COPY scripts/ ./scripts/

# Fix line endings (CRLF -> LF) to ensure shebang works on Linux
RUN apt-get update && apt-get install -y sed && \
    sed -i 's/\r$//' ./scripts/bootstrap.sh && \
    chmod +x ./scripts/bootstrap.sh && \
    apt-get purge -y sed && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
CMD ["sh", "/app/scripts/bootstrap.sh"]
