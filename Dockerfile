# Build stage
FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY . .
RUN pnpm run build && \
    npx tsc server.ts --outDir dist-server --module ESNext --moduleResolution bundler --target ES2020 --esModuleInterop

# Server stage
FROM node:24-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/dist-server ./dist-server
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml

RUN npm install -g pnpm && \
    pnpm install --prod

EXPOSE 3000

CMD ["node", "dist-server/server.js"]
