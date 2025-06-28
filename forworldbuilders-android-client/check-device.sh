#!/bin/bash

# Check if device is connected
echo "Checking for connected Android devices..."
/Users/owner/Library/Android/sdk/platform-tools/adb devices -l

# If device is connected, show more info
if [ $(/Users/owner/Library/Android/sdk/platform-tools/adb devices | wc -l) -gt 2 ]; then
    echo -e "\n✅ Device found! Getting device info..."
    /Users/owner/Library/Android/sdk/platform-tools/adb shell getprop ro.product.model
    /Users/owner/Library/Android/sdk/platform-tools/adb shell getprop ro.build.version.release
else
    echo -e "\n❌ No devices found. Please check:"
    echo "1. Developer Options is enabled"
    echo "2. USB Debugging is turned ON"
    echo "3. You've authorized this computer on your phone"
    echo "4. Try a different USB cable or port"
fi