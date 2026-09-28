# AS ONE API — image production (Render / Docker)
# Debian slim évite les erreurs OpenSSL/Alpine avec Prisma

FROM node:20-bookworm-slim AS builder

WORKDIR /app

RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npx prisma generate

COPY . .
RUN npm run build

# --- production ---
FROM node:20-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production

RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
COPY prisma ./prisma/

# prisma CLI nécessaire pour db push au démarrage
RUN npm ci --omit=dev && npm install prisma@5.22.0 --no-save && npx prisma generate

COPY --from=builder /app/dist ./dist
RUN mkdir -p uploads

EXPOSE 3000

# Création du schéma sur Supabase puis lancement de l'API
CMD ["sh", "-c", "npx prisma db push --accept-data-loss && node dist/main"]
