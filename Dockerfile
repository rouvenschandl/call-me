# Build stage
FROM oven/bun:1.3.11-alpine AS builder

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun run build && \
    bunx tsc server.ts --outDir dist-server --module ESNext --moduleResolution bundler --target ES2020 --esModuleInterop

# Server stage
FROM oven/bun:1.3.11-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/dist-server/server.js ./server.js
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/bun.lock ./bun.lock

RUN bun install --frozen-lockfile --production

EXPOSE 3000
ENV NODE_ENV=production

CMD ["bun", "server.js"]
