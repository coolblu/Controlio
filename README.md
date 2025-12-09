# Final Release README - Controlio - Group 14

**Group number:** 14  
**Team members:** Masayuki Yamazaki, Avis Luong, Evan Weng, Jerry Lin  
**Name of project:** Controlio  
**Dependencies:** Firebase iOS SDK 12.4.0, Google Sign-in 9.0.0, Xcode 16+, Swift 5.10+  
**Requires:** iOS 18.5+

---

## Special Instructions

### Trackpad Usage
- Run the receiver program first
  - In XCode under Product, set the scheme to ControlioReceiver and the destination to My Mac
- Go to the Accessibility settings on the Mac under Privacy and Security and add the built program to Accessibility permissions
  - To get the build path, go to XCode and click on Products -> Show Build Folder in finder -> go to the debug folder and your .app should be there
- Rerun the app after adding permissions
- Then in XCode, click on debug on the top -> Detach from ControlioReceiver
- Now, you can change the scheme to Controlio
- Enable development mode on iPhone under Privacy and Security
- In XCode, select the iOS target (Controlio) and access Signing & Capabilities
  - Ensure team is set
  - Change the bundle identifier to something unique
- Plug in your iPhone
  - Choose the device as the running destination under Product
  - On the first run, you will get a trust/signing warning
    - On the iPhone go to Settings -> General -> VPN & Device Management -> Click on the app and trust it
    - Run again
- Make sure to enable Bluetooth on both devices
- Sign up/Login and access the trackpad screen and allow Local Network
- Press select device on the home page
- Connect to the device that you intend to use

### Gamepad Usage
- All setup instructions same as trackpad
- When using, if needed, remap keybinds in the gamepad settings

### Race Wheel Usage
- All setup instructions same as trackpad
- Remap keybinding for gas and brake pedals in the race wheel settings if needed
- Experiment in game to adjust sensitivities and thresholds according to feel

---

## Feature Summary

| Feature | Description | Release Planned | Release Actual | Deviations | Who/Percentage Worked On |
|---------|-------------|----------------|----------------|------------|--------------------------|
| **Trackpad Controller** | Allows the iPhone screen to act as a wireless touchpad to control the pointer on a connected computer. Include pointer movement, tapping/clicking and basic gesture support | Alpha | Alpha (core), refined in Beta & Final | Changed UI from proposal mockups | Avis (50%), Evan (50%) |
| **Wii-style motion controller** | Motion-based controller similar to a Wii remote using phone tilt and gestures for input | Final (stretch goal) | Not yet implemented | Stretch goal (schedule after Final) | N/A |
| **Racing wheel controller** | Uses iPhone as a virtual steering wheel for racing games | Final (stretch goal) | Final | Changed UI from proposal mockups | Avis (90%), Jerry (10%) |
| **Connection & Mac Receiver pipeline** | Wi-fi connection between Controlio and the ControlioReceiver app, including connection scaffolding, event structure, connect/disconnect controls, and connection persistence control | Not called out separately in the proposal, but an implicit implementation for all releases | Alpha & Beta | Not originally listed as a separate feature. Initial work began in Alpha and strengthened in Beta | Masayuki (20%), Avis (40%), Evan (40%) |
| **Authentication & onboarding** | Splash screen (logo), splash -> login/signup -> home, Firebase email/password authentication, Google sign-in, and error handling | Not explicitly planned | Alpha | Not listed in the proposal, but required for a real app, as it supports real user accounts | Jerry (80%), Masayuki (20%) |
| **Home connect/disconnect UI** | Homeview screen + connect/disconnect GUI so users can start or end a session with ControlioReceiver | Alpha | Alpha (GUI) & Beta (core function) | None | Masayuki (25%), Jerry (65%), Avis (10%) |
| **Device Help & Device Controller screens** | Device Help screen and Device Controller screen, plus the orange toolbar and navigation linking Device Help and Trackpad Settings | Beta | Beta | None | Masayuki (75%), Avis (25%) |
| **Setting & app preferences** | Trackpad settings page, App Preferences screen, UI toggles for vibration feedback and sound effects | Alpha | Beta & Final | Originally part of individual controller features; consolidated into dedicated settings later | Evan (40%), Jerry (60%) |
| **Themes & localization** | Dark/light mode for trackpad and gamepad, and French/Spanish translations used across the app | Not originally planned | Beta & Final | Extra function beyond the original plan - added to improve accessibility and appearance | Avis (20%), Jerry (20%), Masayuki (60%) |
| **Event Pump** | Priority queue and logic designed to handle signals from the controller and translate to usable signals for the receiver | Not originally planned | Alpha | We added the keyboard inputs to event pump compensate for game controller and racing wheel | Evan (50%), Avis (50%) |



# Controlio

Transport: MultipeerConnectivity
- iOS browses, macOS advertises

