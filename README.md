# FitQuest 💪

**FitQuest** adalah aplikasi Android untuk mencatat latihan dan makanan, sekaligus
menjaga motivasi lewat **sistem quest bergaya game**. Cocok untuk kamu yang ingin
membangun otot, menurunkan lemak tubuh, dan jadi lebih bugar — dengan panduan program
latihan berbasis **alat & mesin gym** serta perhitungan gizi harian.

Semua data tersimpan **di perangkatmu (offline)**, dan bisa kamu **cadangkan ke
Google Drive** kapan saja.

---

## 📥 Download APK
APK siap pasang tersedia di halaman **[Releases](https://github.com/aliusman67/GymApp-Tracker/releases)**:
- **Rilis stabil** — tag versi (`v1.1.0`, dst.): `FitQuest-vX.Y.Z-arm64-v8a.apk`.
- **Latest Build (main)** — pre-release yang diperbarui otomatis setiap ada perubahan
  di branch `main`.

Pilih APK sesuai arsitektur perangkat (umumnya **arm64-v8a**), unduh, lalu buka
file-nya di Android (izinkan *install unknown apps* bila diminta).

---

## Kenapa FitQuest?
- **Program latihan siap pakai** — tidak perlu bingung "hari ini latihan apa".
- **Pantau gizi otomatis** — target kalori & protein dihitung dari data dirimu.
- **Termotivasi seperti main game** — selesaikan quest, kumpulkan XP, naik level & rank.
- **Lihat perkembanganmu** — grafik berat badan dan volume latihan dari waktu ke waktu.
- **Privat** — datamu milikmu, tersimpan lokal, backup ke Drive-mu sendiri.

---

## Fitur Utama

### 🏋️ Program Latihan 12 Minggu (Adaptif)
Program terstruktur dengan fokus pada **mesin & alat gym**. Intensitas naik bertahap
dalam **3 fase** (membangun dasar → kekuatan → power & definisi). Setiap latihan punya
target set, repetisi, dan waktu istirahat, lengkap dengan **perkiraan durasi** tiap
sesi (±50–75 menit).

**Menyesuaikan kondisi awalmu** — saat onboarding kamu memilih:
- **Level pengalaman** (Pemula / Menengah / Mahir) → menentukan jumlah set, rentang
  rep, RPE, dan waktu istirahat (pemula: set lebih sedikit, rep lebih tinggi,
  istirahat lebih lama; mahir: volume & intensitas lebih besar).
- **Hari latihan per minggu** (3–6 hari) → jadwal mingguan otomatis disusun ulang
  (mis. 3 hari: Push–Lower–Pull di Senin/Rabu/Jumat; hari lain jadi pemulihan).

Semua bisa diubah kapan saja di **Pengaturan → Ubah Target & Format Latihan**.

Saat latihan, kamu tinggal **mencatat beban & repetisi aktual**, mencentang set, dan
**timer istirahat** berjalan otomatis.

| Hari | Fokus |
|------|-------|
| Senin | Push (dada, bahu, tricep) |
| Selasa | Lower (kaki & glute) |
| Rabu | Pull (punggung & bicep) |
| Kamis | Core + cardio mesin |
| Jumat | Full body |
| Sabtu | Pemulihan aktif |
| Minggu | Istirahat |

### 🥗 Pencatatan Nutrisi
- **Target harian otomatis**: aplikasi menghitung kebutuhan kalori & protein dari
  jenis kelamin, umur, tinggi, berat, tingkat aktivitas, dan tujuanmu
  (menurunkan / menjaga / menaikkan berat badan).
- **Food Capture AI**: **foto makananmu**, lalu AI memperkirakan kalori dan proteinnya —
  kamu bisa mengoreksi sebelum menyimpannya ke catatan.
- **Log makanan**: tambahkan dari daftar cepat (makanan umum & menu Indonesia),
  cari makanan, atau isi manual. Pantau progress kalori/protein/karbo/lemak setiap hari.

### 🎮 Sistem Quest (Gamifikasi)
Ubah rutinitas jadi permainan — quest **tersinkron dengan latihan gym-mu**:
- **Daily Quest (hari latihan)** — selesaikan sesi gym dan log 16+ set (*otomatis*
  dari workout logger), cardio mesin 10 menit, cooldown & stretching.
  Selesaikan semua → **bonus XP**.
- **Daily Quest (hari istirahat)** — mobility/stretching, jalan santai 30 menit,
  tidur 7–9 jam.
- **Side Quest** — penuhi target protein, log 3+ makanan, timbang berat badan
  (*otomatis*), progressive overload, minum 8 gelas air.
- **Main Quest** — program 12 minggu yang dibagi jadi beberapa "chapter".
- **XP, Level & Rank** — selesaikan quest untuk mendapat XP, naik level, dan membuka
  rank yang lebih tinggi (E → D → C → B → A → S → Monarch). Ada notifikasi saat
  kamu **level up**.

### 📈 Progres
Catat berat badan dan lihat **grafik perkembangan** serta **volume latihan** dari sesi
ke sesi. Pantau konsistensi lewat riwayat latihanmu.

### ☁️ Backup ke Google Drive
Masuk dengan akun Google untuk **mencadangkan** seluruh data (profil, latihan, makanan,
hingga XP & quest) ke Drive-mu, lalu **memulihkannya** kapan saja — misalnya saat ganti
perangkat. Bisa juga diatur agar backup otomatis setiap selesai latihan.

---

## Cara Memakai (Singkat)
1. **Isi data diri** saat pertama membuka app → target kalori & program otomatis dibuat.
2. **Dashboard** menampilkan latihan hari ini dan ringkasan nutrisi.
3. **Mulai latihan** → catat beban/rep, centang set, ikuti timer istirahat.
4. **Catat makanan** — manual, dari daftar cepat, atau **foto** dengan Food Capture AI.
5. Buka tab **Quest** untuk melihat misi harian dan progres level/rank-mu.
6. Pantau perkembangan di tab **Progres**, dan atur backup di **Pengaturan**.

---

## Privasi & Data
- Data disimpan **lokal** di perangkat secara default.
- **API key** AI makanan dan data backup **tidak dibagikan** ke pihak lain; key hanya
  tersimpan di perangkatmu dan dipakai untuk memproses foto yang kamu kirim.
- Backup Google Drive masuk ke **folder privat aplikasi** di Drive-mu (tidak terlihat
  sebagai file umum).

---

## Catatan
FitQuest menyediakan **template kebugaran umum** dan **bukan pengganti saran medis**.
Bila kamu memiliki kondisi kesehatan tertentu, konsultasikan dulu dengan profesional.
Mulailah secara bertahap dan utamakan teknik yang benar. Nilai gizi (termasuk estimasi
AI) bersifat **perkiraan**.
