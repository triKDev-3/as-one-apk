# Pourquoi pas KataBump pour l’API AS ONE ?

**KataBump** est une plateforme d’hébergement de **bots Discord** (Node.js / Python), pas un hébergeur d’API web mobile.

| Besoin AS ONE | KataBump Free |
|---------------|---------------|
| URL HTTP publique pour le téléphone | Non documenté / non conçu pour ça |
| PostgreSQL ou MySQL | Free = SQLite seulement ; MariaDB = payant |
| RAM NestJS + Prisma + Socket.io | **308 MB** (souvent insuffisant) |
| Disque `node_modules` | **716 MB** (limite vite atteinte) |
| Renouvellement | Tous les **4 jours** sur le free |

→ **Ne pas déployer l’API AS ONE sur KataBump.**

Utilise plutôt la stack gratuite : **[DEPLOY_FREE.md](./DEPLOY_FREE.md)** (Supabase + Render).
