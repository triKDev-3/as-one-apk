# AS ONE API — production (Render)
# v3 — npm install fallback si package-lock désynchronisé (ms@ missing)

FROM node:20-bookworm-slim AS builder

WORKDIR /app

RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
COPY prisma ./prisma/
COPY nest-cli.json tsconfig.json tsconfig.build.json ./

# npm ci échoue si lock incomplet → fallback npm install
RUN npm ci || (echo "WARN: npm ci failed, falling back to npm install" && npm install)

RUN npx prisma generate

COPY src ./src
RUN npx nest build \
  && echo "=== dist layout ===" \
  && find dist -type f -name "*.js" | head -50 \
  && (test -f dist/main.js || test -f dist/src/main.js)

# --- production ---
FROM node:20-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production

RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
COPY prisma ./prisma/

RUN (npm ci --omit=dev || npm install --omit=dev) \
  && npm install prisma@5.22.0 --no-save \
  && npx prisma generate

COPY --from=builder /app/dist ./dist

RUN mkdir -p uploads \
  && echo "=== runtime dist ===" \
  && find dist -type f -name "*.js" | head -20 \
  && (test -f dist/main.js || test -f dist/src/main.js)

EXPOSE 3000

CMD ["sh", "-c", "npx prisma db push --accept-data-loss && if [ -f dist/main.js ]; then node dist/main.js; else node dist/src/main.js; fi"]
