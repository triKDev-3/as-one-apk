# AS ONE API — production
# v4 — npm install only (lock désync OK)

FROM node:20-bookworm-slim AS builder

WORKDIR /app

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl ca-certificates python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package.json ./
COPY package-lock.json* ./
COPY prisma ./prisma/
COPY nest-cli.json tsconfig.json tsconfig.build.json ./

# Toujours npm install (évite "Missing X from lock file")
RUN npm install

RUN npx prisma generate

COPY src ./src
RUN npx nest build \
  && echo "=== dist layout ===" \
  && find dist -type f -name "*.js" | head -40 \
  && (test -f dist/main.js || test -f dist/src/main.js)

FROM node:20-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY package.json ./
COPY package-lock.json* ./
COPY prisma ./prisma/

RUN npm install --omit=dev \
  && npm install prisma@5.22.0 --no-save \
  && npx prisma generate

COPY --from=builder /app/dist ./dist

RUN mkdir -p uploads \
  && (test -f dist/main.js || test -f dist/src/main.js)

EXPOSE 3000

CMD ["sh", "-c", "npx prisma db push --accept-data-loss && if [ -f dist/main.js ]; then node dist/main.js; else node dist/src/main.js; fi"]
