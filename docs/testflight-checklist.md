# TestFlight Beta Test Checklist

Run-Jin (ラン陣) TestFlight beta testing checklist.

## Pre-Upload

- [ ] App builds in Release configuration without errors or warnings
- [ ] Bundle identifier: `app.space.k1t.run-jin`
- [ ] Version and build number are set correctly
- [ ] Info.plist contains all required privacy usage descriptions
- [ ] App icons provided for all required sizes
- [ ] Launch screen configured

## Core Flows

### Authentication
- [ ] Phone number SMS login works end-to-end
- [ ] New user registration flow completes
- [ ] Existing user login flow completes
- [ ] Session persists after app restart
- [ ] Logout clears session and returns to login screen

### Location & Permissions
- [ ] Location permission dialog appears with correct Japanese text
- [ ] "When In Use" permission grants map access
- [ ] "Always" permission enables background tracking
- [ ] App handles permission denied gracefully (shows guidance)
- [ ] Location accuracy indicator displays correctly on map

### Running Session
- [ ] Start a run from the main screen
- [ ] Route is drawn on map in real-time during run
- [ ] Distance, pace, and elapsed time update live
- [ ] Pause and resume run works correctly
- [ ] Finish run saves the session and shows summary
- [ ] Run continues tracking when app is in background
- [ ] Run continues tracking when screen is locked
- [ ] Battery usage is reasonable during a 30-minute run

### Territory (Hex Grid)
- [ ] Hex grid overlay renders on the map
- [ ] Running through cells captures them (color change)
- [ ] Captured territory count updates after run completion
- [ ] Territory is synced to server after run
- [ ] Existing territory loads correctly on app launch
- [ ] Map performance is acceptable when zooming/panning

### Run History
- [ ] Past runs appear in history list
- [ ] Run detail view shows route, stats, and captured territory
- [ ] History syncs between devices (same account)

### User Profile
- [ ] Profile screen shows user stats (total distance, territory count)
- [ ] Profile editing works (display name, avatar)

## Edge Cases

### Network
- [ ] App launches while offline (shows cached data)
- [ ] Run can start while offline
- [ ] Run data syncs when connection is restored
- [ ] Error messages display correctly for network failures

### Location
- [ ] App handles GPS signal loss during run (tunnel, indoor)
- [ ] App recovers when GPS signal returns
- [ ] No erratic route points during GPS drift
- [ ] App behaves correctly when location services are disabled system-wide

### Interruptions
- [ ] Incoming phone call during run does not lose data
- [ ] App switching during run preserves state
- [ ] Low memory warning does not crash the app
- [ ] App recovers correctly after being terminated by system during background run

### Device Compatibility
- [ ] iPhone SE (small screen) — UI elements accessible
- [ ] iPhone 15/16 Pro Max (large screen) — layout fills correctly
- [ ] iPad — orientation and layout adapts
- [ ] iOS 17 minimum version compatibility
- [ ] Dark mode and light mode display correctly

## Performance

- [ ] App launch time under 3 seconds
- [ ] Map scrolling is smooth (60fps)
- [ ] Memory usage stays reasonable during long runs (>1 hour)
- [ ] No excessive battery drain in background mode
- [ ] App size is under 200MB

## Crash & Stability

- [ ] No crashes during normal usage flows
- [ ] No crashes from rapid UI interactions (double-tap, fast navigation)
- [ ] No crashes when rotating device
- [ ] Check Xcode Organizer / TestFlight crash reports after beta period

## Localization

- [ ] All UI strings display in Japanese
- [ ] No untranslated English strings visible
- [ ] Date/time formatting follows Japanese locale
- [ ] Number formatting (distance, pace) follows Japanese locale

## Beta Feedback

- [ ] TestFlight feedback mechanism works (screenshot + send)
- [ ] Beta testers can access the app via invite link
- [ ] Beta expiration date is set appropriately (90 days max)
- [ ] What's New text is written in Japanese for each build
