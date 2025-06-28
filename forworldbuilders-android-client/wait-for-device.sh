#!/bin/bash

echo "🔍 Waiting for Pixel 9 Pro XL to connect with USB debugging..."
echo "Please follow the steps in PIXEL_SETUP.md"
echo ""
echo "Current status:"

# Check every 2 seconds
while true; do
    DEVICES=$(/Users/owner/Library/Android/sdk/platform-tools/adb devices | grep -v "List of devices" | grep -v "^$")
    
    if [ ! -z "$DEVICES" ]; then
        echo ""
        echo "✅ Device found!"
        /Users/owner/Library/Android/sdk/platform-tools/adb devices -l
        echo ""
        echo "Installing app..."
        /Users/owner/Library/Android/sdk/platform-tools/adb install app/build/outputs/apk/debug/app-debug.apk
        break
    else
        echo -ne "\r⏳ No device found. Make sure USB debugging is ON and authorized... "
    fi
    
    sleep 2
done