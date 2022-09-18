# Dolphin Controller

Video games were meant to be played together. All you need to play a game with friends on Dolphin is your laptop and this app, over bluetooth or Wi-Fi.

| macOS Server | iOS Client | iOS Server Browser |
| ------------ | ---------- | ------------------ |
| <img src="https://user-images.githubusercontent.com/329222/130981252-d7fdad99-8b32-437f-aefd-eb1198613549.png" alt="Server UI" /> | ![Client UI](https://user-images.githubusercontent.com/329222/131947045-28fb3a63-58fe-47e7-a7b8-e3f4a365dee7.png) | ![Server Join UI](https://user-images.githubusercontent.com/329222/131947834-1a5de0b6-9a95-46bd-95a4-b4afc0aa7ccc.PNG) |

## Installation & Usage

1. [Download the latest version of Dolphin emulator](https://dolphin-emu.org)
2. [Install the iOS app from the App Store](https://apps.apple.com/us/app/dolphin-ctrl/id1584272645) and the [macOS server from GitHub](https://github.com/apexskier/dolphin-controller/releases/latest) (or build and run the with XCode)
3. From the iOS app, tap "Join" and find your server
4. Pick a controller number by tapping P1, P2, P3, or P4

**Important**:

Dolphin Controller can be _slow_ depending the speed of your WiFi/bluetooth/remote network connect _and_ the speed of the Dolphin emulator itself. Try verifying the performance with a simple game if a more performance intensive game feels slow. Tips for improving performance can be found in Dolphin's [Performance Guide](https://dolphin-emu.org/docs/guides/performance-guide/).

## Setup

In order for the app to interact with the Dolphin Emulator software, this app takes advantage of [Dolphin's pipe input feature](https://wiki.dolphin-emu.org/index.php?title=Pipe_Input).

The server will automatically write the correct config and create the required FIFO pipes.

From the Dolphin app, open the controller settings (Options > Controller Settings in the menu bar). For each controller you wish to connect in-game, change "Port N" to "Standard Controller".

![Dolphin Controller Settings](https://user-images.githubusercontent.com/329222/130376541-ca943da6-963d-4706-b2a0-74b6e4516f1c.png)

### Verification

You can verify the controller is connected by clicking "Configure" and ensuring "Device" is connected to "Pipe/0/ctrlN". From the configure window, you can also verify that the UI responds to interactions on your iOS device.

![Controller configuration verification](https://user-images.githubusercontent.com/329222/130376738-b08f01c5-7360-4f17-909e-abcddf0c3264.png)

## Tips

* The iOS app will attempt to auto-reconnect with the same controller number if it looses a connection (if your screen locks or the app backgrounds).
* In the server browser window (after tapping "Join") the ★'d server is the one last connected to.
* Servers are advertised automatically with Bonjour, so no need to enter manual information if everyone's in the same room.
* For remote play, tap the Network icon in the macOS app's toolbar to find the port, forward to a public IP address, and enter the address manually.

❤️ inspired by (and originally forked from, but since rewritten) https://github.com/ajaymerchia/dolphin-controller
