# Dolphin Controller

Video games were meant to be played together. All you need to launch a gaming session with friends via Dolphin is your laptop and this repository.

## Installation

1. [Download the latest version of Dolphin emulator](https://dolphin-emu.org)
2. Build and run the macOS server and iOS client from XCode

## Dolphin Setup

In order for the app to interact with the Dolphin Emulator software, this app takes advantage of [Dolphin's pipe input feature](https://wiki.dolphin-emu.org/index.php?title=Pipe_Input).

The server will automatically write the correct config and create the required FIFO pipes.

From the Dolphin app, open the controller settings (Options > Controller Settings in the menu bar). For each controller you wish to connect in-game, change "Port N" to "Standard Controller". You can verify the controller is connected by clicking "Configure" and ensuring "Device" is connected to "Pipe/0/ctrlN". From the configure window, you can also verify that the UI responds to interactions on your iOS device.
