# Déploiement gratuit — API AS ONE (sans PC)

> **KataBump** = bots Discord uniquement → **ne convient pas** à cette API.
> Stack : **Supabase** (PostgreSQL) + **Render** (NestJS).

---

## Étape 1 — Supabase

1. https://supabase.com → **New project**
2. Note le mot de passe DB
3. **Settings → Database → Connection string → URI**
4. Copie l’URI (Session pooler ou Direct)

```text
postgresql://postgres.XXXX:MOT_DE_PASSE@....pooler.supabase.com:5432/postgres
```

---

## Étape 2 — Render

1. https://render.com → login GitHub
2. **New → Web Service** → repo `triKDev-3/as-one-apk`
3. Réglages :

| Champ | Valeur |
|-------|--------|
| Name | `asone-api` |
| Root Directory | `backend` |
| Build Command | `npm ci && npx prisma generate && npm run build` |
| Start Command | `npx prisma db push --accept-data-loss && node dist/main` |
| Plan | **Free** |

4. Variables d’environnement :

| Key | Value |
|-----|--------|
| `DATABASE_URL` | URI Supabase |
| `JWT_SECRET` | longue phrase secrète |
| `NODE_ENV` | `production` |

5. **Create** → attendre **Live**
6. URL : `https://asone-api-xxxx.onrender.com`

### Seed (une fois)

Quand l’API est Live, dans les logs tu dois voir `AS ONE API running`.

Pour créer les comptes de test, le plus simple sans Shell :
- ouvre un ticket / dis-moi l’URL Live → on peut ajouter un endpoint admin seed temporaire, **ou**
- sur Render **Shell** (si disponible) :
  ```bash
  npx ts-node prisma/seed.ts
  ```

Comptes seed : mot de passe **`asone123`** — Admin **`+22890000001`**

---

## Étape 3 — APK

1. https://github.com/triKDev-3/as-one-apk/actions
2. **Build APK AS ONE** → **Run workflow**
3. `api_base_url` = `https://asone-api-xxxx.onrender.com`
4. Installe le nouvel APK

Avant le login : ouvre l’URL API dans Chrome (réveille Render Free, ~30–60 s).

---

## Checklist

- [ ] Supabase créé + URI copiée
- [ ] Render Live
- [ ] Seed OK
- [ ] APK rebuild avec la bonne URL
- [ ] Login test
