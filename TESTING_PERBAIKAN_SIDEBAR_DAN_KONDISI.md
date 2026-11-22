# 🧪 TESTING GUIDE - PERBAIKAN SIDEBAR & KONDISI BARANG

**Date:** 2026-06-16  
**Version:** 1.0  
**Status:** Ready for Testing ✅

---

## 📋 SCOPE TESTING

Dua masalah yang sudah diperbaiki:

1. **MASALAH 1:** Sidebar active menu berubah saat navigasi ke halaman Kondisi/Penilaian
2. **MASALAH 2:** Update kondisi barang gagal dengan error "Validasi gagal"

---

## ✅ PRE-FLIGHT CHECKS

### Compilation Status

- [x] `flutter pub get` — Success
- [x] `flutter analyze` — No errors
- [x] `dart compile kernel` — Success
- [x] Dart syntax check — Passed

### Backend Status

- [x] Laravel routes `/barang/{id}` — Configured (PUT/POST)
- [x] BarangController.update() — Ready with RBS logic
- [x] InventoryRuleBasedService — Scoring logic verified
- [x] Barang model fillable — All score fields included
- [x] Database migrations — All score columns exist

### Code Changes Summary

| File                                               | Change                    | Lines            |
| -------------------------------------------------- | ------------------------- | ---------------- |
| `lib/core/router/route_meta.dart`                  | +2 regex patterns         | 15-20            |
| `lib/pages/barang/barang_penilaian_edit_page.dart` | +2 form fields            | +id & +barang_id |
| `lib/pages/barang/penilaian_kondisi_page.dart`     | Conditional update/create | ~10 lines        |

---

## 🧪 TEST PLAN

### TEST 1: Sidebar Active Menu (MASALAH 1)

**Objective:** Verifikasi sidebar tetap menunjuk ke "Perbaikan" saat di halaman Kondisi/Penilaian

#### Test Case 1.1: Navigate dari Perbaikan ke Penilaian

```
PRECONDITION:
- App running (flutter run)
- User logged in
- Berada di halaman Perbaikan

STEPS:
1. Lihat sidebar menu → "Perbaikan" highlighted/active
2. Klik tombol "Nilai Kondisi" untuk salah satu barang rusak
3. App navigate ke /inventaris/{id}/nilai-ulang
4. Halaman Penilaian Kondisi muncul dengan form kriteria

EXPECTED:
✅ Sidebar menu "Perbaikan" TETAP highlighted/active
✅ Breadcrumb: Perbaikan → Penilaian Kondisi
✅ Active menu tidak bergeser ke Dashboard/Inventaris/lainnya
```

#### Test Case 1.2: Navigate ke halaman Kondisi View

```
STEPS:
1. Dari Perbaikan page, klik "Detail Kondisi" (jika ada)
2. App navigate ke /inventaris/{id}/kondisi
3. Halaman detail kondisi barang muncul (view-only)

EXPECTED:
✅ Sidebar menu "Perbaikan" TETAP highlighted
✅ Kondisi badge dan informasi barang ditampilkan
```

#### Test Case 1.3: Breadcrumb Navigation

```
STEPS:
1. Dari halaman Penilaian/Kondisi, lihat breadcrumb
2. Klik "Perbaikan" di breadcrumb
3. Kembali ke halaman Perbaikan list

EXPECTED:
✅ Breadcrumb link active
✅ Menu highlight kembali ke Perbaikan
```

---

### TEST 2: Update Kondisi Barang (MASALAH 2)

**Objective:** Verifikasi scoring dan update kondisi bekerja end-to-end

#### Test Case 2.1: Isikan Semua Kriteria & Simpan

```
PRECONDITION:
- Berada di halaman Penilaian Kondisi (/inventaris/{id}/nilai-ulang)
- Form kriteria kosong (semua radio button default)

STEPS:
1. Pilih "Lengkap (L)" untuk Kelengkapan → score=3
2. Pilih "Berfungsi (Bf)" untuk Fungsional → score=3
3. Pilih "Bagus (Bg)" untuk Fisik → score=3
4. Pilih "< 3 tahun (Muda)" untuk Usia → score=3
5. Pilih "Baik (B)" untuk Perawatan → score=3
6. Pilih "Aman (Am)" untuk Keamanan → score=3
7. Lihat progress bar naik ke 100% (total=18)
8. Lihat kondisi badge → "Sangat Baik" (total >= 15)
9. Klik "Simpan"

EXPECTED:
✅ Dialog konfirmasi muncul: "Hasil Kondisi: Sangat Baik (Total 18)"
✅ Tidak ada error "Validasi gagal"
✅ Response from backend: "Kondisi barang berhasil diperbarui"
✅ Kembali ke halaman Perbaikan
✅ Kondisi badge barang updated ke "Sangat Baik"
✅ Database: barang.kondisi_barang = "Sangat Baik", total_score = 18
```

#### Test Case 2.2: Skor "Baik" (10-14 points)

```
STEPS:
1. Pilih scores: Lengkap(3) + BfS(2) + Bagus(3) + Muda(3) + Baik(2) + Aman(1) = 14
2. Lihat badge → "Baik" (10 <= total < 15)
3. Klik Simpan

EXPECTED:
✅ kondisi_barang updated to "Baik"
✅ total_score = 14
✅ Snackbar: "Kondisi barang berhasil diperbarui"
```

#### Test Case 2.3: Skor "Rusak" (< 10 points)

```
STEPS:
1. Pilih scores: TL(1) + TBf(1) + Jelek(1) + Tua(1) + Buruk(1) + Tidak(1) = 6
2. Lihat badge → "Rusak" (total < 10)
3. Klik Simpan

EXPECTED:
✅ kondisi_barang updated to "Rusak"
✅ total_score = 6
✅ Activity log created: "Kondisi X diubah dari [old] menjadi Rusak"
```

#### Test Case 2.4: Validasi Error Handling

```
STEPS:
1. Manually tampilkan network errors di DevTools
2. Klik Simpan dengan network disconnected
3. Observe error handling

EXPECTED:
✅ Loading spinner visible while saving
✅ Error message displayed in Snackbar
✅ Form NOT reset, user dapat retry
✅ No crash/exception thrown
```

---

### TEST 3: Database Persistence

**Objective:** Verifikasi data tersimpan dengan benar di database

#### Test Case 3.1: Check Barang Record

```
MYSQL QUERY:
SELECT id, nama_barang, kondisi_barang, total_score,
       kelengkapan_score, fungsional_score, fisik_score,
       usia_score, perawatan_score, keamanan_score
FROM barang WHERE id = {tested_id};

EXPECTED:
✅ All score fields populated with correct values (1-3)
✅ total_score = sum of all scores
✅ kondisi_barang = "Sangat Baik" OR "Baik" OR "Rusak"
✅ updated_at timestamp recent
```

#### Test Case 3.2: Check Activity Log

```
MYSQL QUERY:
SELECT * FROM activity_logs
WHERE barang_id = {tested_id}
AND activity_type = 'ubah_kondisi'
ORDER BY created_at DESC LIMIT 1;

EXPECTED:
✅ Record exists
✅ Description shows: "Kondisi {nama} diubah dari {old} menjadi {new}"
✅ Created by correct user
```

---

## 🐛 DEBUGGING TIPS

Jika ada error, check:

### Error: "Validasi gagal"

1. **Lihat response body:** Add `print(response.data)` di `penilaian_kondisi_page.dart`
2. **Check validation rules:** [UpdateBarangRequest.php](backend/app/Http/Requests/Barang/UpdateBarangRequest.php)
3. **Verify payload:**
   ```dart
   print('Payload: $payload');
   print('Barang ID: ${widget.form['barang_id']}');
   ```

### Error: Sidebar tidak berubah

1. **Check route location:** Add `debugPrint('Route: ${GoRouter.of(context).location}')` di main_app_shell.dart
2. **Verify route_meta match:** Test dengan `RouteMeta.fromLocation('/inventaris/5/nilai-ulang')`
3. **Check selectedIndex:** Lihat di AppSidebar widget construction

### Error: Update tidak masuk database

1. **Check service.update() call:** Verify `barangId > 0` condition
2. **Check Laravel logs:** `storage/logs/laravel.log`
3. **Check network tab:** DevTools network tab untuk melihat request/response

---

## 📊 TEST EXECUTION CHECKLIST

### Before Running Tests

- [ ] Flutter app compiled without errors
- [ ] Laravel backend running (`php artisan serve`)
- [ ] Database migrations run (`php artisan migrate`)
- [ ] Backend routes accessible
- [ ] Test device/emulator ready

### During Testing

- [ ] All test cases run
- [ ] Expected results match actual results
- [ ] No crashes or unhandled exceptions
- [ ] Snackbar messages display correctly
- [ ] Navigation works as expected

### After Testing

- [ ] Database records verified with MySQL query
- [ ] Activity logs created for kondisi changes
- [ ] Screenshots/logs collected for documentation
- [ ] All issues logged with screenshots

---

## ✅ SUCCESS CRITERIA

✅ **Semua 3 test groups PASSED:**

- Sidebar menu tetap active saat navigasi ke Kondisi/Penilaian
- Scoring form bisa input semua 6 kriteria
- Update kondisi barang berhasil tanpa error validasi
- Data persisten di database

✅ **No regressions:**

- Perbaikan list masih berfungsi
- Detail barang masih bisa dibuka
- Inventaris list masih normal

✅ **Performance:**

- Loading time < 2 detik
- No memory leaks
- Smooth navigation

---

## 📝 SIGN-OFF

| Item          | Status  | Notes             |
| ------------- | ------- | ----------------- |
| Compilation   | ✅ Pass | No errors         |
| Database      | ✅ Pass | Columns exist     |
| Backend Logic | ✅ Pass | RBS service ready |
| Frontend Code | ✅ Pass | Changes minimal   |
| Ready to Test | ✅ YES  | Deploy to device  |

**Next Step:** Run actual tests on Android emulator / iOS simulator / Physical device

---

## 🚀 QUICK START TESTING

```bash
# 1. Start backend
cd c:\xampp\htdocs\skripsirusdil\backend
php artisan serve

# 2. In new terminal, run Flutter
cd c:\xampp\htdocs\skripsirusdil
flutter run -d chrome  # atau -d emulator-5554 untuk Android

# 3. Test dari halaman Perbaikan:
- Klik barang rusak
- Input 6 kriteria scores
- Klik Simpan
- Verify sidebar tetap di Perbaikan
- Verify snackbar: "Kondisi barang berhasil diperbarui"
```

---

Generated: 2026-06-16 | Version: 1.0
