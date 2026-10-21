# Implementasi Status Fuzzy Sensor

## Tujuan

Setiap pembacaan suhu, TDS, dan pH memperoleh:

- derajat keanggotaan `Baik`, `Cukup`, dan `Kurang`;
- status dominan;
- skor kualitas 0 sampai 100 untuk kurva gabungan.

Skor gabungan diperlukan karena ketiga sensor memiliki satuan berbeda. Nilai mentah suhu, TDS, dan pH tidak tepat jika digambar pada satu sumbu yang sama.

## Konfigurasi awal

Konfigurasi berada di:

`lib/domain/fuzzy_sensor_status.dart`

| Sensor | Kritis rendah | Cukup rendah | Ideal | Cukup tinggi | Kritis tinggi |
|---|---:|---:|---:|---:|---:|
| Suhu | ≤20°C | 20–24°C | 24–28°C | 28–32°C | ≥32°C |
| TDS | ≤50 PPM | 50–150 PPM | 150–300 PPM | 300–500 PPM | ≥500 PPM |
| pH | ≤5,0 | 5,0–6,5 | 6,5–7,5 | 7,5–9,0 | ≥9,0 |

Angka tersebut merupakan konfigurasi awal. Sesuaikan dengan spesies ikan, jenis tanaman, media tanam, serta target operasional akuaskap.

## Defuzzifikasi

Bobot status:

- Baik = 100
- Cukup = 60
- Kurang = 20

Rumus skor:

`score = (μBaik × 100 + μCukup × 60 + μKurang × 20) / Σμ`

Klasifikasi akhir:

- `score ≥ 80`: Baik
- `40 ≤ score < 80`: Cukup
- `score < 40`: Kurang

## File yang diubah

- `lib/domain/fuzzy_sensor_status.dart`
- `lib/card_row.dart`
- `lib/curve_card.dart`
- `lib/history_screen.dart`
- `lib/main.dart`
- `lib/services/api_service.dart`
- `php/Get_data.php`
- `test/fuzzy_sensor_status_test.dart`

## Catatan basis data

Versi ini menghitung status di Flutter dari nilai mentah. Metode ini menghindari duplikasi status dalam basis data dan membuat perubahan batas fuzzy lebih mudah.

Jika status historis harus tetap mengikuti konfigurasi pada saat data direkam, simpan juga `fuzzy_config_version` atau skor hasil evaluasi pada tabel sensor.
