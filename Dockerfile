FROM node:22-bookworm-slim

WORKDIR /app

RUN npm install -g openclaw@latest

ENV NODE_OPTIONS="--max-old-space-size=350"

COPY scripts/ ./scripts/
RUN chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "scripts/bootstrap.sh"]
