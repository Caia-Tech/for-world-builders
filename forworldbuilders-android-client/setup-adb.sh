#!/bin/bash

# Add Android SDK tools to PATH for current session
export PATH=$PATH:/Users/owner/Library/Android/sdk/platform-tools

echo "✅ Added adb to PATH for this session"
echo "You can now use 'adb' directly"
echo ""
echo "To make this permanent, add this line to your ~/.zshrc or ~/.bash_profile:"
echo 'export PATH=$PATH:/Users/owner/Library/Android/sdk/platform-tools'