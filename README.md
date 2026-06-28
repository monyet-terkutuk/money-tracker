# Catat Uang Pribadi

Aplikasi pencatatan keuangan pribadi berbasis Flutter untuk mencatat pemasukan dan pengeluaran harian, dilengkapi dengan fitur pemindaian struk menggunakan OCR dan AI.

## Fitur

### 1. Manajemen Transaksi

- **Catat Pemasukan & Pengeluaran** — Tambah transaksi secara manual dengan memilih tipe (pemasukan/pengeluaran), jumlah, kategori, tanggal, metode pembayaran, dan catatan.
- **Navigasi Bulanan** — Lihat riwayat transaksi per bulan dengan navigasi panah kiri/kanan.
- **Filter Berdasarkan Tipe** — Lihat daftar transaksi yang difilter khusus pemasukan atau pengeluaran.
- **Detail Transaksi** — Lihat informasi lengkap setiap transaksi termasuk gambar struk jika ada.
- **Hapus dengan Swipe** — Geser ke kiri pada item transaksi untuk menghapus (dengan opsi undo).

### 2. Pemindaian Struk (OCR + AI)

- **Ambil Foto/Galeri** — Ambil foto struk menggunakan kamera atau pilih dari galeri.
- **OCR Otomatis** — Gunakan Google MLKit Text Recognition untuk mengekstrak teks dari gambar struk.
- **Parsing AI** — Kirim teks hasil OCR ke API DeepSeek untuk diparsing menjadi data terstruktur (nama toko, tanggal, total, metode bayar).
- **Pratinjau Hasil** — Lihat hasil parsing sebelum disimpan (gambar struk, teks OCR, dan field hasil parsing).

### 3. Kategori

- **Kategori Default** — 9 kategori pengeluaran (Makanan & Minuman, Transportasi, Belanja & Kebutuhan, Tagihan & Isi Ulang, Kesehatan, Hiburan, Pendidikan, Rumah Tangga, Lainnya) dan 6 kategori pemasukan (Gaji, Bonus, Freelance, Investasi, Hadiah, Lainnya).
- **Kategori Kustom** — Tambah dan hapus kategori sesuai kebutuhan.

### 4. Ekspor & Cadangan

- **Ekspor CSV** — Ekspor seluruh transaksi ke file CSV dan bagikan melalui aplikasi lain.
- **Cadangan Database** — Backup file database SQLite ke folder Downloads atau bagikan.

### 5. Tampilan

- **Ringkasan Bulanan** — Dashboard utama menampilkan saldo, total pemasukan, dan total pengeluaran bulan berjalan.
- **Mode Gelap/Terang** — Beralih antara tema gelap dan terang dari halaman Pengaturan.

### 6. Pengaturan

- **API Key DeepSeek** — Konfigurasi API key untuk fitur parsing struk AI.
- **Dark Mode** — Toggle tema gelap.

## Teknologi

| Teknologi | Kegunaan |
|-----------|----------|
| **Flutter / Dart** | Framework pengembangan aplikasi |
| **Drift** | ORM / database SQLite lokal |
| **Riverpod** | State management |
| **GoRouter** | Navigasi dan routing |
| **Google MLKit** | OCR untuk membaca teks dari gambar struk |
| **DeepSeek API** | AI parsing untuk mengekstrak data struk |
| **FlutterSecureStorage** | Penyimpanan aman untuk API key |
| **Image Picker** | Kamera dan galeri untuk mengambil gambar struk |
| **Share Plus** | Berbagi file CSV / backup |
| **CSV** | Generate file CSV untuk ekspor data |

## Cara Menggunakan

### Persyaratan

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.4
- Android Studio / Xcode untuk build
- Perangkat Android/iOS atau emulator

### Instalasi

```bash
# Clone repository
git clone <repository-url>
cd catat_uang_pribadi

# Install dependencies
flutter pub get

# Generate kode Drift & Riverpod
dart run build_runner build --delete-conflicting-outputs

# Jalankan aplikasi
flutter run
```

### Panduan Penggunaan

#### Mencatat Transaksi Manual

1. Dari halaman utama (**Beranda**), tap tombol **+** (FAB) di pojok kanan bawah.
2. Pilih **Input Manual**.
3. Pilih tipe transaksi: **Pemasukan** atau **Pengeluaran**.
4. Isi jumlah (angka saja, dalam Rupiah).
5. Pilih kategori (akan menyesuaikan dengan tipe transaksi).
6. Atur tanggal (default: hari ini).
7. Pilih metode pembayaran: Tunai, Debit, Kredit, QRIS, E-Wallet.
8. Tambahkan catatan (opsional).
9. Tap **Simpan**.

#### Memindai Struk

1. Dari halaman utama, tap tombol **+** → **Pindai Struk**.
2. Pilih **Kamera** untuk memotret struk, atau **Galeri** untuk memilih gambar.
3. Aplikasi akan memproses gambar dengan OCR.
4. Teks hasil OCR akan dikirim ke AI untuk diparsing.
5. Pratinjau hasil parsing akan ditampilkan.
6. Periksa dan simpan data transaksi.

> **Catatan:** Fitur pemindaian struk memerlukan koneksi internet dan API Key DeepSeek yang valid. Konfigurasikan API Key di halaman **Pengaturan**.

#### Melihat Riwayat Transaksi

1. Dari halaman utama, tap kartu **Total Pemasukan** atau **Total Pengeluaran**.
2. Daftar transaksi akan ditampilkan untuk bulan berjalan.
3. Geser ke kiri/kanan pada bagian atas (bulan/tahun) untuk navigasi antar bulan.
4. Tap transaksi untuk melihat detail.
5. Geser kiri pada item untuk menghapus.

#### Ekspor Data

1. Buka halaman **Pengaturan** dari ikon roda gigi di pojok kanan atas halaman utama.
2. Tap **Ekspor CSV** untuk menghasilkan dan membagikan file CSV.
3. Tap **Backup Database** untuk membuat cadangan file database.

#### Mengelola Kategori

1. Buka halaman **Kategori** dari ikon kategori di pojok kanan atas halaman utama.
2. Lihat kategori pengeluaran dan pemasukan.
3. Tap ikon **+** untuk menambah kategori kustom.
4. Kategori default tidak dapat dihapus; kategori kustom dapat dihapus dengan tap ikon sampah.

## Struktur Proyek

```
lib/
├── main.dart                          # Entry point aplikasi
├── app.dart                           # MaterialApp.router dengan ProviderScope
├── core/
│   ├── database/
│   │   ├── app_database.dart          # Database Drift + method DAO
│   │   └── tables/
│   │       ├── transactions_table.dart # Definisi tabel transaksi
│   │       └── categories_table.dart  # Definisi tabel kategori
│   ├── router/
│   │   └── app_router.dart            # Konfigurasi GoRouter
│   ├── theme/
│   │   └── app_theme.dart             # Tema Material 3 (terang/gelap)
│   └── utils/
│       ├── constants.dart             # Konstanta (metode bayar, ikon kategori)
│       ├── currency_formatter.dart     # Format mata uang IDR
│       └── date_formatter.dart        # Format tanggal Indonesia
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart       # Dashboard utama
│   ├── transactions/
│   │   ├── domain/
│   │   │   ├── transaction_providers.dart # Riverpod providers transaksi
│   │   │   └── category_providers.dart    # Riverpod providers kategori
│   │   └── presentation/
│   │       ├── add_transaction_screen.dart   # Form tambah/edit transaksi
│   │       ├── transaction_detail_screen.dart # Detail transaksi
│   │       └── transaction_list_screen.dart   # Daftar transaksi bulanan
│   ├── categories/
│   │   └── presentation/
│   │       └── categories_screen.dart  # Kelola kategori
│   ├── scan/
│   │   ├── ocr_service.dart           # Layanan OCR Google MLKit
│   │   ├── ai_parser_service.dart     # Layanan parsing DeepSeek API
│   │   ├── scan_provider.dart         # State machine proses scan
│   │   └── presentation/
│   │       └── scan_screen.dart       # Layar pemindaian struk
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart   # Pengaturan aplikasi
└── shared/
    └── widgets/
        ├── amount_card.dart           # Kartu jumlah dengan ikon
        ├── empty_state.dart           # Placeholder konten kosong
        ├── error_view.dart            # Tampilan error dengan tombol ulang
        └── loading_indicator.dart     # Indikator loading
```

## Pengembangan

### Menambahkan Fitur Baru

Proyek ini menggunakan arsitektur berbasis fitur dengan Riverpod untuk state management dan Drift untuk database. Untuk menambahkan fitur baru:

1. Tambahkan model/data di folder `features/<fitur>/domain/`.
2. Tambahkan screen di `features/<fitur>/presentation/`.
3. Tambahkan route di `core/router/app_router.dart`.
4. Generate kode: `dart run build_runner build`.

### Perintah Umum

```bash
# Generate kode (Drift, Riverpod)
dart run build_runner build

# Watch mode (generate otomatis saat file berubah)
dart run build_runner watch

# Clean dan rebuild
dart run build_runner clean && dart run build_runner build

# Analisis kode
flutter analyze

# Jalankan test
flutter test
```

### Catatan Pengembangan

- Semua jumlah uang disimpan sebagai integer (Rupiah tanpa desimal).
- ID record menggunakan UUID v4.
- Database berada di `catat_uang.db` dalam direktori dokumen aplikasi.
- Kategori default di-seed otomatis saat pertama kali aplikasi dijalankan.
- Mode gelap belum dipersist (kembali ke terang setiap restart aplikasi).
- Fitur penyimpanan hasil scan dari pratinjau masih dalam tahap pengembangan.
