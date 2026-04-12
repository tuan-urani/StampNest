# Store Submission Kit (StampNest)

Prepared date: 2026-04-12
Project root: `/Users/uranidev/Documents/stamp_v2`

## 1) Data extracted from current codebase

### Core app identity
- App display name: `StampNest`
- Flutter package name: `stamp_camera`
- Version (`pubspec.yaml`): `1.0.0+1`
  - Marketing version: `1.0.0`
  - Build number / version code: `1`

### iOS (App Store)
- Bundle ID: `com.urani.stampnest`
- Team ID: `7797UMZFQR`
- Deployment target: iOS `13.0`
- Display name: `StampNest`
- Info.plist permissions:
  - Camera usage description exists
  - Photo library read usage description exists
  - Photo library add usage description exists

### Android (Google Play)
- Application ID: `com.urani.stampnest`
- Namespace: `com.urani.stampnest`
- App label: `StampNest`
- Manifest permissions:
  - `android.permission.CAMERA`
  - `android.permission.WRITE_EXTERNAL_STORAGE` (maxSdkVersion 28)
  - `android.permission.READ_EXTERNAL_STORAGE` (maxSdkVersion 32)
- Flutter SDK in local config: `3.38.5`
  - Flutter default `minSdkVersion`: `24`
  - Flutter default `targetSdkVersion`: `36`
  - Flutter default `compileSdkVersion`: `36`

### Legal/support content already in repo
- Privacy policy file: `web/privacy-policy.html`
- Terms file: `web/terms-of-use.html`
- Support email in legal pages: `stampnest.support@gmail.com`

## 2) Blocking items to fix before production upload

1. Android release signing is currently using debug keystore:
   - File: `android/app/build.gradle.kts`
   - Current config: `release { signingConfig = signingConfigs.getByName("debug") }`
   - Action: switch to upload/release keystore and enable Play App Signing flow.

2. Backend URL is placeholder:
   - File: `.env.prod`
   - Current value: `API_BASE_URL=https://api.example.com`
   - Action: set real production API endpoint before release.

3. Public policy URLs are still missing:
   - Current policy documents exist as local files bundled in app.
   - Store forms require live URL(s) (HTTPS) for policy/support pages.
   - Action: host privacy policy and terms online, then use those URLs in both stores.

## 3) App Store Connect input sheet

## App record creation
- Name: `StampNest`
- Primary language: `English (U.S.)` or your chosen default
- Bundle ID: `com.urani.stampnest`
- SKU: `TODO (e.g., STAMPNEST_IOS_001)`

## Required metadata to prepare
- Subtitle: `TODO`
- Description: `TODO`
- Keywords: `TODO`
- Support URL: `TODO (public HTTPS URL)`
- Marketing URL (optional): `TODO`
- Privacy Policy URL: `TODO (public HTTPS URL)`
- Category / secondary category: `TODO`
- Age rating questionnaire: `TODO`
- Copyright: `TODO`
- App Review contact:
  - First name / last name: `TODO`
  - Phone: `TODO`
  - Email: `TODO`
- Sign-in required for review? If yes, provide:
  - Demo username/password: `TODO`
  - Extra steps / OTP instruction: `TODO`

## iOS media assets checklist
- App icon in Xcode asset catalog (source recommended 1024x1024)
- Screenshots: 1 to 10 per required device class
- Optional app preview videos

## 4) Google Play Console input sheet

## App setup
- App name: `StampNest`
- App or game: `TODO`
- Free or paid: `TODO`
- Contact email (required): `stampnest.support@gmail.com` (or your final support email)
- Default language: `TODO`
- Package name (immutable): `com.urani.stampnest`

## Main store listing fields
- App name (max 30): `StampNest`
- Short description (max 80): `TODO`
- Full description (max 4000): `TODO`
- Category + tags: `TODO`
- Contact details:
  - Email (required): `TODO`
  - Website (recommended): `TODO`
  - Phone (optional): `TODO`

## Play App content declarations (must complete)
- Privacy policy URL
- Ads declaration (contains ads: yes/no)
- App access instructions (if login/restricted sections)
- Target audience and content
- Data safety form
- Content rating questionnaire
- Sensitive permissions declaration (if applicable)
- News app declaration (if applicable)

## Android media assets checklist
- App icon (required): 512x512 PNG
- Feature graphic (required): 1024x500 JPEG/PNG (no alpha)
- Screenshots (required): minimum 2 screenshots across supported device types

## 5) Suggested release build commands

## Android AAB (production)
```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --flavor prod --release --build-name 1.0.0 --build-number 1
```
Output (default): `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

## iOS IPA
```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build ipa --release --build-name 1.0.0 --build-number 1
```
Then upload via Xcode Organizer or Transporter.

## 6) Submission-day checklist (both stores)

- Confirm version/build numbers incremented correctly.
- Confirm production API endpoint is active.
- Confirm policy URLs are live and publicly reachable without login.
- Verify login flow with reviewer account (if app requires auth).
- Verify camera/gallery permission prompts match actual behavior.
- Test release build on real devices (Android + iOS) before upload.
- Prepare release notes (`What's New`) for first version or update.

## 7) Draft listing copy (ready to adapt)

## Google Play short description (<= 80 chars)
```text
Turn photos into collectible stamps and keep memories in themed boards.
```

## Google Play full description (draft)
```text
StampNest helps you capture moments and turn them into beautiful stamp-style memories.

What you can do with StampNest:
- Capture from camera or pick photos from your gallery
- Crop and save photos as stamps
- Organize stamps into collections
- Keep favorites and browse your memory timeline
- Arrange stamps on creative boards with drag, zoom, and rotate interactions

Designed for simple and personal memory keeping, StampNest gives you a playful way to store your moments in one place.
```

## App Store subtitle (draft)
```text
Turn moments into collectible stamps
```

## App Store keywords (draft)
```text
memory,stamp,photo,collection,journal,scrapbook,camera,gallery,album,story
```

## First release notes (draft)
```text
Welcome to StampNest 1.0.0
- Capture or import photos and create stamps
- Save and organize stamps in collections
- Build memory boards with easy editing gestures
- Added Privacy Policy and Terms of Use in Settings
```
