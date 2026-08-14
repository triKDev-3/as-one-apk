# Checklist de test bout-en-bout AS ONE

Mot de passe seed : `asone123`

## 1. Auth
- [ ] Login Admin `+22890000001`
- [ ] Login Chef `+22890000011`
- [ ] Login Agent `+22890100001`
- [ ] Login Magasinier `+22890000003`
- [ ] Login Comptable `+22890000002`
- [ ] Mauvais mot de passe → erreur claire
- [ ] Logout + session restaurée au relancement

## 2. Admin
- [ ] Créer un agent temporaire
- [ ] Créer un site chantier avec tarif
- [ ] Suspendre / réactiver un compte

## 3. Agent
- [ ] Gros bouton disponibilité ON/OFF
- [ ] Voir affectations
- [ ] Confirmer / refuser une affectation (avant 22h)
- [ ] Classement visible (moyenne uniquement)

## 4. Chef
- [ ] Choisir un site → Composer l’équipe
- [ ] Multi-sélection agents + dates
- [ ] Attribution → notification temps réel côté Agent
- [ ] WhatsApp / SMS / copier message
- [ ] Pointage avec photo (caméra ou galerie)
- [ ] Noter les agents 1–5 ★

## 5. Magasinier
- [ ] Sortie matériel liée au site
- [ ] Retour état BON (pas de retenue)
- [ ] Retour DEGRADE / MANQUANT → retenue

## 6. Comptable
- [ ] Créer période (quinzaine)
- [ ] Voir lignes pré-calculées
- [ ] Ajuster primes / retenues
- [ ] Admin valide définitivement

## 7. Temps réel
- [ ] Agent reçoit SnackBar « Nouvelle affectation »
- [ ] Chef reçoit SnackBar confirm/refus
- [ ] Agent reçoit « pointage enregistré »

## Photos
- Permissions Android (`AndroidManifest.xml`) :
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  ```
- iOS (`Info.plist`) :
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Photo de pointage AS ONE</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Choisir une photo de pointage</string>
  ```
