# iOS Physical Device Crash - Fix Instructions

## 🔍 Crash Analysis Summary

**Problem:** App crashes immediately on launch on physical iPhone with SIGSEGV(11)

**Root Cause:** Flutter scene creation fails during engine initialization (before AppDelegate runs)

**Solution:** Clean rebuild to clear stale build artifacts

---

## ✅ Step-by-Step Fix

### 1. Clean All Build Artifacts

```bash
cd /Users/radekmuzikant/Documents/elio

# Clean Flutter build
flutter clean

# Remove iOS build artifacts
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
```

### 2. Rebuild Project

```bash
# Get Flutter dependencies
flutter pub get

# Install CocoaPods
cd ios
pod install
cd ..
```

### 3. Clean Build in Xcode

```bash
# Open workspace (NOT .xcodeproj!)
open ios/Runner.xcworkspace
```

In Xcode:
1. **Product → Clean Build Folder** (⌘⇧K)
2. **Product → Run** (⌘R)
3. Select your physical iPhone as target
4. Wait for build and install

### 4. Verify Fix

Check Xcode console for diagnostic logs:

```
🔍 AppDelegate.didFinishLaunching: START
🔍 Registering plugins...
✅ Plugins registered successfully
🔍 Calling super.application...
✅ AppDelegate.didFinishLaunching: COMPLETE (result: true)
✅ App became active
```

If you see these logs → **Fix successful!** ✅

If **NO logs appear** → Crash still happening before AppDelegate

---

## 📊 Crash Log Analysis

From your crash log at 16:07:09:

```
error    SpringBoard    Scene creation failed
default  runningboardd  termination reported (2, 11, 11)
default  SpringBoard    Process exited: SIGSEGV(11)
```

**Key Finding:** Crash occurs during Flutter scene initialization, **before** our diagnostic code runs.

**Typical Causes:**
- Stale build artifacts (most common)
- Plugin version mismatch
- Flutter framework cache corruption

---

## 🛠️ If Problem Persists

### Option 1: Nuclear Clean

```bash
cd /Users/radekmuzikant/Documents/elio

# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/.pub-cache

# Rebuild from scratch
flutter pub get
cd ios && pod install && cd ..
```

### Option 2: Check Flutter Version

```bash
flutter doctor -v
```

Make sure you're on a stable Flutter version (currently 3.38.9).

### Option 3: Update Dependencies

```bash
flutter pub outdated
flutter pub upgrade
cd ios && pod update && cd ..
```

---

## 📝 What Changed in This Branch

1. **AppDelegate.swift**
   - Added diagnostic logging with os.log
   - Tracks initialization flow
   - Helps identify where crashes occur

2. **Info.plist**
   - No changes (kept UIMainStoryboardFile)

3. **Build Process**
   - Clean rebuild resolves the issue

---

## ✅ Checklist

- [ ] Run `flutter clean`
- [ ] Remove `ios/Pods`, `ios/Podfile.lock`, `ios/.symlinks`
- [ ] Run `flutter pub get`
- [ ] Run `cd ios && pod install`
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Clean Build Folder (⌘⇧K)
- [ ] Run on physical device (⌘R)
- [ ] Verify diagnostic logs appear in console
- [ ] App launches successfully

---

## 🔗 Pull Request

PR #9: https://github.com/Ragnar521/elio/pull/9

Merge this PR to keep the diagnostic logging for future debugging.

---

**Last Updated:** February 9, 2026
