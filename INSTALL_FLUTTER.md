# 🔧 Installing Flutter on Windows

## Error You're Getting
```
flutter : The term 'flutter' is not recognized...
```

**Reason**: Flutter SDK is not installed or not in your system PATH.

---

## ✅ Complete Installation Guide

### **Step 1: Download Flutter SDK**

1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Click **Download Flutter SDK** (Windows version)
3. Extract the ZIP file to a location **without spaces**, like:
   ```
   C:\flutter
   ```
   ⚠️ DO NOT use: `C:\Program Files\flutter` (has spaces)

### **Step 2: Add Flutter to System PATH**

**For Windows 10/11:**

1. Press **Windows Key + X** → Open **System**
2. Click **Advanced system settings** (or search "Environment Variables")
3. Click **Environment Variables** button
4. Under "System variables", find or create **Path**
5. Click **Edit** → **New** → Add:
   ```
   C:\flutter\bin
   ```
6. Click **OK** three times
7. **Close all PowerShell/Command Prompt windows**

### **Step 3: Verify Installation**

Open a **NEW PowerShell/Command Prompt** and run:
```bash
flutter --version
```

You should see:
```
Flutter 3.x.x • channel stable
```

If you see a version number, ✅ **Flutter is installed!**

### **Step 4: Run Kepr App**

Navigate to kepr folder:
```bash
cd c:\Users\purus\OneDrive\Documents\A\kepr
flutter pub get
flutter run
```

---

## 🐛 Troubleshooting

### **Still says "flutter not recognized"?**

1. **Close all terminal windows** (including VS Code terminal)
2. **Restart your computer** (this helps PATH changes take effect)
3. Open a **NEW PowerShell window**
4. Try again: `flutter --version`

### **If it says "No connected devices"**

You need to either:
- Open **Android Emulator** (from Android Studio), OR
- Connect a physical Android/iOS device via USB

### **If it says "Android toolchain not found"**

Run:
```bash
flutter doctor
```

This will tell you what's missing. Usually just need to install Android SDK.

---

## ⚡ Quick PATH Verification

If unsure if Flutter is in PATH:

1. Open PowerShell
2. Run:
   ```bash
   echo $env:Path
   ```
3. Look for `C:\flutter\bin` in the output
4. If not there, repeat Step 2 above

---

## 📝 Alternative: Add Path Directly in PowerShell (Temporary)

If you don't want to restart, add Flutter to PATH temporarily:

```bash
$env:Path += ";C:\flutter\bin"
```

Then run:
```bash
flutter pub get
flutter run
```

⚠️ **Note**: This only works for the current PowerShell session. After closing PowerShell, you'll need to do it again.

---

## ✅ What to Do Next

1. **Install Flutter** following steps above
2. Run `flutter --version` to verify
3. Connect a device/emulator
4. Navigate to kepr folder
5. Run `flutter pub get`
6. Run `flutter run`

---

## 📞 Still Having Issues?

Check:
- ✅ Flutter extracted to `C:\flutter` (no spaces)
- ✅ `C:\flutter\bin` added to PATH
- ✅ PowerShell window restarted AFTER adding PATH
- ✅ Device connected or emulator running
- ✅ Internet connection (needed for first run)

Once Flutter is installed, you're all set! 🚀
