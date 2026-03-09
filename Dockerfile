FROM node:22-bookworm

WORKDIR /app

RUN npm install openclaw@latest --omit=dev --no-audit --no-fund

ENV NODE_OPTIONS="--max-old-space-size=350"
ENV PATH="/app/node_modules/.bin:$PATH"

COPY scripts/ ./scripts/

RUN sed -i 's/\r$//' ./scripts/bootstrap.sh && chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "/app/scripts/bootstrap.sh"]
