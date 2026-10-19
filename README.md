# FitQuest 💪

Aplikasi **Android** (Flutter) untuk *track* latihan & nutrisi dengan **sistem quest
bergaya game** lean, otot padat, kekuatan fungsional, V-taper, body fat rendah.
Program latihan difokuskan pada **alat & mesin gym**.

> Fitur

- **Program latihan "Toji Physique"** 12 minggu, 3 fase progressive overload, split 5 hari latihan + 2 hari recovery, **difokuskan pada alat & mesin gym** (leg press, hack squat, lat pulldown, cable row, machine press, rowing/air bike, dll.), lengkap dengan **estimasi durasi** tiap sesi.
- **Workout logger**: isi beban & rep aktual, centang set, **timer istirahat** otomatis, simpan durasi sesi.
- **📷 Food Capture AI**: foto makanan (kamera/galeri) → **Google Gemini Vision** memperkirakan kalori & protein tiap item → koreksi → langsung masuk log. (Butuh API key Gemini gratis; lihat Setup di bawah.)
- **Kalkulator kalori & protein harian** (BMR Mifflin-St Jeor → TDEE → target sesuai goal) + **food logger** dengan database quick-add (makanan gym + menu Indonesia) dan makanan custom.
- **⚔️ Solo Leveling Quest System**: tab **Quest** bergaya "System" — Daily Quest ikonik (Push-up/Sit-up/Squat ×100 + Lari 10 km), Side Quest (sebagian otomatis dari data: protein, log makanan, sesi latihan), Main Quest (program 12 minggu = 3 chapter), plus **XP → Level → Rank hunter (E→D→C→B→A→S→MONARCH)**, nama Hunter, dan popup "LEVEL UP!".
- **Progres**: grafik berat badan & volume latihan, riwayat sesi, catat body stat.
- **Offline-first**: semua data di SQLite lokal (`sqflite`).
- **Sync Google Drive**: backup/restore seluruh database (JSON, termasuk XP/quest) ke folder privat app di Drive, manual atau otomatis setelah latihan.

## Detail Program Latihan (estimasi & menu mingguan)

Filosofi: *athletic aesthetic + functional strength + conditioning*.
**5 hari latihan, 2 hari pemulihan. Estimasi sesi 50–75 menit.**

> **Fokus: alat & mesin gym.** Gerakan lapangan/bodyweight (box jump, sprint, battle rope, sled) sudah diganti mesin/kabel.

| Hari             | Fokus                                  | Menu utama (mesin/alat gym)                                                                                                                       | Estimasi |
| ---------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| **Senin**  | Push (Mesin) — dada/bahu/tricep       | Machine chest press, seated machine shoulder press, incline DB press, pec deck fly, cable lateral raise, cable pushdown, overhead cable extension | ~65 mnt  |
| **Selasa** | Lower (Mesin) — kaki/glute            | Leg press, hack squat, seated leg curl, leg extension, machine hip thrust, hip abduction, calf raise machine                                      | ~70 mnt  |
| **Rabu**   | Pull (Mesin & Cable) — punggung/bicep | Lat pulldown, seated cable row, chest-supported machine row, assisted pull-up, cable face pull, straight-arm pulldown, cable hammer curl          | ~70 mnt  |
| **Kamis**  | Core + Cardio Mesin                    | Cable crunch, cable woodchopper, captain's chair knee raise, ab wheel, rowing machine 5×250m, air bike interval                                  | ~50 mnt  |
| **Jumat**  | Full Body (Mesin)                      | Smith machine deadlift, machine shoulder press, lat pulldown, leg press, seated cable row, dumbbell farmer's carry                                | ~70 mnt  |
| **Sabtu**  | Active Recovery                        | Foam rolling, dynamic stretch, steady cycle / treadmill incline                                                                                   | ~40 mnt  |
| **Minggu** | Rest                                   | Pemulihan penuh                                                                                                                                   | —       |

### Fase progresi (12 minggu)

- **Fase 1 — Minggu 1–4 · Foundation/Hypertrophy:** 3–4 set × 8–12 rep, RPE 7, istirahat 90–150 s. Fokus bentuk & volume.
- **Fase 2 — Minggu 5–8 · Strength:** 4–5 set × 4–6 rep, RPE 8, istirahat ~150 s. Naikkan beban.
- **Fase 3 — Minggu 9–12 · Power + Lean/Conditioning:** 3–5 set × 3–5 rep eksplosif + HIIT, RPE 8–9, istirahat ~180 s. Defisit kalori ringan untuk leanness.

App otomatis menyesuaikan **set/rep/RPE/istirahat** tiap exercise berdasarkan fase (minggu berjalan dihitung dari tanggal kamu mulai).

### Berapa lama terlihat hasilnya?

- **4 minggu:** adaptasi saraf, teknik membaik, tenaga naik.
- **8 minggu:** massa otot & definisi mulai terlihat (jika nutrisi on-point).
- **12 minggu:** perubahan komposisi tubuh jelas (lean & berisi) — dengan konsistensi latihan **+** kalori/protein sesuai target **+** tidur 7–9 jam.

> Realistis: "badan Toji" = body fat rendah + otot padat. Kecepatan tergantung genetika, asupan, dan recovery. Protein target **2.0 g/kg** BB.

## Logika Nutrisi

- **BMR (Mifflin-St Jeor):** pria `10·kg + 6.25·cm − 5·umur + 5`; wanita `… − 161`.
- **TDEE** = BMR × faktor aktivitas (1.2 / 1.375 / 1.55 / 1.725 / 1.9).
- **Target kalori:** cut = TDEE − 20%, maintain = TDEE, lean-bulk = TDEE + 10%.
- **Makro:** protein 2.0 g/kg · lemak 25% kalori · karbo = sisa kalori.

---

## 🚀 Cara Menjalankan (Developer)

### 1. Prasyarat

- **Flutter SDK** (stable, ≥ 3.22). Install:
  - macOS: `brew install --cask flutter` atau unduh dari https://docs.flutter.dev/get-started/install
  - Cek: `flutter doctor` (perbaiki item Android toolchain).
- **Android Studio** (untuk SDK & emulator) atau device Android fisik (USB debugging aktif).

### 2. Generate scaffold platform (Android)

Folder project ini hanya berisi `lib/`, `pubspec.yaml`, dan `analysis_options.yaml`.
Jalankan di dalam folder `APPGym` untuk membuat folder `android/` (dan file platform lain)
**tanpa menimpa** kode yang sudah ada:

```bash
cd APPGym
flutter create --platforms=android --org com.toji --project-name toji_trainer .
```

### 3. Ambil dependency

```bash
flutter pub get
```

> Jika `pub get` mengeluh soal versi (mis. `googleapis`/`go_router`), longgarkan versi di
> `pubspec.yaml` atau jalankan `flutter pub upgrade --major-versions`.

### 4. minSdk (tidak perlu diubah)

`android/app/build.gradle.kts` memakai `minSdk = flutter.minSdkVersion` — Flutter
versi kini menetapkan **API 24 (Android 7.0)**, sudah memenuhi syarat semua plugin
(google_sign_in butuh ≥21). Target SDK mengikuti `flutter.targetSdkVersion` (36/Android 16).

### 5. Setup Google Sign-In / Drive (WAJIB untuk fitur sync)

Sync memakai **Google Drive appDataFolder**. Kamu perlu OAuth Client Android:

1. Dapatkan **SHA-1** signing certificate:
   ```bash
   cd android && ./gradlew signingReport
   ```

   (salin SHA-1 dari variant `debug` — untuk release pakai SHA-1 keystore release).
2. Buka [Google Cloud Console](https://console.cloud.google.com/) → buat project.
3. **APIs & Services → Library** → aktifkan **Google Drive API**.
4. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Android**
   - Package name: `com.toji.toji_trainer` *(sesuaikan dengan `applicationId` di `build.gradle`)*
   - SHA-1: tempel dari langkah 1.
5. Simpan. Tidak perlu menaruh file JSON di app — `google_sign_in` Android memakai
   konfigurasi ini otomatis.

> Fitur app tetap jalan **tanpa** setup ini (data lokal). Hanya tombol Login/Backup/Restore
> Drive yang akan gagal sampai OAuth dikonfigurasi.

### 5b. Setup Food Capture AI (Gemini) — opsional tapi disarankan

Fitur **foto makanan → kalori/protein** memakai Google Gemini Vision.

1. Ambil **API key gratis**: https://aistudio.google.com/app/apikey
2. Di app: **Pengaturan → Food AI (Gemini Vision) → Isi API Key**, tempel key-nya.
   Key disimpan lokal di perangkat (SharedPreferences), hanya dikirim ke Google
   Gemini saat menganalisis foto.
3. Buka **Nutrisi → ikon kamera** (atau dashboard → "Foto AI"), foto makanan, tap
   **Analisis Nutrisi**, koreksi bila perlu, lalu **Tambahkan ke Log**.

> Tanpa API key, food logger manual & quick-add tetap berfungsi normal.
> Model default `gemini-1.5-flash` (ganti di `lib/services/food_vision_service.dart`).

### 6. Jalankan

```bash
flutter run
```

Alur pertama kali: **Onboarding** (isi data diri → target kalori/protein otomatis) →
Dashboard. Tanggal mulai program dicatat otomatis → minggu & fase berjalan dihitung dari sana.

### 7. Build release (APK optimal)

```bash
flutter build apk --release --split-per-abi   # APK kecil per arsitektur
flutter build apk --release                   # APK UNIVERSAL — semua perangkat Android
```

Hasil di `build/app/outputs/flutter-apk/`:
- `app-<abi>-release.apk` — per arsitektur (arm64-v8a, armeabi-v7a, x86_64), ukuran lebih kecil.
- `app-release.apk` — **universal** (arm64-v8a + armeabi-v7a + x86_64), jalan di
  **semua perangkat Android 7.0+ (API 24)**; paling aman untuk sideload bila tidak
  tahu arsitektur perangkat.

> R8/minify sengaja **dimatikan** (stabilitas lintas perangkat — googleapis memakai
> refleksi). Kode Dart tetap AOT + tree-shaken. Signing release otomatis dipakai bila
> `android/key.properties` ada (lihat `docs/RELEASE.md`).

**Download APK jadi**: halaman [Releases](https://github.com/aliusman67/Gym-Tracker/releases)
(disediakan CI/CD GitHub Actions: `FitQuest-<versi>-universal.apk` + per-ABI + `.aab`).

Untuk Play Store:

```bash
flutter build appbundle --release
```

---

## 🗂 Struktur Kode

```
lib/
  main.dart                     # bootstrap: buka DB, cek profil, jalankan app
  app/
    router.dart                 # go_router + redirect onboarding
    shell.dart                  # bottom navigation (6 tab, termasuk Quest)
    providers.dart              # Riverpod providers (DB, profil, program, food, sync)
  core/theme.dart               # tema gelap (charcoal + scar accent ala Toji)
  domain/
    nutrition_calc.dart         # BMR/TDEE/target makro
    models/models.dart          # model data + (to/from)Map & JSON
  data/
    database.dart               # sqflite: skema, seed, DAO, export/import JSON
    seed_program.dart           # program Toji 12 minggu + progresi fase
    seed_foods.dart             # database makanan quick-add
    quest_data.dart             # Daily/Side/Main Quest + kurva level/rank
  services/
    food_vision_service.dart    # foto -> nutrisi via Gemini Vision (REST)
    quest_service.dart          # quest engine: progress + XP + auto-tracking
  sync/drive_sync.dart          # backup/restore ke Google Drive
  features/
    onboarding/                 # setup profil + hitung makro
    dashboard/                  # ringkasan + banner Hunter
    quest/                      # layar "System" Solo Leveling (XP/Level/Rank)
    program/                    # split mingguan, detail hari, workout logger
    nutrition/                  # ring makro, food logger, food capture AI
    progress/                   # grafik berat & volume
    settings/                   # sync Drive, target, Gemini key, nama hunter, reset
  widgets/common.dart           # kartu, progress ring, pill, dsb.
```

## ⚔️ Solo Leveling Quest System

- **Daily Quest** (reset tiap hari): Push-up ×100, Sit-up ×100, Squat ×100, Lari 10 km —
  counter manual (+/−). Selesaikan semua → **bonus +50 XP**.
- **Side Quest**: target protein, log 3+ makanan, selesaikan 1 sesi (**otomatis** dari data app)
  + minum 8 gelas, tidur 7 jam, stretching (manual).
- **Main Quest**: program 12 minggu = 3 chapter (Fase 1/2/3), progres = minggu berjalan.
- **XP → Level → Rank**: tiap quest memberi XP sekali/hari. Level naik → popup "LEVEL UP!".
  Rank hunter: E(1) → D(4) → C(9) → B(15) → A(22) → S(30) → MONARCH(40).
- XP & progress quest ikut ter-backup ke Google Drive.

## 🔌 Sync Google Drive — cara kerja

- Login via `google_sign_in` (scope `drive.appdata`).
- **Backup:** seluruh tabel di-export jadi 1 file JSON (`toji_trainer_backup.json`)
  → di-upload ke **appDataFolder** (folder privat app, tak terlihat di UI Drive user).
- **Restore:** unduh JSON → *upsert* ke SQLite (merge by primary key, last-write-wins).
- **Auto-backup:** toggle di Pengaturan → backup otomatis tiap selesai sesi latihan.
- Data sensitif tetap di device; Drive hanya menyimpan salinan backup milik user.

## 🧪 Verifikasi (checklist)

1. `flutter pub get` sukses, `flutter run` jalan di emulator/device.
2. Onboarding: isi data → target kalori/protein muncul & tersimpan.
3. Dashboard: latihan hari ini sesuai hari, ring kalori/protein update.
4. Program: split 7 hari tampil; buka detail hari → set/rep/RPE sesuai fase.
5. Mulai sesi → logger: isi beban/rep, centang set → timer istirahat jalan.
6. Selesai → durasi tersimpan; cek tab Progres (volume & riwayat).
7. Nutrisi: quick-add & custom food → ring berubah; swipe untuk hapus.
8. **Restart app** → semua data tetap ada (SQLite persist).
9. Settings: Login Google → Backup → (hapus/reinstall) → Restore → data kembali.

## ⚠️ Catatan

- Program ini template kebugaran umum, **bukan** saran medis. Konsultasikan ke
  profesional bila punya kondisi kesehatan. Mulai bertahap, utamakan teknik.
- Nilai makro makanan bersifat aproksimasi.
