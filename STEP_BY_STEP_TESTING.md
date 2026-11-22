# 🎬 STEP-BY-STEP TESTING WALKTHROUGH

**Date:** 2026-06-16 | **Version:** 1.0

---

## 🚀 QUICK START (5 MINUTES)

### Step 1: Start Laravel Backend

```bash
cd c:\xampp\htdocs\skripsirusdil\backend
php artisan serve
# Output: Server running on http://127.0.0.1:8000
```

### Step 2: Start Flutter App

```bash
# In new terminal/PowerShell
cd c:\xampp\htdocs\skripsirusdil
flutter run -d chrome  # or -d emulator-5554 for Android
```

### Step 3: Login

- Username/Email: (use valid credentials)
- Password: (use valid password)

### Step 4: Navigate to Perbaikan

- Click "Perbaikan" in sidebar
- You should see list of "Rusak" barang

---

## ✅ TEST 1: Sidebar Active Menu

**Time:** 3 minutes | **Risk:** Low

### Scenario 1.1: Navigate to Penilaian Kondisi

```
STEP 1: Verify sidebar
├─ Look at sidebar menu
├─ Confirm "Perbaikan" is highlighted (background color different)
└─ Note the current highlight position

STEP 2: Click a barang card or row
├─ Click any barang "Nilai Kondisi" button
├─ Confirm loading spinner appears briefly
└─ Wait for Penilaian Kondisi page to load

STEP 3: Verify sidebar UNCHANGED
├─ Look at sidebar menu again
├─ ✅ EXPECTED: "Perbaikan" still highlighted
├─ ✅ EXPECTED: NO highlight moved to Dashboard/Inventaris/lainnya
├─ ✅ EXPECTED: Page title shows "Kondisi Barang" (or Penilaian Kondisi)
└─ If sidebar changed color → TEST FAILED ❌

STEP 4: Check breadcrumb (if visible)
├─ Look for breadcrumb navigation
├─ ✅ EXPECTED: Perbaikan > Penilaian Kondisi (or similar)
└─ Shows current navigation hierarchy
```

**Expected Result:**

```
✅ Sidebar "Perbaikan" menu stays highlighted
✅ No visual shift to other menu items
✅ Breadcrumb shows Perbaikan parent
```

**If Test Fails:**

- Check route_meta.dart line 15-20 was applied
- Verify regex patterns: `^/inventaris/\d+/nilai-ulang$`
- Check GoRouter location in DevTools console

---

## ✅ TEST 2: Kondisi Barang Update (Main Test)

**Time:** 10 minutes | **Risk:** Medium

### Scenario 2.1: Fill All 6 Criteria Scores (Sangat Baik)

```
STEP 1: Check form loads
├─ Page title: "Kondisi Barang" or "Penilaian Kondisi"
├─ 6 criteria sections visible:
│  1. Kelengkapan Inventaris
│  2. Fungsional Inventaris
│  3. Kesesuaian Fisik
│  4. Usia Pemakaian
│  5. Riwayat Perawatan
│  6. Keamanan
├─ Each section has 3 radio button options
└─ Total score value starts at 6 (1+1+1+1+1+1)

STEP 2: Set scores for "Sangat Baik" (total=18)
├─ Kelengkapan: Select "Lengkap (L)" → 3
├─ Fungsional: Select "Berfungsi (Bf)" → 3
├─ Fisik: Select "Bagus (Bg)" → 3
├─ Usia: Select "< 3 tahun (Muda)" → 3
├─ Perawatan: Select "Baik (B)" → 3
├─ Keamanan: Select "Aman (Am)" → 3
└─ After each select: Total score updates in real-time

STEP 3: Verify progress bar updates
├─ Look for progress indicator / progress bar
├─ Starting position: 0% (minimum scores)
├─ After selecting all high scores: 100% (or near max)
└─ ✅ EXPECTED: Smooth progress bar animation

STEP 4: Verify kondisi badge updates
├─ Look for condition badge/indicator
├─ Color: GREEN (Sangat Baik)
├─ Text: "Sangat Baik"
├─ Total score displayed: 18
└─ ✅ EXPECTED: Badge shows "Sangat Baik" with green color

STEP 5: Click "Simpan" button
├─ Button located at bottom of form
├─ Loading spinner appears
├─ Backend processing... (1-3 seconds)
└─ Wait for dialog or response

STEP 6: Verify confirmation dialog
├─ ✅ EXPECTED: Dialog title: "Hasil Kondisi"
├─ ✅ EXPECTED: Shows "Kondisi: Sangat Baik"
├─ ✅ EXPECTED: Shows "Total Nilai: 18"
├─ Two buttons: "Kembali" (cancel) and "Simpan" (confirm)
└─ Click "Simpan" in dialog

STEP 7: Verify success response
├─ ✅ EXPECTED: Snackbar message: "Kondisi barang berhasil diperbarui"
├─ ✅ EXPECTED: Message color: GREEN (success)
├─ ✅ EXPECTED: Auto-dismiss after 3-4 seconds
└─ NO error message should appear

STEP 8: Verify navigation back
├─ ✅ EXPECTED: Auto-navigate to /perbaikan page
├─ ✅ EXPECTED: Back on Perbaikan list
├─ ✅ EXPECTED: Sidebar "Perbaikan" still highlighted
└─ Page transitions smoothly

STEP 9: Check kondisi badge in list
├─ Find the barang you just updated
├─ ✅ EXPECTED: Badge changed to "Sangat Baik" (green)
├─ ✅ EXPECTED: Previous "Rusak" (red) is gone
└─ List refreshed automatically

SUCCESS CRITERIA:
✅ All 6 scores filled (1-3 each)
✅ Total score calculated correctly (18)
✅ Kondisi determined correctly ("Sangat Baik")
✅ No error "Validasi gagal"
✅ Snackbar shows success message
✅ Database persisted (check MySQL)
✅ Kondisi badge updated in list
```

**Database Verification (MySQL):**

```sql
SELECT id, nama_barang, kondisi_barang, total_score,
       kelengkapan_score, fungsional_score, fisik_score,
       usia_score, perawatan_score, keamanan_score,
       updated_at
FROM barang
WHERE id = [BARANG_ID_YOU_UPDATED]
LIMIT 1;

EXPECTED OUTPUT:
┌────┬──────────────┬──────────────┬─────────────┬───────────────┬──────────────┬───────────┐
│ id │ nama_barang  │ kondisi_bar. │ total_score │ kelengkapan_s │ fungsional_s │ ... (more)
├────┼──────────────┼──────────────┼─────────────┼───────────────┼──────────────┼───────────┤
│ 5  │ Meja Kayu    │ Sangat Baik  │ 18          │ 3             │ 3            │ 3...
└────┴──────────────┴──────────────┴─────────────┴───────────────┴──────────────┴───────────┘

✅ All score columns populated
✅ total_score = 18
✅ kondisi_barang = "Sangat Baik"
```

---

### Scenario 2.2: Fill Criteria for "Baik" (10-14 points)

```
STEP 1: Go back to Perbaikan
├─ Click "Perbaikan" in sidebar
└─ Back on barang list

STEP 2: Click different barang
├─ Select another "Rusak" barang
├─ Click "Nilai Kondisi"
└─ Penilaian form loads

STEP 3: Fill scores for "Baik" (total=12)
├─ Kelengkapan: Select "Lengkap (L)" → 3
├─ Fungsional: Select "Berfungsi Sebagian (BfS)" → 2
├─ Fisik: Select "Bagus (Bg)" → 3
├─ Usia: Select "3-5 tahun (Sedang)" → 2
├─ Perawatan: Select "Cukup (C)" → 1
├─ Keamanan: Select "Aman (Am)" → 1
└─ Total should = 3+2+3+2+1+1 = 12

STEP 4: Verify kondisi badge
├─ ✅ EXPECTED: Color: ORANGE (Baik)
├─ ✅ EXPECTED: Text: "Baik"
└─ ✅ EXPECTED: Condition correctly classified

STEP 5: Simpan
├─ Klik Simpan button
├─ Confirm in dialog
├─ ✅ EXPECTED: Success: "Kondisi barang berhasil diperbarui"
├─ ✅ EXPECTED: total_score = 12
├─ ✅ EXPECTED: kondisi_barang = "Baik"
└─ Navigate back to Perbaikan

STEP 6: Verify badge updated
├─ ✅ EXPECTED: Barang now shows orange badge "Baik"
└─ Updated in list
```

---

### Scenario 2.3: Fill Criteria for "Rusak" (< 10 points)

```
STEP 1: Go back to Perbaikan, select another barang

STEP 2: Fill scores for "Rusak" (total=6)
├─ Kelengkapan: Select "Tidak Lengkap (TL)" → 1
├─ Fungsional: Select "Tidak Berfungsi (TBf)" → 1
├─ Fisik: Select "Jelek (J)" → 1
├─ Usia: Select "> 10 tahun (Tua)" → 1
├─ Perawatan: Select "Buruk (Bu)" → 1
├─ Keamanan: Select "Tidak Aman (TA)" → 1
└─ Total = 1+1+1+1+1+1 = 6

STEP 3: Verify kondisi badge
├─ ✅ EXPECTED: Color: RED (Rusak)
├─ ✅ EXPECTED: Text: "Rusak"
└─ Total score displayed: 6

STEP 4: Simpan & verify
├─ Klik Simpan → Confirm
├─ ✅ EXPECTED: "Kondisi barang berhasil diperbarui"
├─ ✅ EXPECTED: kondisi_barang = "Rusak"
├─ ✅ EXPECTED: total_score = 6
└─ Activity log created: "Kondisi X diubah dari [old] menjadi Rusak"
```

---

## ❌ TEST 3: Error Handling

**Time:** 5 minutes | **Risk:** Low

### Scenario 3.1: Network Error

```
STEP 1: Simulate network failure
├─ Open Chrome DevTools (F12)
├─ Go to Network tab
├─ Find and block requests to /barang/* (throttle network)
└─ Or disable internet temporarily

STEP 2: Fill form & Simpan
├─ Select all criteria
├─ Click Simpan button
├─ Observe loading spinner

STEP 3: Verify error handling
├─ ✅ EXPECTED: Loading spinner shows for a moment
├─ ✅ EXPECTED: Error snackbar appears
├─ ✅ EXPECTED: Message: "Network error" or similar
├─ ✅ EXPECTED: Form NOT reset (user can see what they filled)
├─ ✅ EXPECTED: Retry possible (button clickable again)
└─ ✅ NO crash / blank screen

STEP 4: Re-enable network
├─ Remove network block
├─ Click Simpan again
├─ ✅ EXPECTED: Now succeeds
```

---

## 📊 TEST SUMMARY FORM

Fill this after testing:

```
TEST EXECUTION SUMMARY
=====================

Date: ________________
Tester: ______________
Device: _____________ (Chrome / Android Emulator / iOS Simulator / Physical)
Flutter Version: ____
Laravel API: ________ (URL/Status)

TEST 1: Sidebar Active Menu
├─ Test 1.1 (Navigate to Penilaian): ☐ PASS  ☐ FAIL
├─ Test 1.2 (Navigate to Kondisi): ☐ PASS  ☐ FAIL
├─ Test 1.3 (Breadcrumb): ☐ PASS  ☐ FAIL
└─ Overall Status: ☐ PASS  ☐ FAIL

TEST 2: Kondisi Update
├─ Test 2.1 (Sangat Baik - 18 pts): ☐ PASS  ☐ FAIL
├─ Test 2.2 (Baik - 12 pts): ☐ PASS  ☐ FAIL
├─ Test 2.3 (Rusak - 6 pts): ☐ PASS  ☐ FAIL
├─ Database verification: ☐ PASS  ☐ FAIL
└─ Overall Status: ☐ PASS  ☐ FAIL

TEST 3: Error Handling
├─ Network error handling: ☐ PASS  ☐ FAIL
└─ Overall Status: ☐ PASS  ☐ FAIL

OVERALL RESULT
==============
All Tests: ☐ PASS  ☐ FAIL

Issues Found:
1. _____________________________________
2. _____________________________________
3. _____________________________________

Sign-Off: ____________________  Date: __________
```

---

## 🔍 DEBUGGING COMMANDS

If something fails, use these:

### Check Flutter Logs

```bash
flutter run -v 2>&1 | grep -i "error\|exception\|failed"
```

### Check Laravel Logs

```bash
cd backend
tail -f storage/logs/laravel.log
```

### Check Network Requests (DevTools)

```
Chrome: F12 → Network tab
Look for: PUT /api/barang/{id}
Expected: 200 OK response with updated barang JSON
```

### Check Database Directly

```bash
mysql -u root inventaris_instansi

# Then run:
SELECT * FROM barang WHERE id = 5;
SELECT * FROM activity_logs WHERE barang_id = 5 ORDER BY created_at DESC LIMIT 5;
```

---

## ✅ FINAL CHECKLIST

Before signing off:

- [ ] Test 1: Sidebar menu stays on Perbaikan ✅
- [ ] Test 2.1: Sangat Baik update works (18 pts)
- [ ] Test 2.2: Baik update works (12 pts)
- [ ] Test 2.3: Rusak update works (6 pts)
- [ ] Database: All scores persisted correctly
- [ ] Activity log: Kondisi change logged
- [ ] Error handling: Network errors handled gracefully
- [ ] No crashes: App stable throughout testing
- [ ] No regressions: Other features still work

---

**Status: Ready for Testing!** ✅

Generated: 2026-06-16 | Version: 1.0
