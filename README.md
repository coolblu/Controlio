# Alpha Release README - Controlio - Group 14

## Contributions

### Masayuki Yamazaki (25%)
- HomeView screen
- Connect/disconnect GUI on HomewVIew screen
- Some of the splash screen (ContolioApp) shows the logo when the user opens the app
- Device Help Screen
- Device Controller Screen
- The orange toolbar on Device Help Screen and Trackpad Setting Screen
- Added navigations from the toolbar on  Device Help Screen and Trackpad Setting Screen

### Avis Luong (25%)
- Functionality of the trackpad with Evan
- MacReceiver app with Evan
- Trackpad Screen
- Debugging/testing trackpad
- Scaffolding for connection management
- Created the structure for events
- Dark mode for trackpad
- Added Dark/Light mode for gamepad
- Worked on gamepad UI
- Added disconnect/reconnect button on home screen
- Connection status tracking
- Connection persistence through the app
- Fixed pointer lag with Evan
- Worked on gamepad logic and functionality with Evan

### Evan Weng (25%)
- Functionality of the trackpad with Avis
- MacReciever app with Avis
- Debugging/testing of trackpad connection
- Trackpad Screen
- Settings page and settings for trackpad
- Worked on pointer lag with Avis
- Worked on gamepad logic and functionality with Avis
- Keyboard emitter to convert swipes, presses, and holds on the game controller into keys on the keyboard

### Jerry Lin (25%)
- Added transitions from splash screen to login/signup to home screen with animations
- Set up firebase for simple username and password authentication
- Added google sign in option through firebase
- Implemented Login and Signup screens, displaying error messages if applicable
- Sidebar when clicking hamburger button with logout button and navigation to Manage Profile screen and App Preferences screen
- Obtaining and showing display name for the app on the home screen and sidebar
- Manage Profile screen implementation allowing users to change display name, password, or delete their account
- App Preferences screen using user defaults to save settings
- Implemented prevent screen sleep toggle
- Implemented language translations for French and Spanish and added to various screens
- Implemented dark mode and added to various screens
- UI toggles for vibration feedbacks and sound effects
- Added app icon

---

## Deviations
- On the Device Controller Screen, the screen is supposed to show the devices connected and available to the iPhone. It, however, does not work as it should right now. Therefore, the “Select Device” button on the homepage does not have functionality and the Device Controller Screen has hard coded placeholders.
- Our original plan was to have the game controller screen directly simulate a physical game controller. We wanted the emulator to directly send game controller signals as if there was a bluetooth or physical game controller connected. After we did some research, we realized that this isn’t possible. Apple doesn’t have a way for you to do this unless you get a specific license that relates to low-level programming. There are some drivers we found but they don’t work with apps in the app store. What we decided to pivot to is having the game controller signals convert to keyboard inputs. That is, moving the analog stick up is the same as pressing the “w” key, for example. You can then map the other buttons to whatever keys you would like. 
- Decided to remove notifications from app settings as those don’t seem that useful as connections won’t happen outside the app and there are no updates. Removed show tips toggle from app settings as that was redundant with the help screen of our app. Sound effects and vibration feedback will be added once the controllers are more fleshed out.
- We originally had the settings for the game controller scoped for the Beta, but due to the technical complexity of implementing the controller we did not have enough time to complete it for Beta.

---

## Special Instructions

Trackpad Usage:
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

### Trackpad Gestures
- 3-finger swipe left/right: previous/next tab (Ctrl+Shift+Tab / Ctrl+Tab)
- Right-edge swipe: open Notification Center
- 5-finger pinch: Cmd+Q (close app)

Gamepad Usage:
- All setup instructions same as trackpad
- When using, if needed, remap game keybinds with gamepad inputs
    - I.e if walk forward is not already binded to “W” go into the game’s settings and rebind to the controller input for forward etc (analog stick forward = W).
 

# Controlio

Transport: MultipeerConnectivity
- iOS browses, macOS advertises
- serviceType = "controlio-trk"

Event schema (JSON, line-delimited):
- {"t":"pm","p":{"dx":Int,"dy":Int}} pointer move
- {"t":"bt","p":{"c":Int /*0=left,1=right*/,"s":Int /*0=up,1=down*/}} button
- {"t":"sc","p":{"dx":Int,"dy":Int}} scroll
- (reserve {"t":"gs","p":{"k":Int,"v":Int}} for gestures later)
