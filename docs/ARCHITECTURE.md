# AS ONE — Architecture Technique

**Version** : 1.0  
**Date** : Août 2026  
**Objectif** : Application multi-plateforme (Android / iOS / Web / Desktop) pour la gestion des équipes, du matériel et de la paie.

---

## 1. Stack retenue

| Couche              | Technologie                          | Justification |
|---------------------|--------------------------------------|-------------|
| Frontend            | Flutter 3.x                          | Un seul codebase → Android, iOS, Web, Windows, macOS, Linux. Performance native. |
| State management    | Riverpod                             | Simple, testable, performant |
| Backend             | NestJS 10 + TypeScript               | Architecture modulaire, typage fort, excellent pour les règles métier complexes |
| ORM                 | Prisma 5                             | Migrations claires, typage excellent, performances |
| Base de données     | PostgreSQL 16                        | Fiabilité, transactions, index avancés |
| Auth                | JWT + Refresh Token + RBAC           | Sécurité fine par rôle |
| Temps réel          | Socket.io                            | Notifications affectation / pointage |
| Stockage photos     | Cloudinary (ou S3 compatible)        | Hors de Katabump (limites de stockage) |
| Cache / Queue       | Redis (optionnel au début)           | Classement, sessions, jobs de paie |
| Hébergement API     | Katabump (démarrage) → Railway/Fly.io | Passage progressif selon la charge |

---

## 2. Principes de design & performance

- **Mobile-first** : tous les écrans sont pensés d’abord pour smartphone.
- **Rôles stricts** : aucun endpoint n’est accessible sans le bon rôle.
- **Verrouillage optimiste** sur les agents (attribution).
- **Pré-calcul** de la paie sur intervalle (pas de calcul à la volée massif).
- **Photos** compressées côté client avant upload.
- **Index** sur : `disponibility`, `assignment.agentId + siteId + date`, `pointage`.
- **Pas d’auto-inscription**.

---

## 3. Structure monorepo

```
asone-app/
├── backend/                 # NestJS API
│   ├── src/
│   │   ├── modules/         # auth, users, sites, assignments, pointages, material, payroll...
│   │   ├── common/          # guards, decorators, filters
│   │   ├── prisma/
│   │   └── main.ts
│   ├── prisma/schema.prisma
│   └── package.json
├── frontend/                # Flutter
│   ├── lib/
│   │   ├── core/            # theme, router, network
│   │   ├── features/        # auth, agent, chef, magasinier, comptable, admin
│   │   └── main.dart
│   └── pubspec.yaml
├── shared/                  # Types / DTOs partagés (optionnel)
└── docs/
```

---

## 4. Rôles (RBAC)

```
ADMIN
COMPTABLE
CHEF
MAGASINIER
AGENT
```

Un utilisateur ne peut avoir **qu’un seul rôle** actif (simplifie les permissions).

---

## 5. Flux critiques prioritaires

1. Auth + création manuelle des comptes (Admin)
2. Disponibilité Agent (gros bouton + règle 22h)
3. Attribution d’équipe par le Chef (verrouillage + transfert)
4. Pointage (photo optionnelle)
5. Sortie / retour matériel + retenues
6. Calcul & simulation de paie
7. Classement (moyenne des notes)

---

## 6. Couleurs officielles (brand)

| Nom              | HEX       | Usage |
|------------------|-----------|-------|
| Bleu foncé       | `#005C9C` | Primary, textes importants |
| Bleu clair       | `#0085B0` | Accents, boutons secondaires |
| Vert émeraude    | `#00845F` | Success, disponibilité active, CTAs |
| Blanc            | `#FFFFFF` | Fonds |
| Gris clair       | `#F5F7FA` | Backgrounds |

Logo : `logo_asone_alt.svg` (version recommandée pour l’app).

---

## 7. Prochaines livraisons

- [x] Architecture
- [ ] Prisma schema complet
- [ ] Backend NestJS (auth + modules de base)
- [ ] Thème Flutter + navigation par rôle
- [ ] Écrans Agent (disponibilité + solde)
- [ ] Écrans Chef (composition d’équipe)
