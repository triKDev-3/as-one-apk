# Déploiement gratuit — API AS ONE (sans PC)

Stack recommandée :

| Service | Rôle | Coût |
|---------|------|------|
| **Supabase** | Base PostgreSQL | Gratuit |
| **Render** | API NestJS 24/7 (s’endort ~15 min d’inactivité) | Gratuit |
| **GitHub Actions** | Build APK | Gratuit |

---

## Étape 1 — Supabase (base)

1. Va sur https://supabase.com → compte → **New project**
2. Note le **mot de passe** de la base
3. **Project Settings → Database → Connection string → URI**
4. Copie l’URI (mode **Session** ou **Direct**)

Exemple :

```text
postgresql://postgres.XXXX:MOT_DE_PASSE@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

> Le schéma Prisma du repo est configuré en **`postgresql`** pour Supabase.

---

## Étape 2 — Render (API)

1. https://render.com → compte avec **GitHub**
2. **New → Web Service**
3. Connecte le repo `triKDev-3/as-one-apk`
4. Réglages :

| Champ | Valeur |
|-------|--------|
| **Name** | `asone-api` |
| **Root Directory** | `backend` |
| **Runtime** | Node |
| **Build Command** | `npm ci && npx prisma generate && npm run build` |
| **Start Command** | `npx prisma migrate deploy && node dist/main` |
| **Instance** | Free |

5. **Environment Variables** :

```env
DATABASE_URL=<URI Supabase collée ici>
JWT_SECRET=<longue phrase secrète au hasard>
NODE_ENV=production
PORT=10000
```

> Render injecte souvent `PORT` automatiquement. Si le start échoue, laisse `PORT` vide ou utilise la valeur fournie par Render.

6. **Create Web Service** → attends **Live** (5–10 min)
7. URL du type : `https://asone-api-xxxx.onrender.com`

### Seed (comptes de test) — une seule fois

Dans Render → ton service → **Shell** (si dispo) ou ajoute temporairement au Start :

```bash
npx prisma migrate deploy && npx ts-node prisma/seed.ts && node dist/main
```

Puis **remets** le Start sans seed après le 1er lancement réussi.

Comptes : mot de passe `asone123` — Admin `+22890000001`

---

## Étape 3 — Tester l’API sur le téléphone

Dans Chrome mobile :

```text
https://asone-api-xxxx.onrender.com
```

Si la page répond ou que les logs Render montrent `AS ONE API running` → OK.

> 1er appel après sommeil : 30–60 s de patience.

---

## Étape 4 — Connecter l’APK

1. https://github.com/triKDev-3/as-one-apk/actions
2. **Build APK AS ONE** → **Run workflow**
3. **api_base_url** = `https://asone-api-xxxx.onrender.com` (sans `/` final)
4. Télécharge l’artifact → installe

---

## Checklist

- [ ] Projet Supabase créé
- [ ] `DATABASE_URL` collée dans Render
- [ ] Service Render **Live**
- [ ] Seed exécuté une fois
- [ ] APK rebuild avec la bonne URL
- [ ] Login test OK

---

## Problèmes fréquents

| Erreur | Solution |
|--------|----------|
| `P1001` / can't reach database | Vérifie l’URI Supabase ; autorise les connexions (pas de restriction IP stricte) |
| OOM / crash | Baileys WhatsApp est lourd ; désactive temporairement le module WhatsApp si besoin |
| Timeout téléphone | Réveille l’API en ouvrant l’URL dans Chrome avant de lancer l’app |
| Migrations fail | Utilise la connexion **Direct** (port 5432) pour `migrate deploy` |
