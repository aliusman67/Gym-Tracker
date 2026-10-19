# FitQuest 💪

![Flutter CI](https://github.com/aliusman67/GymApp-Tracker/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/aliusman67/GymApp-Tracker/actions/workflows/release.yml/badge.svg)

**FitQuest** adalah aplikasi **Android** (Flutter) untuk mencatat latihan dan nutrisi,
dengan **sistem quest bergaya game** supaya tetap termotivasi. Fokusnya: membangun otot,
menurunkan body fat, dan meningkatkan kekuatan fungsional — dengan program latihan
berbasis **alat & mesin gym**.

Semua data tersimpan **lokal (offline-first)** dan bisa di-**backup ke Google Drive**.

> **Logo & icon:** `Assets/logo.png` (dipakai sebagai icon launcher + tampil di onboarding & app bar).
> Ganti icon: ubah `Assets/logo.png` lalu jalankan `dart run flutter_launcher_icons`.

---

## ✨ Fitur
- **Program latihan 12 minggu** — 3 fase *progressive overload*, split 5 hari latihan + 2 hari pemulihan, **fokus alat & mesin gym** (leg press, hack squat, lat pulldown, cable row, machine press, rowing/air bike, dll.), lengkap dengan **estimasi durasi** tiap sesi.
- **Workout logger** — isi beban & rep aktual, centang set, **timer istirahat** otomatis, simpan durasi sesi.
- **📷 Food Capture AI** — foto makanan (kamera/galeri) → **Google Gemini Vision** memperkirakan kalori & protein tiap item → koreksi → langsung masuk log. (Butuh API key Gemini gratis; lihat Setup.)
- **Kalkulator kalori & protein harian** — BMR (Mifflin-St Jeor) → TDEE → target sesuai goal (cut/maintain/lean-bulk), plus **food logger** dengan database quick-add & makanan custom.
- **🎮 Quest System (gamifikasi)** — tab **Quest** dengan Daily Quest, Side Quest, dan Main Quest, plus **XP → Level → Rank (E→D→C→B→A→S→Monarch)** dan notifikasi "LEVEL UP!".
- **Progres** — grafik berat badan & volume latihan, riwayat sesi, catat body stat.
- **Offline-first** — semua data di SQLite lokal (`sqflite`).
- **Sync Google Drive** — backup/restore seluruh database (JSON) ke folder privat app di Drive, manual atau otomatis setelah latihan.

---

## 🏋️ Program Latihan

Filosofi: *athletic aesthetic + functional strength + conditioning*.
**5 hari latihan, 2 hari pemulihan. Estimasi sesi 50–75 menit.**

> Fokus pada **alat & mesin gym**; gerakan lapangan/bodyweight murni diminimalkan.

| Hari | Fokus | Menu utama (mesin/alat gym) | Estimasi |
|------|-------|------------------------------|----------|
| **Senin** | Push (Mesin) — dada/bahu/tricep | Machine chest press, seated machine shoulder press, incline DB press, pec deck fly, cable lateral raise, cable pushdown, overhead cable extension | ~65 mnt |
| **Selasa** | Lower (Mesin) — kaki/glute | Leg press, hack squat, seated leg curl, leg extension, machine hip thrust, hip abduction, calf raise machine | ~70 mnt |
| **Rabu** | Pull (Mesin & Cable) — punggung/bicep | Lat pulldown, seated cable row, chest-supported machine row, assisted pull-up, cable face pull, straight-arm pulldown, cable hammer curl | ~70 mnt |
| **Kamis** | Core + Cardio Mesin | Cable crunch, cable woodchopper, captain's chair knee raise, ab wheel, rowing machine 5×250m, air bike interval | ~50 mnt |
| **Jumat** | Full Body (Mesin) | Smith machine deadlift, machine shoulder press, lat pulldown, leg press, seated cable row, dumbbell farmer's carry | ~70 mnt |
| **Sabtu** | Active Recovery | Foam rolling, dynamic stretch, steady cycle / treadmill incline | ~40 mnt |
| **Minggu** | Rest | Pemulihan penuh | — |

### Fase progresi (12 minggu)
- **Fase 1 — Minggu 1–4 · Foundation/Hypertrophy:** 3–4 set × 8–12 rep, RPE 7, istirahat 90–150 s. Fokus bentuk & volume.
- **Fase 2 — Minggu 5–8 · Strength:** 4–5 set × 4–6 rep, RPE 8, istirahat ~150 s. Naikkan beban.
- **Fase 3 — Minggu 9–12 · Power + Lean/Conditioning:** 3–5 set × 3–5 rep eksplosif + HIIT, RPE 8–9, istirahat ~180 s. Defisit kalori ringan untuk leanness.

App otomatis menyesuaikan **set/rep/RPE/istirahat** tiap exercise berdasarkan fase
(minggu berjalan dihitung dari tanggal kamu memulai program).

### Perkiraan hasil
- **4 minggu:** adaptasi saraf, teknik membaik, tenaga naik.
- **8 minggu:** massa otot & definisi mulai terlihat (jika nutrisi on-point).
- **12 minggu:** perubahan komposisi tubuh jelas (lean & berisi) — dengan konsistensi latihan **+** kalori/protein sesuai target **+** tidur 7–9 jam.

> Kecepatan hasil tergantung genetika, asupan, dan recovery. Target protein umum **~2.0 g/kg** berat badan.

---

## 🥗 Logika Nutrisi
- **BMR (Mifflin-St Jeor):** pria `10·kg + 6.25·cm − 5·umur + 5`; wanita `… − 161`.
- **TDEE** = BMR × faktor aktivitas (1.2 / 1.375 / 1.55 / 1.725 / 1.9).
- **Target kalori:** cut = TDEE − 20%, maintain = TDEE, lean-bulk = TDEE + 10%.
- **Makro:** protein ~2.0 g/kg · lemak 25% kalori · karbo = sisa kalori.

---

## 🎮 Quest System (Gamifikasi)
- **Daily Quest** (reset tiap hari): Push-up ×100, Sit-up ×100, Squat ×100, Lari 10 km —
  counter manual (+/−). Selesaikan semua → **bonus XP**.
- **Side Quest**: penuhi target protein, log 3+ makanan, selesaikan 1 sesi latihan
  (**otomatis** dari data app) + minum 8 gelas, tidur 7 jam, stretching (manual).
- **Main Quest**: program 12 minggu = 3 chapter (Fase 1/2/3), progres = minggu berjalan.
- **XP → Level → Rank**: tiap quest memberi XP sekali/hari. Level naik → notifikasi "LEVEL UP!".
  Rank: E(1) → D(4) → C(9) → B(15) → A(22) → S(30) → Monarch(40).
- XP & progress quest ikut ter-backup ke Google Drive.

---

## 🚀 Cara Menjalankan (Developer)

### 1. Prasyarat
- **Flutter SDK** (stable, ≥ 3.22). Install:
  - macOS: `brew install --cask flutter` atau unduh dari https://docs.flutter.dev/get-started/install
  - Cek: `flutter doctor` (perbaiki item Android toolchain).
- **Android Studio** (untuk SDK & emulator) atau device Android fisik (USB debugging aktif).

### 2. Generate scaffold platform (Android)
Bila folder `android/` belum ada, jalankan di dalam folder project untuk membuatnya
**tanpa menimpa** kode yang sudah ada:
```bash
flutter create --platforms=android --org com.toji --project-name toji_trainer .
```
> `--project-name` dan `--org` harus tetap `toji_trainer` / `com.toji` agar cocok dengan
> `applicationId` & import package internal (`package:toji_trainer/...`).

### 3. Ambil dependency
```bash
flutter pub get
```
> Jika `pub get` mengeluh soal versi, longgarkan versi di `pubspec.yaml` atau jalankan
> `flutter pub upgrade --major-versions`.

### 4. minSdk Android = 21
Pastikan `minSdk` 21 (untuk `google_sign_in`). Default `flutter.minSdkVersion` sudah 21
pada Flutter versi terbaru; bila perlu set manual di `android/app/build.gradle.kts`.

### 5. Setup Google Sign-In / Drive (untuk fitur sync)
Sync memakai **Google Drive appDataFolder**. Kamu perlu OAuth Client Android:
1. Dapatkan **SHA-1** signing certificate:
   ```bash
   cd android && ./gradlew signingReport
   ```
   (salin SHA-1 variant `debug`; untuk release pakai SHA-1 keystore release).
2. Buka [Google Cloud Console](https://console.cloud.google.com/) → buat project.
3. **APIs & Services → Library** → aktifkan **Google Drive API**.
4. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Android**
   - Package name: `com.toji.toji_trainer`
   - SHA-1: tempel dari langkah 1.
5. Simpan. `google_sign_in` Android memakai konfigurasi ini otomatis.

> App tetap jalan **tanpa** setup ini (data lokal). Hanya Login/Backup/Restore Drive
> yang gagal sampai OAuth dikonfigurasi.

### 5b. Setup Food Capture AI (Gemini) — opsional
Fitur **foto makanan → kalori/protein** memakai Google Gemini Vision.
1. Ambil **API key gratis**: https://aistudio.google.com/app/apikey
2. Di app: **Pengaturan → Food AI (Gemini Vision) → Isi API Key**, tempel key-nya.
   Key disimpan lokal di perangkat (SharedPreferences), hanya dikirim ke Google Gemini
   saat menganalisis foto.
3. Buka **Nutrisi → ikon kamera** (atau dashboard → "Foto AI"), foto makanan, tap
   **Analisis Nutrisi**, koreksi bila perlu, lalu **Tambahkan ke Log**.

> Tanpa API key, food logger manual & quick-add tetap berfungsi normal.
> Model default `gemini-1.5-flash` (ganti di `lib/services/food_vision_service.dart`).

### 6. Jalankan
```bash
flutter run
```
Alur pertama kali: **Onboarding** (isi data diri → target kalori/protein otomatis) → Dashboard.

### 7. Build release (APK optimal)
```bash
flutter build apk --release --split-per-abi
```
Hasil di `build/app/outputs/flutter-apk/`. `--split-per-abi` memecah APK per arsitektur
(arm64-v8a, armeabi-v7a, x86_64) → ukuran lebih kecil. R8/minify aktif default di release.

Untuk Play Store:
```bash
flutter build appbundle --release
```

---

## 🤖 CI/CD (GitHub Actions)
Dua workflow di `.github/workflows/` berjalan otomatis di GitHub:

**`ci.yml` — Flutter CI** (tiap `push` & `pull_request`, semua branch):
1. Setup Java 17 + Flutter stable (dengan cache).
2. `flutter pub get` → `flutter analyze --no-fatal-infos` → `flutter test`.
3. `flutter build apk --release --split-per-abi` **dan** `flutter build appbundle --release`.
4. Upload APK & AAB sebagai **artifact** (tab *Actions* → run → *Artifacts*).

> `--no-fatal-infos`: lint info tidak memblokir; warning/error tetap membuat CI gagal.

**`release.yml` — Release** (tiap push tag `v*`):
- Build APK + AAB lalu membuat **GitHub Release** dan melampirkan file-nya.
- Rilis versi baru:
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

**Catatan agar CI jalan:**
- Folder `android/` (hasil `flutter create`) **harus ikut ter-commit** — `.gitignore`
  hanya mengecualikan `local.properties`, `.gradle/`, `key.properties`, dan keystore.
- Release build memakai **debug signing** (default template) → cukup untuk artifact CI.
  Untuk Play Store, siapkan keystore release + `key.properties`.

---

## 🔌 Sync Google Drive — cara kerja
- Login via `google_sign_in` (scope `drive.appdata`).
- **Backup:** seluruh tabel di-export jadi 1 file JSON → di-upload ke **appDataFolder**
  (folder privat app, tak terlihat di UI Drive user).
- **Restore:** unduh JSON → *upsert* ke SQLite (merge by primary key, last-write-wins).
- **Auto-backup:** toggle di Pengaturan → backup otomatis tiap selesai sesi latihan.
- Data tetap di device; Drive hanya menyimpan salinan backup milik user.

---

## 🗂 Struktur Kode
```
lib/
  main.dart                     # bootstrap: buka DB, cek profil, jalankan app
  app/
    router.dart                 # go_router + redirect onboarding
    shell.dart                  # bottom navigation (6 tab, termasuk Quest)
    providers.dart              # Riverpod providers (DB, profil, program, food, quest, sync)
  core/theme.dart               # tema gelap
  domain/
    nutrition_calc.dart         # BMR/TDEE/target makro
    models/models.dart          # model data + PlayerProfile + QuestProgress
  data/
    database.dart               # sqflite: skema, seed, DAO, export/import JSON
    seed_program.dart           # program 12 minggu + progresi fase
    seed_foods.dart             # database makanan quick-add
    quest_data.dart             # Daily/Side/Main Quest + kurva level/rank
  services/
    food_vision_service.dart    # foto -> nutrisi via Gemini Vision (REST)
    quest_service.dart          # quest engine: progress + XP + auto-tracking
  sync/drive_sync.dart          # backup/restore ke Google Drive
  features/
    onboarding/                 # setup profil + hitung makro
    dashboard/                  # ringkasan harian
    quest/                      # layar Quest (XP/Level/Rank)
    program/                    # split mingguan, detail hari, workout logger
    nutrition/                  # ring makro, food logger, food capture AI
    progress/                   # grafik berat & volume
    settings/                   # sync Drive, target, Gemini key, profil, reset
  widgets/common.dart           # kartu, progress ring, pill, dsb.
```

---

## 🧪 Verifikasi (checklist)
1. `flutter pub get` sukses, `flutter run` jalan di emulator/device.
2. Onboarding: isi data → target kalori/protein muncul & tersimpan.
3. Dashboard: latihan hari ini sesuai hari, ring kalori/protein update.
4. Program: split 7 hari tampil; buka detail hari → set/rep/RPE sesuai fase.
5. Mulai sesi → logger: isi beban/rep, centang set → timer istirahat jalan.
6. Selesai → durasi tersimpan; cek tab Progres (volume & riwayat).
7. Nutrisi: quick-add, custom food, dan Food Capture AI → ring berubah.
8. Quest: selesaikan Daily/Side Quest → XP bertambah, level/rank naik.
9. **Restart app** → semua data tetap ada (SQLite persist).
10. Settings: Login Google → Backup → (hapus/reinstall) → Restore → data kembali.

## ⚠️ Catatan
- Program ini template kebugaran umum, **bukan** saran medis. Konsultasikan ke profesional
  bila punya kondisi kesehatan. Mulai bertahap, utamakan teknik.
- Nilai makro makanan (termasuk estimasi AI) bersifat aproksimasi.
