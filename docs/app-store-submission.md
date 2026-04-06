# App Store Submission Checklist

Run-Jin (ラン陣) App Store submission preparation guide.

## App Store Connect Setup

### App Information
- [ ] App name: ラン陣 (Run-Jin)
- [ ] Subtitle (30 chars max): GPSランニング x 陣取りゲーム
- [ ] Bundle ID: `app.space.k1t.run-jin`
- [ ] SKU: run-jin
- [ ] Primary language: Japanese
- [ ] Category: Health & Fitness (primary), Games (secondary)
- [ ] Content rights: No third-party content requiring documentation

### Pricing & Availability
- [ ] Price: Free
- [ ] Availability: Japan (initial launch)
- [ ] Pre-orders: Disabled (unless planned)

### Version Information
- [ ] Version number set (1.0.0)
- [ ] Build number incremented for each upload
- [ ] "What's New" text written in Japanese

## App Store Listing

### Description (Japanese)
- [ ] Description written (up to 4000 chars)
- [ ] Keywords set (up to 100 chars, comma-separated)
- [ ] Promotional text (up to 170 chars, can be updated without new build)
- [ ] Support URL provided
- [ ] Marketing URL (optional)

### Screenshots (Required)
Screenshots must be provided for at minimum:
- [ ] **iPhone 6.7" (iPhone 15 Pro Max)**: 1290 x 2796 px — minimum 3, up to 10
- [ ] **iPhone 6.5" (iPhone 11 Pro Max)**: 1242 x 2688 px — minimum 3, up to 10
- [ ] **iPad Pro 12.9" (6th gen)**: 2048 x 2732 px (if supporting iPad)

Recommended screenshot content:
1. Map view with hex grid territory
2. Active running session with live stats
3. Run completion summary with captured territory
4. Run history / profile screen
5. Territory overview (zoomed out map)

### App Preview (Optional)
- [ ] Video preview (15-30 seconds, showing gameplay)
- [ ] Format: H.264, 30fps, portrait orientation

### App Icon
- [ ] 1024 x 1024 px icon uploaded to App Store Connect
- [ ] No alpha channel, no rounded corners (system applies them)
- [ ] Matches in-app icon design

## Privacy & Legal

### Privacy Policy
- [ ] Privacy policy URL hosted and accessible
- [ ] Policy covers:
  - Location data collection and usage
  - How running routes are stored
  - Territory data and public visibility
  - User account data (phone number)
  - Analytics data collected
  - Third-party services (Supabase, Firebase)
  - Data retention and deletion policy
  - Contact information for privacy inquiries
- [ ] Policy is available in Japanese

### App Privacy (Data Collection Labels)
Configure in App Store Connect under "App Privacy":

**Data Linked to You:**
- [ ] Location — Precise Location (used for running route tracking, territory capture)
- [ ] Contact Info — Phone Number (used for authentication)
- [ ] Identifiers — User ID (used for account management)

**Data Used to Track You:**
- [ ] Advertising data (if using ad tracking — NSUserTrackingUsageDescription)

**Data Not Linked to You:**
- [ ] Usage Data — Product Interaction (analytics)
- [ ] Diagnostics — Crash Data, Performance Data

### App Tracking Transparency
- [ ] ATT prompt implemented (NSUserTrackingUsageDescription in Info.plist)
- [ ] App functions correctly if user declines tracking
- [ ] Ad SDKs handle ATT opt-out gracefully

### Terms of Service
- [ ] Terms of service URL hosted and accessible
- [ ] Terms available in Japanese

## Technical Requirements

### Build Configuration
- [ ] Release build configuration used
- [ ] Bitcode: not required (Xcode 14+)
- [ ] Minimum deployment target: iOS 17.0
- [ ] Architectures: arm64
- [ ] Strip debug symbols enabled for release
- [ ] App Transport Security: no exceptions needed (all HTTPS)

### Entitlements
- [ ] Location services entitlement configured
- [ ] Background modes: location updates
- [ ] Push notifications (if applicable)

### Required Capabilities
- [ ] Location Services (GPS hardware)
- [ ] Verify `UIRequiredDeviceCapabilities` if needed

### Code Signing
- [ ] Distribution certificate valid and not expiring soon
- [ ] Provisioning profile: App Store distribution
- [ ] Team ID: 85693DB6BF

## Review Preparation

### App Review Information
- [ ] Contact information for reviewer (name, phone, email)
- [ ] Demo account credentials (if login required for review)
  - Provide a test phone number or alternative login for review
- [ ] Notes for reviewer explaining:
  - App requires location permission to function
  - Running feature requires physical movement (or explain how to test)
  - Territory capture requires GPS-tracked running session

### Common Rejection Reasons to Verify
- [ ] **Guideline 2.1 (Performance)**: App does not crash
- [ ] **Guideline 2.3 (Accuracy)**: Screenshots match actual app
- [ ] **Guideline 4.0 (Design)**: App provides sufficient functionality
- [ ] **Guideline 5.1.1 (Data Collection)**: Privacy labels match actual data collection
- [ ] **Guideline 5.1.2 (Data Use)**: Purpose strings explain why data is needed
- [ ] **Guideline 2.5.4 (Background)**: Background location justified by core functionality
- [ ] **Guideline 3.1.1 (Payments)**: No external payment mechanisms (if monetized)

### Background Location Justification
Apple scrutinizes background location usage. Be prepared to explain:
- Core feature: GPS route tracking during runs (must continue in background)
- Purpose string clearly states the need
- App does not track location when not in an active running session
- Distance filter and accuracy settings minimize battery impact

## Submission Steps

1. [ ] Archive the app in Xcode (Product > Archive)
2. [ ] Validate the archive (no errors)
3. [ ] Upload to App Store Connect via Xcode Organizer
4. [ ] Wait for processing (usually 15-30 minutes)
5. [ ] Select the build in App Store Connect
6. [ ] Fill in all version information, screenshots, and metadata
7. [ ] Complete App Privacy questionnaire
8. [ ] Submit for review
9. [ ] Monitor review status (typically 24-48 hours)
10. [ ] Address any reviewer feedback promptly

## Post-Submission

- [ ] Monitor crash reports in Xcode Organizer
- [ ] Respond to App Review feedback within 14 days
- [ ] Plan first update with bug fixes from beta feedback
- [ ] Set up App Store Connect analytics monitoring
