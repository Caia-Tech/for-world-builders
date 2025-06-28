# Pixel 9 Pro XL Setup Guide

Your device IS connected (Serial: 47271FDAS0090T) but USB debugging is not enabled.

## Step-by-Step Instructions:

### 1. Enable Developer Options (if not already done)
- Open **Settings** on your Pixel
- Scroll down to **About phone**
- Tap **Build number** 7 times rapidly
- You'll see "You are now a developer!"

### 2. Enable USB Debugging
- Go back to main **Settings**
- Tap **System**
- Tap **Developer options**
- Find **USB debugging** and toggle it ON
- A dialog will appear asking "Allow USB debugging?" - tap **OK**

### 3. When You Connect the USB Cable
- **IMPORTANT**: When you plug in the USB cable after enabling USB debugging, you should see a popup on your phone:
  - Title: "Allow USB debugging?"
  - Message: "The computer's RSA key fingerprint is..."
  - ✅ Check "Always allow from this computer"
  - Tap **Allow**

### 4. Check USB Mode
- Pull down your notification shade
- Look for a USB notification (might say "Charging this device via USB")
- Tap it and select **File Transfer** or **PTP**

## Quick Check
After completing the above, run:
```bash
./check-device.sh
```

You should see your Pixel 9 Pro XL listed!

## Troubleshooting
If still not working:
1. Try unplugging and replugging the USB cable
2. Try a different USB port
3. Make sure the cable supports data (not charge-only)
4. On your phone: Settings → Developer options → Revoke USB debugging authorizations → Then reconnect