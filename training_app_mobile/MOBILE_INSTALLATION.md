# Training App Mobile Installation Guide

This guide will help you install and run the Training App Flutter mobile application on your phone.

## Prerequisites

Before you begin, ensure you have:
- A computer with Flutter SDK installed
- USB cable to connect your phone to computer
- Android phone (Android 5.0+ / API level 21+) or iOS device (iOS 11.0+)

## Method 1: Install via Flutter (Recommended for Development)

### For Android Devices

#### Step 1: Enable Developer Options
1. Open **Settings** on your Android device
2. Scroll down and tap **About phone** (or **About device**)
3. Find **Build number** and tap it **7 times**
4. You should see a message saying "You are now a developer!"

#### Step 2: Enable USB Debugging
1. Go back to **Settings**
2. Look for **Developer options** (usually under System or Advanced)
3. Enable **USB debugging**
4. Enable **Install via USB** (if available)

#### Step 3: Connect and Install
1. Connect your Android device to your computer via USB
2. When prompted on your phone, allow USB debugging for this computer
3. Open terminal/command prompt on your computer
4. Navigate to the Flutter project directory:
   ```bash
   cd /path/to/trainingApp/training_app_mobile
   ```
5. Check if your device is recognized:
   ```bash
   flutter devices
   ```
6. Install and run the app:
   ```bash
   flutter run
   ```

### For iOS Devices (macOS only)

#### Step 1: Set up iOS Development
1. Install Xcode from the App Store
2. Open Xcode and accept the license agreement
3. Install Xcode command line tools:
   ```bash
   sudo xcode-select --install
   ```

#### Step 2: Connect Device
1. Connect your iOS device to your Mac via USB
2. Trust the computer when prompted on your device
3. In Xcode, go to **Window > Devices and Simulators**
4. Select your device and click **Use for Development**

#### Step 3: Install App
1. Open terminal and navigate to the project:
   ```bash
   cd /path/to/trainingApp/training_app_mobile
   ```
2. Run the app:
   ```bash
   flutter run
   ```

## Method 2: Install APK (Android Only)

### Step 1: Build APK
On your computer, build the APK file:
```bash
cd /path/to/trainingApp/training_app_mobile
flutter build apk --release
```

The APK will be created at: `build/app/outputs/flutter-apk/app-release.apk`

### Step 2: Transfer APK to Phone
Choose one of these methods:

**Option A: USB Transfer**
1. Connect your phone to computer via USB
2. Copy `app-release.apk` to your phone's Downloads folder

**Option B: Cloud Storage**
1. Upload the APK to Google Drive, Dropbox, or similar
2. Download it on your phone

**Option C: Email**
1. Email the APK file to yourself
2. Download the attachment on your phone

### Step 3: Install APK
1. On your Android device, go to **Settings > Security**
2. Enable **Install unknown apps** or **Unknown sources**
3. Open your file manager and navigate to where you saved the APK
4. Tap the APK file and follow the installation prompts

## Method 3: App Store Distribution (Production)

For production deployment, the app would need to be published to official app stores:

### Android (Google Play Store)
1. Build an App Bundle:
   ```bash
   flutter build appbundle --release
   ```
2. Upload to Google Play Console
3. Users install via Play Store

### iOS (Apple App Store)
1. Build for iOS:
   ```bash
   flutter build ipa --release
   ```
2. Upload to App Store Connect via Xcode
3. Users install via App Store

## Troubleshooting

### Common Android Issues

**Device not recognized:**
- Ensure USB debugging is enabled
- Try different USB cable or port
- Install device-specific USB drivers

**Installation failed:**
- Check available storage space
- Disable antivirus temporarily
- Clear cache: `flutter clean && flutter pub get`

**App won't start:**
- Check minimum Android version (5.0+)
- Restart the device
- Check device logs: `flutter logs`

### Common iOS Issues

**Code signing errors:**
- Ensure you have a valid Apple Developer account
- Configure signing in Xcode
- Check provisioning profiles

**Device not trusted:**
- Go to Settings > General > Device Management
- Trust the developer certificate

### Network Configuration

The app connects to your backend API. Ensure:

1. **Backend is running** on your development machine
2. **Network accessibility**:
   - If using localhost, your phone and computer must be on the same WiFi network
   - Update API base URL in the app if needed
3. **Firewall settings** allow connections on the backend port

To update the API URL, modify:
```dart
// lib/services/api_client.dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api';
```

Replace `YOUR_COMPUTER_IP` with your computer's local IP address (e.g., `192.168.1.100`).

## First Run Setup

When you first open the app:

1. **Register a new account** or **login** if you already have one
2. The app will connect to your backend API
3. You can start creating exercise types and exercises

## Performance Tips

- **Close background apps** for better performance
- **Ensure stable WiFi connection** for API calls
- **Restart the app** if you experience slowdowns

## Need Help?

If you encounter issues:
1. Check this troubleshooting section
2. Review Flutter device setup: https://docs.flutter.dev/get-started/install
3. Check your backend API is running and accessible
4. Ensure your phone meets minimum system requirements

---

**System Requirements:**
- **Android:** 5.0+ (API level 21+), 2GB RAM minimum
- **iOS:** 11.0+, 2GB RAM minimum
- **Storage:** 100MB free space
- **Network:** WiFi or mobile data connection