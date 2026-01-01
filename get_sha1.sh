#!/bin/bash

echo "Getting SHA-1 fingerprint for Google Sign-In..."
echo ""

# Try to find keytool
KEYTOOL_PATH=$(which keytool 2>/dev/null)

if [ -z "$KEYTOOL_PATH" ]; then
    # Try common Java locations
    if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/keytool" ]; then
        KEYTOOL_PATH="$JAVA_HOME/bin/keytool"
    elif [ -f "$HOME/Library/Android/sdk/jbr/bin/keytool" ]; then
        KEYTOOL_PATH="$HOME/Library/Android/sdk/jbr/bin/keytool"
    elif [ -f "$HOME/.android/sdk/jbr/bin/keytool" ]; then
        KEYTOOL_PATH="$HOME/.android/sdk/jbr/bin/keytool"
    fi
fi

if [ -z "$KEYTOOL_PATH" ]; then
    echo "ERROR: keytool not found!"
    echo ""
    echo "Please install Java JDK or use Android Studio's JDK."
    echo "You can also run this command manually:"
    echo ""
    echo "keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
    exit 1
fi

echo "Using keytool at: $KEYTOOL_PATH"
echo ""
echo "SHA-1 Fingerprint:"
echo "----------------------------------------"
$KEYTOOL_PATH -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -A 1 "SHA1:"
echo "----------------------------------------"
echo ""
echo "Copy the SHA-1 value above and add it to Firebase Console:"
echo "1. Go to Firebase Console > Project Settings > Your Apps"
echo "2. Select your Android app (com.example.baitap)"
echo "3. Click 'Add fingerprint'"
echo "4. Paste the SHA-1 value"
echo "5. Download the new google-services.json"

