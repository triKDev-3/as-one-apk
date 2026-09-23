# Build APK sans PC (GitHub Actions)

## Installation qui échoue (« un package empêche… »)

Android refuse souvent d’écraser une ancienne app avec **une autre signature** ou le même ID.

### À faire avant d’installer

1. **Désinstalle** toute app nommée `asone_app`, `AS ONE`, ou liée à l’ancien package `com.example.asone_app`
   - Paramètres → Applications → chercher « asone » → Désinstaller
2. Vérifie qu’il reste **assez d’espace** (au moins 200 Mo libres)
3. Télécharge le **nouvel** artifact (package `services.asone.app`, version 1.0.1+)
4. Ouvre le fichier **`.apk`** (pas le `.zip` brut) après décompression

### Sources inconnues

Chrome / Fichiers → autoriser l’installation de cette source quand Android le demande.

---

## 1. Lancer un build

1. [Actions du dépôt](https://github.com/triKDev-3/as-one-apk/actions)
2. **Build APK AS ONE** → **Run workflow**
3. Attendre ~10–15 min (run vert)

## 2. Télécharger l’APK

1. Ouvre le run réussi
2. Section **Artifacts** → `asone-apk-debug`
3. Dézippe → `asone-debug.apk`
4. Installe

## 3. API

Par défaut : `http://10.208.121.45:3000`  
Le téléphone doit joindre cette adresse (même Wi‑Fi / API publique).

## Compte test

Mot de passe : `asone123` — Admin `+22890000001` · Chef `+22890000011` · Agent `+22890100001`
