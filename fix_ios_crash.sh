#!/bin/bash

# iOS Crash Fix Script
# Run this script to perform a clean rebuild and fix the launch crash

set -e  # Exit on error

echo "🧹 iOS Crash Fix - Clean Rebuild"
echo "================================="
echo ""

# Step 1: Flutter Clean
echo "Step 1/5: Cleaning Flutter build artifacts..."
flutter clean
echo "✅ Flutter clean complete"
echo ""

# Step 2: Remove iOS artifacts
echo "Step 2/5: Removing iOS build artifacts..."
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
echo "✅ iOS artifacts removed"
echo ""

# Step 3: Get Flutter dependencies
echo "Step 3/5: Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies downloaded"
echo ""

# Step 4: Install CocoaPods
echo "Step 4/5: Installing CocoaPods..."
cd ios
pod install
cd ..
echo "✅ CocoaPods installed"
echo ""

# Step 5: Instructions for Xcode
echo "Step 5/5: Manual steps in Xcode"
echo "================================="
echo ""
echo "✅ Clean rebuild preparation complete!"
echo ""
echo "📱 Now open Xcode and:"
echo "   1. Run: open ios/Runner.xcworkspace"
echo "   2. Product → Clean Build Folder (⌘⇧K)"
echo "   3. Select your physical iPhone"
echo "   4. Product → Run (⌘R)"
echo ""
echo "🔍 Look for diagnostic logs in Xcode console:"
echo "   🔍 AppDelegate.didFinishLaunching: START"
echo "   ✅ Plugins registered successfully"
echo "   ✅ AppDelegate.didFinishLaunching: COMPLETE"
echo ""
echo "If you see these logs, the fix worked! 🎉"
echo ""

# Optionally open Xcode workspace
read -p "Open Xcode workspace now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    open ios/Runner.xcworkspace
    echo "✅ Xcode workspace opened"
fi

echo ""
echo "📋 Full instructions: See IOS_CRASH_FIX.md"
echo "🔗 Pull Request: https://github.com/Ragnar521/elio/pull/9"
