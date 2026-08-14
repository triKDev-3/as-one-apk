# AS ONE — Statut projet (MVP)

**Date :** 2026-08-14  
**Cahier des charges :** v6 (`AS_ONE_Cahier_des_Charges_v6.docx`)

## Couverture fonctionnelle

| Domaine | Backend | Frontend | Notes |
|---------|---------|----------|-------|
| Auth JWT + RBAC | ✅ | ✅ | Login téléphone |
| Agent — disponibilité ≤22h | ✅ | ✅ | Gros bouton |
| Agent — confirm/refus affectation | ✅ | ✅ | Avant 22h |
| Agent — dashboard / classement | ✅ | ✅ | Moyenne uniquement |
| Chef — sites / équipe | ✅ | ✅ | Multi-agents, dates |
| Chef — pointage + photo | ✅ | ✅ | Caméra / galerie |
| Chef — notation 1–5 | ✅ | ✅ | Recalc rankingScore |
| Chef — WhatsApp/SMS | — | ✅ | Texte généré localement |
| Magasinier — sortie/retour | ✅ | ✅ | Retenues auto |
| Comptable — périodes paie | ✅ | ✅ | Simulation + ajustements |
| Admin — users / sites | ✅ | ✅ | Suspension |
| Temps réel Socket.io | ✅ | ✅ | assignment, pointage |
| Upload photos | ✅ | ✅ | `/upload/photo` |
| Seed démo | ✅ | — | `npm run seed` |
| Docker Compose | ✅ | — | Postgres + API |

## Corrections récentes (audit)

- Pool agents chef : **tous les agents actifs** (indisponibles inclus, badge UI)
- DTOs stricts : `RespondAssignment`, `ToggleAvailability`, `SetActive`
- Health check : `GET /health`
- Docs : NATIVE_SETUP, DEPLOY_KATABUMP, TEST_CHECKLIST

## Hors MVP (backlog)

- [ ] Push FCM natives
- [ ] Cloudinary (remplacer disque local)
- [ ] Serveur d’envoi WhatsApp Business
- [ ] Mode offline / file d’attente
- [ ] Journal d’audit UI complète
- [ ] Tests automatisés (e2e)

## Démarrage

```bash
docker compose up -d --build
cd backend && npm install && npm run seed
cd ../frontend && flutter create . --project-name asone_app --org services.asone
flutter pub get && flutter run --dart-define=API_BASE_URL=http://localhost:3000
```
