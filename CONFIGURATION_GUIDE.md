# ⚙️ CONFIGURATION GUIDE - Setup for Different Environments

## Overview

This guide explains how to configure the Inventaris Instansi app for different environments:

- Android Emulator
- iOS Simulator
- Web Browser
- Physical Android Device
- Physical iOS Device
- Production Server

---

## 1️⃣ Android Emulator Setup

### **Default Configuration (Usually Works):**

```dart
// File: lib/core/constants/api_constants.dart
// When kIsWeb = false AND Platform.isAndroid:
// Automatically uses: http://10.0.2.2:8000/api
```

### **How It Works:**

- Android emulator has special IP `10.0.2.2` that points to host machine
- This is automatically configured - **no changes needed**
- `network_security_config.xml` allows cleartext HTTP to this IP

### **To Run:**

```bash
# Terminal 1: Start Backend
cd backend
php artisan serve

# Terminal 2: Start Emulator
flutter emulators --launch <emulator_name>

# Terminal 3: Run App
flutter run -d emulator
```

### **Verify Connection:**

1. Open app
2. Login with: `admin` / `password123`
3. Should see dashboard with data
4. Check terminal for logs confirming API calls

### **If It Doesn't Work:**

```bash
# 1. Verify backend is running on 8000
curl http://127.0.0.1:8000/api/me

# 2. Check emulator can reach 10.0.2.2
adb shell ping 10.0.2.2

# 3. Check network_security_config.xml includes 10.0.2.2
cat android/app/src/main/res/xml/network_security_config.xml

# 4. Rebuild app
flutter clean
flutter pub get
flutter run -d emulator
```

---

## 2️⃣ iOS Simulator Setup

### **Default Configuration:**

```dart
// File: lib/core/constants/api_constants.dart
// When kIsWeb = false AND Platform.isIOS:
// Automatically uses: http://127.0.0.1:8000/api
```

### **How It Works:**

- iOS simulator runs on host machine
- Uses localhost (127.0.0.1) to reach backend
- `Info.plist` allows HTTP and local network

### **To Run:**

```bash
# Terminal 1: Start Backend
cd backend
php artisan serve

# Terminal 2: Run App on iOS Simulator
flutter run -d "iPhone 15"
```

### **Verify Connection:**

1. Open app
2. Login with: `admin` / `password123`
3. Should see dashboard with data
4. Check console for logs

### **If It Doesn't Work:**

```bash
# 1. Verify Info.plist has network settings
cat ios/Runner/Info.plist | grep -A 5 NSAppTransportSecurity

# 2. Rebuild pods if dependency issues
cd ios
pod install
cd ..

# 3. Rebuild app
flutter clean
flutter pub get
flutter run -d "iPhone 15"

# 4. Check simulator network settings
open -a "Simulator"
# Simulate network change: Simulator > Device > Network > WiFi disabled/enabled
```

### **Common iOS Issues:**

- **"Could not communicate with Bonjour"** → This is OK, not an error
- **Network timeout** → Check NSLocalNetworkUsageDescription in Info.plist
- **SSL error** → Info.plist should have NSAllowsArbitraryLoads: true

---

## 3️⃣ Web Browser Setup

### **Default Configuration:**

```dart
// File: lib/core/constants/api_constants.dart
// When kIsWeb = true:
// Automatically uses: http://127.0.0.1:8000/api
```

### **How It Works:**

- Web browser runs on host machine
- Uses localhost (127.0.0.1) to reach backend
- CORS must be enabled on Laravel backend

### **To Run:**

```bash
# Terminal 1: Start Backend
cd backend
php artisan serve

# Terminal 2: Run App on Web
flutter run -d chrome
# or: flutter run -d firefox

# Or manually open: http://localhost:port
```

### **Verify CORS is Enabled:**

```bash
# Check config/cors.php has correct settings
cat backend/config/cors.php

# Should have:
# 'paths' => ['api/*'],
# 'allowed_methods' => ['*'],
# 'allowed_origins' => ['*'],
```

### **If It Doesn't Work:**

```bash
# 1. Check backend CORS config
grep -r "CORS" backend/config/

# 2. Check Laravel debug output
tail -f backend/storage/logs/laravel.log

# 3. Use browser DevTools
F12 > Network tab > check API calls
```

---

## 4️⃣ Physical Android Device Setup

### **Required Steps:**

#### **Step 1: Get Your Computer's IP Address**

```bash
# Windows CMD
ipconfig

# Look for line like: IPv4 Address . . . . . : 192.168.1.100
# Note this IP (example: 192.168.1.100)
```

#### **Step 2: Update API Configuration**

```dart
// File: lib/core/constants/api_constants.dart
// Line 10: Update deviceHost with your IP

static const String deviceHost = '192.168.1.100'; // YOUR IP HERE
```

#### **Step 3: Start Backend with Network Binding**

```bash
cd backend
php artisan serve --host=0.0.0.0

# This binds to all network interfaces
# Output: Local: http://127.0.0.1:8000
#         On Your Network: http://192.168.1.100:8000
```

#### **Step 4: Connect Device**

```bash
# USB Cable Method:
adb devices
flutter run -d <device_id>

# WiFi Method:
# 1. Connect device via USB first
# 2. adb tcpip 5555
# 3. Disconnect USB
# 4. adb connect <device_ip>:5555
# 5. flutter run -d <device_ip>:5555
```

#### **Step 5: Verify Connection**

1. Open app
2. Login with: `admin` / `password123`
3. Should see dashboard with data
4. Check terminal for logs

### **Network Requirements:**

- ✅ Device and computer on same WiFi network
- ✅ Device can ping computer: `ping 192.168.1.100`
- ✅ Computer's firewall allows port 8000
- ✅ Backend running with `--host=0.0.0.0`

### **If Connection Fails:**

```bash
# 1. Verify device can reach computer
# On device terminal:
ping 192.168.1.100

# 2. Test direct API call from device
# On computer terminal:
curl http://192.168.1.100:8000/api/me

# 3. Verify IP is correct
# On computer terminal:
ipconfig | findstr "IPv4"

# 4. Disable firewall temporarily for testing
# Windows Defender Firewall > Advanced Settings
# Add inbound rule for port 8000

# 5. Check network_security_config.xml includes your IP
cat android/app/src/main/res/xml/network_security_config.xml
```

### **Adding Multiple Device IPs:**

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<domain-config cleartextTrafficPermitted="true">
  <domain includeSubdomains="true">localhost</domain>
  <domain includeSubdomains="true">127.0.0.1</domain>
  <domain includeSubdomains="true">10.0.2.2</domain>
  <domain includeSubdomains="true">192.168.1.100</domain> <!-- Your IP -->
  <domain includeSubdomains="true">192.168.1.101</domain> <!-- Another IP -->
</domain-config>
```

---

## 5️⃣ Physical iOS Device Setup

### **Required (Must Have Mac):**

- Mac computer with Xcode
- iOS device with same WiFi

### **Steps:**

#### **Step 1: Get Your Computer's IP**

```bash
# Mac Terminal
ifconfig

# Look for line like: inet 192.168.1.100
# Note this IP
```

#### **Step 2: Update API Configuration**

```dart
// File: lib/core/constants/api_constants.dart
// Line 10: Update deviceHost

static const String deviceHost = '192.168.1.100'; // YOUR IP
```

#### **Step 3: Start Backend**

```bash
cd backend
php artisan serve --host=0.0.0.0
```

#### **Step 4: Connect Device**

```bash
# Method 1: Physical Cable
flutter run -d <device_uuid>

# Method 2: WiFi (after pairing with cable)
# Xcode > Product > Scheme > Edit Scheme
# Add destination for network device
```

#### **Step 5: Grant Permissions**

First run will ask:

- [ ] Camera access (tap "Allow")
- [ ] Photo library access (tap "Allow")
- [ ] Local network access (tap "Allow")

### **If Connection Fails:**

```bash
# 1. Check Mac firewall
# System Preferences > Security & Privacy > Firewall
# Port 8000 must be allowed

# 2. Verify device can reach Mac
# On device: open Safari
# Try: http://192.168.1.100:8000/api/me
# Should see JSON or error (not connection refused)

# 3. Check Info.plist network settings
grep -A 10 "NSAppTransportSecurity" ios/Runner/Info.plist

# 4. Try via cable first
xcode-select --install
flutter run -d
```

---

## 6️⃣ Production Server Setup

### **When Deploying to Real Server:**

#### **Update API URL:**

```dart
// File: lib/core/constants/api_constants.dart

static String get baseUrl {
  // Replace entire method with:
  return 'https://your-api-server.com/api'; // Your production URL
}
```

#### **Build for Production:**

```bash
# Android
flutter build apk --release

# iOS (requires Mac)
flutter build ios --release

# Web
flutter build web --release
```

#### **Key Changes for Production:**

1. Change to HTTPS (not HTTP)
2. Use real domain (not IP address)
3. Ensure SSL certificates valid
4. Update CORS on Laravel backend for production domain
5. Set strong authentication
6. Enable rate limiting
7. Use environment variables for sensitive data

---

## 🔍 Environment Comparison

| Setting          | Emulator      | Simulator      | Web            | Device    | Production |
| ---------------- | ------------- | -------------- | -------------- | --------- | ---------- |
| **Backend URL**  | 10.0.2.2:8000 | 127.0.0.1:8000 | 127.0.0.1:8000 | device IP | HTTPS URL  |
| **Protocol**     | HTTP          | HTTP           | HTTP           | HTTP      | HTTPS      |
| **Network**      | Virtual       | Virtual        | Local          | WiFi      | Internet   |
| **Config**       | Automatic     | Automatic      | Automatic      | Manual IP | Manual URL |
| **Certificates** | N/A           | N/A            | N/A            | N/A       | Required   |

---

## 🔐 Security Notes

### **Development Only:**

- ✅ HTTP is fine for development
- ✅ Device IP is fine for testing
- ✅ network_security_config.xml allows cleartext

### **Production Only:**

- ✅ MUST use HTTPS
- ✅ Must validate SSL certificates
- ✅ Hide API URLs in config files
- ✅ Use authentication tokens
- ✅ Implement rate limiting
- ✅ Log all API calls

---

## 📋 Quick Reference Checklist

### **Android Emulator:**

- [ ] Backend running: `php artisan serve`
- [ ] Emulator running
- [ ] Network auto-configured (10.0.2.2)
- [ ] Run: `flutter run -d emulator`

### **iOS Simulator:**

- [ ] Backend running: `php artisan serve`
- [ ] Run: `flutter run -d "iPhone 15"`
- [ ] Check Info.plist has network settings

### **Web Browser:**

- [ ] Backend running: `php artisan serve`
- [ ] CORS enabled on Laravel
- [ ] Run: `flutter run -d chrome`

### **Physical Device:**

- [ ] Get computer IP: `ipconfig` / `ifconfig`
- [ ] Update api_constants.dart with deviceHost
- [ ] Backend running: `php artisan serve --host=0.0.0.0`
- [ ] Device on same WiFi
- [ ] Device can ping computer
- [ ] Firewall allows port 8000
- [ ] Run: `flutter run -d <device_id>`

### **Production:**

- [ ] Change URL to HTTPS
- [ ] Update backend domain
- [ ] Build release APK/IPA/web
- [ ] Configure server certificates
- [ ] Enable CORS for production domain
- [ ] Test thoroughly before deployment

---

## 🆘 Common Configuration Issues

### **"Connection refused" on Android**

1. Check: `http://10.0.2.2:8000` not accessible?
2. Verify backend running on 8000
3. Verify network_security_config.xml includes 10.0.2.2
4. Rebuild: `flutter clean && flutter pub get && flutter run`

### **"Cannot connect" on iOS Simulator**

1. Check: `http://127.0.0.1:8000` accessible?
2. Verify backend running on 8000
3. Verify Info.plist has NSAppTransportSecurity
4. Rebuild pods: `cd ios && pod install && cd ..`

### **"CORS error" on Web**

1. Check Laravel config/cors.php
2. Verify `'allowed_origins' => ['*']`
3. Verify `'paths' => ['api/*']`
4. Restart backend

### **"Cannot reach IP" on Physical Device**

1. Get correct IP: `ipconfig` (not 127.0.0.1)
2. Update deviceHost in api_constants.dart
3. Device must be on same WiFi
4. Test with: `ping 192.168.1.100`
5. Check firewall allows port 8000

### **"Local network" error on iOS Device**

1. Check Info.plist has NSLocalNetworkUsageDescription
2. Grant permission when prompted
3. May need to wait 30 seconds after first permission

---

## ✅ Verification Commands

```bash
# Check backend running
curl http://127.0.0.1:8000/api/me -H "Accept: application/json"
# Expected: JSON or 401 error (not connection refused)

# Check device can reach computer (from device)
ping 192.168.1.100
# Expected: replies, not timeouts

# Check specific port
netstat -an | findstr "8000"  # Windows
lsof -i :8000                  # Mac/Linux
# Expected: listening on 0.0.0.0:8000 or 127.0.0.1:8000

# Verify Flutter sees device
flutter devices
# Expected: Shows connected device(s)

# Check logs while running
flutter logs
# Expected: Shows app logs and API calls
```

---

## 📚 Related Documentation

- **DEBUGGING_CHECKLIST.md** - Testing procedures
- **TESTING_GUIDE.md** - Test flows for all features
- **COMPLETE_CHANGELOG.md** - Technical details of all changes
- **README_FIXES.md** - Executive summary of fixes
- **api_constants.dart** - Source of truth for URLs

---

## 🎯 Summary

The app is **pre-configured** for:

- ✅ Android Emulator (10.0.2.2:8000)
- ✅ iOS Simulator (127.0.0.1:8000)
- ✅ Web Browser (127.0.0.1:8000)
- ⚙️ Physical Device (requires IP update)
- ⚙️ Production (requires URL + HTTPS update)

For most testing, **no configuration needed** - just start backend and run app!
