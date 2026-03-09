FROM node:22-bookworm-slim

WORKDIR /app

# No build-time install to avoid exit code 254
ENV NODE_OPTIONS="--max-old-space-size=350"
ENV PATH="/app/node_modules/.bin:$PATH"

COPY scripts/ ./scripts/
RUN sed -i 's/\r$//' ./scripts/bootstrap.sh && chmod +x ./scripts/bootstrap.sh

EXPOSE 8080
CMD ["sh", "/app/scripts/bootstrap.sh"]
