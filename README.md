# Dolphin Controller

Video games were meant to be played together. All you need to play a game with friends on Dolphin is your laptop and this app, over bluetooth or Wi-Fi.

| macOS Server | iOS Client |
| ------------ | ---------- |
| <img src="https://user-images.githubusercontent.com/329222/130376826-e01d3d13-fc0c-4b8e-a97f-29ce20eaa50f.png" alt="Server UI" /> | ![IMG_1337](https://user-images.githubusercontent.com/329222/130545152-d6d1b0fa-0ba5-49f6-9062-204cac70fe99.PNG) |

## Installation

1. [Download the latest version of Dolphin emulator](https://dolphin-emu.org)
2. Build and run the macOS server and iOS client from XCode
3. From the iOS app, tap "Connect" and find your server

## Setup

In order for the app to interact with the Dolphin Emulator software, this app takes advantage of [Dolphin's pipe input feature](https://wiki.dolphin-emu.org/index.php?title=Pipe_Input).

The server will automatically write the correct config and create the required FIFO pipes.

From the Dolphin app, open the controller settings (Options > Controller Settings in the menu bar). For each controller you wish to connect in-game, change "Port N" to "Standard Controller".

![Dolphin Controller Settings](https://user-images.githubusercontent.com/329222/130376541-ca943da6-963d-4706-b2a0-74b6e4516f1c.png)

### Verification

You can verify the controller is connected by clicking "Configure" and ensuring "Device" is connected to "Pipe/0/ctrlN". From the configure window, you can also verify that the UI responds to interactions on your iOS device.

![Controller configuration verification](https://user-images.githubusercontent.com/329222/130376738-b08f01c5-7360-4f17-909e-abcddf0c3264.png)

## Tips

* Turn off auto display lock on your iOS device (Settings > Display & Brightness > Auto-Lock > Never) (at least until I get persistent controller numbers)
* The iOS app will attempt to auto-reconnect if it looses a connection (if your screen locks or the app backgrounds). Your controller number is first come, first served, so reconnect in order if multiple people loose connections.
* The iOS app will remember the last server you connected to, tap "Reconnect" to jump back in, or "New" to find a new server.
* Servers are advertised automatically with Bonjour, so no need to enter manual information if everyone's in the same room.
* For remote play, tap the Network icon in the macOS app's toolbar to find the port, forward to a public IP address, and enter the address manually.

❤️ inspired by (and originally forked from, but since rewritten) https://github.com/ajaymerchia/dolphin-controller
