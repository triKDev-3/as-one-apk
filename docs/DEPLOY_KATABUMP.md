# Déploiement API AS ONE sur Katabump

## Prérequis

- Compte Katabump
- Base PostgreSQL (Katabump managed ou externe)
- Repo backend poussé (ou upload du dossier `backend/`)

## Variables d'environnement

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/asone?schema=public
JWT_SECRET=change-me-long-random-string
JWT_EXPIRES_IN=7d
PORT=3000
NODE_ENV=production
```

## Étapes

1. **Build**
   ```bash
   cd backend
   npm ci
   npx prisma generate
   npm run build
   ```

2. **Migrations**
   ```bash
   npx prisma migrate deploy
   # optionnel seed
   npm run seed
   ```

3. **Start**
   ```bash
   npm run start:prod
   # → node dist/main
   ```

4. **Health check**  
   `GET https://votre-api.katabump.com/` ou endpoint auth.

## Socket.io

- Namespace : `/realtime`
- Clients Flutter se connectent avec `query.userId`
- Katabump doit autoriser les **WebSockets** (généralement activé par défaut)

## Flutter — URL API production

```bash
flutter run --dart-define=API_BASE_URL=https://votre-api.katabump.com
# ou build
flutter build apk --dart-define=API_BASE_URL=https://votre-api.katabump.com
flutter build ios --dart-define=API_BASE_URL=https://votre-api.katabump.com
flutter build web --dart-define=API_BASE_URL=https://votre-api.katabump.com
```

## Checklist production

- [ ] `JWT_SECRET` fort et unique
- [ ] HTTPS uniquement
- [ ] CORS limité aux domaines de l'app si besoin
- [ ] Backups PostgreSQL
- [ ] Logs / monitoring Katabump
- [ ] Seed **désactivé** en prod après le premier admin créé

## Structure process Katabump (exemple)

```
Start command: node dist/main
Build command: npm ci && npx prisma generate && npm run build
```
