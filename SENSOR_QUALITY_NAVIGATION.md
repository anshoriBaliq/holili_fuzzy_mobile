# Navigasi Indeks Kualitas Sensor Realtime

## Perubahan perilaku

Kartu suhu, TDS, dan pH pada halaman utama sekarang dapat diketuk. Kartu yang
dipilih membuka halaman `SensorQualityPage` dengan sensor terkait sebagai sensor
aktif pertama.

Contoh:

- Kartu Suhu membuka halaman indeks dengan Suhu terpilih.
- Kartu TDS membuka halaman indeks dengan TDS terpilih.
- Kartu pH membuka halaman indeks dengan pH terpilih.

Kartu kurva indeks kualitas tidak lagi ditampilkan langsung pada halaman utama.

## Isi halaman indeks

Halaman indeks menampilkan:

1. Pemilih Suhu, TDS, dan pH.
2. Nilai realtime sensor yang dipilih.
3. Status Baik, Cukup, atau Kurang.
4. Skor fuzzy 0 sampai 100.
5. Derajat keanggotaan Baik, Cukup, dan Kurang.
6. Waktu pembaruan data terakhir.
7. Kurva kualitas gabungan ketiga sensor.

Garis sensor yang dipilih dibuat lebih tebal. Dua garis lain tetap tampil dengan
opasitas rendah agar hubungan antar-sensor tetap dapat dibaca.

## Polling realtime

`SensorQualityPage` mengambil 15 data sensor terbaru setiap tiga detik. Ketika
halaman indeks terbuka, polling pada halaman utama dihentikan sementara. Hal ini
mencegah dua request realtime berjalan bersamaan. Polling halaman utama dimulai
kembali setelah pengguna menutup halaman indeks.

## File baru

- `lib/sensor_quality_page.dart`
- `lib/domain/sensor_type.dart`

## File diperbarui

- `lib/card_row.dart`
- `lib/curve_card.dart`
