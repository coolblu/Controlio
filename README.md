# Alpha Release README

## Contributions

### Masayuki Yamazaki (25%)
- HomeView screen
- Connect/disconnect GUI on HomewVIew screen
- Some of the splash screen (ContolioApp) shows the logo when the user opens the app

### Avis Luong (25%)
- Functionality of the trackpad with Evan
- MacReceiver app with Evan
- Trackpad Screen
- Debugging/testing trackpad
- Scaffolding for connection management
- Created the structure for events

### Evan Weng (25%)
- Functionality of the trackpad with Avis
- MacReciever app with Avis
- Debugging/testing of trackpad connection
- Trackpad Screen

### Jerry Lin (25%)
- Added transitions from splash screen to login/signup to home screen with animations
- Set up firebase for simple username and password authentication
- Added google sign in option through firebase
- Implemented Login and Signup screens, displaying error messages if applicable

---

## Deviations
- We had to design a Mac app to help establish the connection between the phone app and the Mac. It also helped us to debug and ensured the app was able to have access to the computer’s mouse.
- Our homescreen was designed and while the trackpad button works, since we spent more time to implement the trackpad, the other buttons don’t link to their respective emulator screen yet
- The debugging/implementation for the trackpad took a while, so the current connection status reflected in the home screen is not implemented yet.
- Right now, in order for the Mac app to be able to control the mouse, you have to open the MacReciever app, allow it to have accessibility control, and then relaunch the app. In Beta we want to solve this issue by either adding a notification to the user or finding a way to allow the accessibility control to be added without having to relaunch the Mac app.
- The current UI for the trackpad is barebones and will be refined in Beta release, including the settings page for the trackpad.

---

## Special Instructions

- Run the receiver program first  
  - In XCode under Product, set the scheme to ControlioReceiver and the destination to My Mac
- Go to the Acessibility settings on the Mac under Privacy and Security and add the built program to Acessibility permissions  
  - To get the build path, go to XCode and click on Products -> Show Build Folder in finder -> go to the debug folder and your .app should be there
- Rerun the app after adding permissions
- Then in XCode, click on debug on the top -> Detach from ControlioReciever
- Now, you can change the scheme to Controlio
- Enable development mode on iPhone under Privacy and Security
- In XCode, select the iOS target (Controlio) and access Signing & Capabilities  
  - Ensure team is set  
  - Change the bundle identifier to something unique
- Plug in your iPhone  
  - Choose the device as the running destination under Product  
  - On the first run, you will get a trust/signing warning  
    - On the iPhone go to Settings -> General -> VPN & Device Managment -> Click on the app and trust it  
    - Run again
- Make sure to enable Bluetooth on both devices
- Login and access the trackpad screen and allow Local Network

# Controlio

Transport: MultipeerConnectivity
- iOS browses, macOS advertises
- serviceType = "controlio-trk"

Event schema (JSON, line-delimited):
- {"t":"pm","p":{"dx":Int,"dy":Int}} pointer move
- {"t":"bt","p":{"c":Int /*0=left,1=right*/,"s":Int /*0=up,1=down*/}} button
- {"t":"sc","p":{"dx":Int,"dy":Int}} scroll
- (reserve {"t":"gs","p":{"k":Int,"v":Int}} for gestures later)
