# AS ONE — Application de gestion

**Facility Management — Afrique de l’Ouest**

Application multi-plateforme (Android · iOS · Web · Desktop) pour la gestion des équipes, du matériel et de la paie.

---

## Stack

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter 3 + Riverpod + go_router |
| Backend | NestJS 10 + Prisma 5 |
| Database | PostgreSQL 16 |
| Auth | JWT + RBAC |
| Temps réel | Socket.io (`/realtime`) |
| Photos | Upload local (`/uploads`) |

**Couleurs officielles** : `#005C9C` · `#0085B0` · `#00845F`

---

## Démarrage rapide

### Option A — Docker (recommandé)

```bash
cd asone-app
docker compose up -d --build
# API → http://localhost:3000/health

cd backend && npm install && npm run seed
```

### Option B — Backend local

```bash
cd backend
cp .env.example .env          # DATABASE_URL + JWT_SECRET
npm install
npx prisma migrate dev
npm run seed
npm run start:dev
```

### Frontend

```bash
cd frontend
flutter create . --project-name asone_app --org services.asone   # une fois
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
# Android emulator : http://10.0.2.2:3000
```

Voir `docs/NATIVE_SETUP.md` pour permissions caméra et builds release.

---

## Comptes de test (seed)

Mot de passe : **`asone123`**

| Rôle | Téléphone |
|------|-----------|
| Admin | +22890000001 |
| Comptable | +22890000002 |
| Magasinier | +22890000003 |
| Chef | +22890000011 |
| Agent | +22890100001 … 005 |

---

## Fonctionnalités par rôle

| Rôle | Capacités |
|------|-----------|
| **Agent** | Disponibilité, confirm/refus affectation, solde, classement, notifs temps réel |
| **Chef** | Sites, composition équipe, pointage + photo, notation, WhatsApp/SMS |
| **Magasinier** | Sortie / retour matériel, retenues |
| **Comptable** | Périodes de paie, simulation, ajustements |
| **Admin** | Comptes, sites, suspension, validation paie, classement |

---

## Documentation

| Doc | Contenu |
|-----|---------|
| `docs/ARCHITECTURE.md` | Décisions techniques |
| `docs/DEPLOY_KATABUMP.md` | Déploiement API |
| `docs/NATIVE_SETUP.md` | Android / iOS / builds |
| `docs/TEST_CHECKLIST.md` | Tests bout-en-bout |

---

## Makefile

```bash
make up          # docker compose up
make down
make logs
make seed
make api-health
make apk API_URL=https://api.example.com
```

---

## Structure

```
asone-app/
├── backend/          # NestJS API
├── frontend/         # Flutter app
├── docs/
├── docker-compose.yml
└── Makefile
```
