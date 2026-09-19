# Build APK sans PC (GitHub Actions)

Tu n’as plus besoin d’un ordinateur pour tester l’app sur Android.

## 1. Lancer un build

1. Ouvre le dépôt : [github.com/triKDev-3/as-one-apk](https://github.com/triKDev-3/as-one-apk)
2. Onglet **Actions**
3. À gauche : **Build APK AS ONE**
4. **Run workflow** (bouton à droite)
5. Optionnel : change l’URL de l’API (ex. serveur Katabump)
6. Clique **Run workflow**

Le build prend en général **8–15 minutes**.

## 2. Télécharger l’APK (téléphone)

1. Quand le run est **vert** (succès), ouvre-le
2. Tout en bas : section **Artifacts**
3. Télécharge `asone-apk-debug` (fichier zip)
4. Dézippe → `asone-debug.apk`
5. Sur Android : *Paramètres → Sécurité → Sources inconnues* (ou autoriser le navigateur / fichiers)
6. Ouvre le `.apk` → Installer

> Sur mobile, GitHub te demande parfois de te connecter. Utilise le navigateur (Chrome) connecté à ton compte GitHub.

## 3. API backend

L’APK pointe par défaut vers :

```text
http://10.208.121.45:3000
```

- Le téléphone et le serveur doivent être **sur le même réseau** (ou l’IP accessible depuis Internet).
- Pour une API en ligne (Katabump, VPS) : relance le workflow avec l’URL HTTPS, ex. `https://api.ton-domaine.com`.

## 4. Build automatique

Chaque push sur `main` qui touche `frontend/` relance aussi un build debug.

## 5. Compte de test

Mot de passe : `asone123`

| Rôle | Téléphone |
|------|-----------|
| Admin | +22890000001 |
| Chef | +22890000011 |
| Agent | +22890100001 |

## Dépannage

| Problème | Solution |
|----------|----------|
| Artifact introuvable | Ouvre le run réussi, scroll en bas ; pas le résumé email |
| « App non installée » | Désinstalle l’ancienne version d’abord |
| Serveur injoignable | Vérifie que l’API tourne et que l’URL du build est correcte |
| Build rouge | Onglet Actions → logs ; envoie le message d’erreur pour correction |
