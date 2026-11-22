# 🧪 TESTING GUIDE - Quick Reference

## 📱 Before You Start

### **Required Setup:**

1. **Backend Running:**

   ```bash
   cd backend
   php artisan serve
   ```

   Expected output: `Local:   http://127.0.0.1:8000`

2. **Android Emulator** (if testing on Android):

   ```bash
   flutter emulators --launch <emulator_name>
   flutter run -d emulator
   ```

3. **Web Browser** (if testing on web):

   ```bash
   flutter run -d chrome
   # or firefox
   ```

4. **Physical Device** (if testing on device):
   - Update `lib/core/constants/api_constants.dart` line 10:
     ```dart
     static const String deviceHost = '192.168.1.100'; // Your IP
     ```
   - Find your IP: Windows CMD → `ipconfig` → IPv4 Address
   - Device must be on same WiFi as computer
   - Run: `flutter run -d <device_id>`

---

## ✅ Test Flow 1: Successful Login & Dashboard

### **Steps:**

1. **Open App** → Login page appears
2. **Enter Credentials:**
   - Username: `admin` (or `user`)
   - Password: `password123`
3. **Click "Masuk"** → Loading spinner shows
4. **Wait for load** → Dashboard page appears with:
   - [ ] Total Barang count
   - [ ] Barang Rusak count
   - [ ] Barang chart
   - [ ] Statistik summary
5. **Verify Layout:**
   - [ ] Header shows username
   - [ ] Bottom navigation visible
   - [ ] All text readable
   - [ ] No layout overflow

### **Success Indicators:**

✅ Dashboard loads within 2-3 seconds  
✅ All stats display correctly  
✅ No errors in console  
✅ Responsive layout on all screen sizes

---

## ❌ Test Flow 2: Failed Login (Invalid Credentials)

### **Steps:**

1. **Open App** → Login page appears
2. **Enter Invalid Credentials:**
   - Username: `admin`
   - Password: `wrongpassword`
3. **Click "Masuk"** → Loading spinner shows
4. **Wait for response** → Error banner appears below password field:
   ```
   ❌ Invalid credentials
   ```

### **Expected Behavior:**

- [ ] Error message appears (not crashes)
- [ ] Button remains clickable to retry
- [ ] Credentials cleared or ready to edit
- [ ] No white/blank screen

### **Success Indicators:**

✅ Error displayed gracefully  
✅ App responsive after error  
✅ Can retry immediately

---

## ❌ Test Flow 3: Network Error (Backend Down)

### **Setup:** Stop backend (Ctrl+C)

### **Steps:**

1. **Open App** → Login page appears
2. **Enter Credentials:** admin / password123
3. **Click "Masuk"** → Loading spinner shows
4. **Wait** → Error banner appears:
   ```
   ❌ Connection refused 
   ```

### **Expected Behavior:**

- [ ] Error message appears (not crashes)
- [ ] Clear indication that backend is offline
- [ ] Retry button available
- [ ] No white/blank screen loop

### **Recovery:**

1. Start backend: `php artisan serve`
2. Click "Coba Lagi" button
3. Login succeeds on retry

### **Success Indicators:**

✅ Network error handled gracefully  
✅ Retry functionality works  
✅ No force close

---

## 🏠 Test Flow 4: Navigate Dashboard → Inventaris → Detail

### **Prerequisites:** Logged in on Dashboard

### **Steps:**

1. **Click "Inventaris" in bottom nav** → Barang list page loads
2. **Verify List:**
   - [ ] Shows inventory items with images
   - [ ] Each item has: nama, kode, kategori, kondisi badge
   - [ ] Images load or show error gracefully
   - [ ] Skeleton loaders during initial load
3. **Click on any item** → Detail page loads showing:
   - [ ] Item image (full size)
   - [ ] All item details (nama, kode, tahun pembelian, ruangan, kategori, kondisi)
   - [ ] Edit and Delete buttons

### **Success Indicators:**

✅ No crashes during navigation  
✅ Images load properly  
✅ Detail page displays all info  
✅ Responsive on all screen sizes

---

## 🔍 Test Flow 5: Search & Filter Inventaris

### **Prerequisites:** On Inventaris List page

### **Steps:**

1. **Type in search box:** "meja" (or any partial item name)
2. **Verify results:**
   - [ ] Only items matching search appear
   - [ ] Results update in real-time
   - [ ] Shows count of matching items
3. **Select Kategori dropdown** → Choose "Meubelair"
4. **Verify filtered results:**
   - [ ] Only items of that category shown
   - [ ] Search filters still applied
5. **Clear search** → All items reappear

### **Success Indicators:**

✅ Search works instantly  
✅ Filter combinations work  
✅ No lag or freezes  
✅ Pagination updates correctly

---

## 📸 Test Flow 6: Image Loading & Error Handling

### **Steps:**

1. **Navigate to Barang List** → Images load
2. **Observe:**
   - [ ] Skeleton loader appears first
   - [ ] Images fade in smoothly
   - [ ] All images eventually display
3. **Force image error:**
   - Edit one item's `fotoUrl` in database to broken URL
   - Refresh page
   - [ ] Error icon appears instead of broken image
   - [ ] No crash
   - [ ] Rest of page still functional

### **Success Indicators:**

✅ Images load gracefully  
✅ Error handling works  
✅ No app freeze  
✅ User experience not interrupted

---

## 📊 Test Flow 7: Aktivitas (Activity Log)

### **Prerequisites:** Logged in

### **Steps:**

1. **Click "Aktivitas" in bottom nav** → Activity page loads
2. **Verify:**
   - [ ] Timeline of activities displays
   - [ ] Activities sorted by newest first
   - [ ] Each activity shows: icon, time, username, action, details
3. **Pull to refresh** → Re-loads activities

### **If Backend Down:**

- [ ] Error banner shows "Connection failed"
- [ ] Refresh button available

### **Success Indicators:**

✅ Activity log loads  
✅ Timeline displays correctly  
✅ Refresh works  
✅ Error handling works

---

## 🔧 Test Flow 8: Perbaikan (Maintenance Items)

### **Prerequisites:** Logged in

### **Steps:**

1. **Click "Perbaikan" in bottom nav** → Maintenance page loads
2. **Verify:**
   - [ ] Shows items with "Rusak" (Broken) condition
   - [ ] Each item has maintenance info
   - [ ] Search works to filter by item name
   - [ ] Can click items to view details
3. **If no broken items:**
   - [ ] Empty state message shows
   - [ ] No errors

### **Success Indicators:**

✅ Maintenance list loads  
✅ Broken items displayed  
✅ Search/filter work  
✅ Empty state handled

---

## 🔐 Test Flow 9: Logout

### **Prerequisites:** Logged in

### **Steps:**

1. **Click Profile icon** (bottom right)
2. **Click "Logout"** → Confirmation dialog appears
3. **Confirm logout** → Redirects to Login page
4. **Close app completely** → Reopen app
5. **Verify:** Login page appears (not dashboard)
   - [ ] Token cleared from device
   - [ ] Session properly ended
6. **Try logging in again** → Works successfully

### **Success Indicators:**

✅ Logout clears session  
✅ Token removed from storage  
✅ Must re-login after app restart  
✅ New login succeeds

---

## 📐 Test Flow 10: Responsive Layout (Mobile ↔ Desktop)

### **Prerequisites:** App open on web browser

### **Steps:**

1. **Open DevTools:** F12
2. **Toggle device toolbar:** Ctrl+Shift+M
3. **Test Mobile (375×667):**
   - [ ] All content visible without horizontal scroll
   - [ ] Search bar full width
   - [ ] Items stack vertically
   - [ ] Buttons appropriately sized for touch
   - [ ] No text cutoff

4. **Test Tablet (768×1024):**
   - [ ] Content centered
   - [ ] Sidebar appears if available
   - [ ] Touch-friendly spacing maintained

5. **Test Desktop (1920×1080):**
   - [ ] Table layout appears on Barang list
   - [ ] Content has margins
   - [ ] Mouse interactions work

### **Success Indicators:**

✅ No horizontal scroll on any size  
✅ Touch targets at least 48dp  
✅ Text readable at all sizes  
✅ Layout adapts smoothly

---

## 🚨 Critical Error Scenarios (Must Not Crash)

| Scenario          | What to Do                   | Expected Result            |
| ----------------- | ---------------------------- | -------------------------- |
| Backend down      | Attempt login                | Error banner, not crash    |
| Invalid route ID  | Access `/inventaris/abc`     | Error page, not crash      |
| Broken image URL  | Item with invalid image      | Error icon, rest works     |
| No search results | Search for non-existent item | "No results" message       |
| Null data         | Provider returns null        | Loading or empty state     |
| 401 Unauthorized  | Token expired                | Logout and return to login |
| 500 Server Error  | Backend error response       | Error banner with retry    |
| Network timeout   | No response for 30 seconds   | "Connection timeout" error |
| JSON decode error | Malformed API response       | "Invalid response" error   |

---

## 🎯 Testing Matrix

Use this matrix to track testing across platforms and features:

|                        | **Android** | **iOS** | **Web** |
| ---------------------- | :---------: | :-----: | :-----: |
| **Login - Success**    |     [ ]     |   [ ]   |   [ ]   |
| **Login - Invalid**    |     [ ]     |   [ ]   |   [ ]   |
| **Login - No Backend** |     [ ]     |   [ ]   |   [ ]   |
| **Dashboard Load**     |     [ ]     |   [ ]   |   [ ]   |
| **Barang List Load**   |     [ ]     |   [ ]   |   [ ]   |
| **Image Loading**      |     [ ]     |   [ ]   |   [ ]   |
| **Search/Filter**      |     [ ]     |   [ ]   |   [ ]   |
| **Navigation**         |     [ ]     |   [ ]   |   [ ]   |
| **Aktivitas Load**     |     [ ]     |   [ ]   |   [ ]   |
| **Perbaikan Load**     |     [ ]     |   [ ]   |   [ ]   |
| **Logout**             |     [ ]     |   [ ]   |   [ ]   |
| **Responsive**         |     [ ]     |   [ ]   |   [ ]   |
| **Error Recovery**     |     [ ]     |   [ ]   |   [ ]   |

---

## 📋 Test Results Template

```
Platform: [Android / iOS / Web / Device Model]
Date: [YYYY-MM-DD]
Build Version: [flutter run build number]

✅ PASSED:
- [Test case 1]
- [Test case 2]

❌ FAILED:
- [Test case]: [Error message]

⚠️ WARNINGS:
- [Issue that needs attention but not critical]

Notes:
[Any observations or issues encountered]

Tester: [Your name]
```

---

## 🐛 Debugging Tips

### **Android Emulator Issues:**

```bash
# View logs
flutter logs

# Rebuild if stuck
flutter clean
flutter pub get
flutter run

# Check network config
cat android/app/src/main/res/xml/network_security_config.xml
```

### **iOS Simulator Issues:**

```bash
# View logs
flutter logs

# Rebuild pods if dependency issues
cd ios
pod install
cd ..
flutter run -d "iPhone 15"
```

### **Network Issues:**

1. Verify backend running: `curl http://127.0.0.1:8000/api/me -H "Authorization: Bearer dummy"`
2. Check network config:
   - Android: `network_security_config.xml`
   - iOS: `Info.plist` NSAppTransportSecurity
3. Verify API URL in `api_constants.dart` matches backend

### **Still Crashing?**

1. Check console: `flutter logs -v`
2. Look for:
   - Null pointer exceptions
   - Network timeouts
   - JSON decode errors
3. Check corresponding provider/service for error handling

---

## ✨ Sign-Off Checklist

When all tests pass, mark as complete:

```
✅ All test flows passed on Android
✅ All test flows passed on iOS
✅ All test flows passed on Web
✅ No crashes encountered
✅ Error states handled gracefully
✅ Responsive layout verified
✅ Network error recovery works
✅ Login/logout flow tested
✅ Image loading tested
✅ Navigation tested
✅ Search/filter tested
✅ Database operations tested
✅ Ready for production
```
