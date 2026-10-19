# Panduan Release & Signing (Developer)

## Cara kerja signing
- `android/key.properties` + `android/app/fitquest-release.jks` = kredensial release
  **lokal**. Keduanya **tidak pernah di-commit** (sudah di-ignore:
  `android/.gitignore` → `key.properties`, `**/*.jks`).
- `android/app/build.gradle.kts` membaca `key.properties`:
  - ada → release build ditandatangani **release key**;
  - tidak ada (mis. CI tanpa secrets) → fallback ke **debug signing** (build tetap jalan).
- Release build juga mengaktifkan **R8 minify + resource shrinking**
  (`android/app/proguard-rules.pro`).

> ⚠️ **BACKUP `fitquest-release.jks` + password-nya!** Kalau hilang, kamu tidak bisa
> lagi merilis update sebagai app yang sama (terutama di Play Store). Simpan salinan
> di password manager / Drive privat.

## Setup GitHub Secrets (sekali saja)
Workflow `ci.yml` & `release.yml` otomatis memakai release signing bila 4 secret ini ada:

| Secret | Isi |
|--------|-----|
| `KEYSTORE_BASE64` | keystore di-encode base64 |
| `KEYSTORE_PASSWORD` | `storePassword` dari `android/key.properties` |
| `KEY_PASSWORD` | `keyPassword` dari `android/key.properties` |
| `KEY_ALIAS` | `fitquest` |

### Cara mengisi
1. Encode keystore ke base64 (macOS, langsung ke clipboard):
   ```fish
   base64 -i android/app/fitquest-release.jks | pbcopy
   ```
2. Buka repo → **Settings → Secrets and variables → Actions → New repository secret**,
   buat keempat secret di atas (nilai password lihat di `android/key.properties`).

   Atau dengan `gh` CLI:
   ```fish
   gh secret set KEYSTORE_BASE64 --body (base64 -i android/app/fitquest-release.jks | string collect)
   gh secret set KEYSTORE_PASSWORD --body (grep storePassword android/key.properties | cut -d= -f2)
   gh secret set KEY_PASSWORD --body (grep keyPassword android/key.properties | cut -d= -f2)
   gh secret set KEY_ALIAS --body fitquest
   ```

## Alur rilis
- **Push ke `main`** → `ci.yml`: analyze → test → build APK (signed bila secrets ada)
  → artifact + rolling pre-release **"Latest Build (main)"** di halaman Releases.
- **Tag versi** → `release.yml`: build → rename (`FitQuest-vX.Y.Z-<abi>.apk`, `.aab`)
  → **GitHub Release stabil** dengan notes otomatis.
  ```fish
  git tag v1.1.0
  git push origin v1.1.0
  ```

## Verifikasi signature APK
```fish
~/Library/Android/sdk/build-tools/36.1.0/apksigner verify --print-certs <file.apk>
# Bandingkan fingerprint dengan keystore:
keytool -list -keystore android/app/fitquest-release.jks
```

## Play Store
1. Pakai file `.aab` dari Release.
2. Pastikan secrets signing terpasang (atau build lokal dengan `key.properties`).
3. Upload ke Play Console → jalur rilis (Internal/Closed/Production).
