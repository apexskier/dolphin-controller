# Dolphin Controller

![enter image description here](https://raw.githubusercontent.com/ajaymerchia/dolphin-controller/master/GameCubeController/Assets.xcassets/melee-logo.imageset/logo-text.png)

Video games were meant to be played together. All you need to launch a gaming session with friends via Dolphin is your laptop and this repository.

## Installation
Download the latest version of Dolphin emulator from here:
https://dolphin-emu.org

Download the latest version of Controller app from the iOS App Store (link to come).

## Dolphin Setup
In order for the app to interact with the Dolphin Emulator software, you need to adjust some config files. We'll call the enclosing config folder `DolphinConfigDirectory`.

**Possible Locations**
* `~/Library/Application Support/Dolphin`
* [Add directories from other platforms here]

### Input Pipes
Make the input streams for the 4 possible controllers. Using your command line run the following commands
```
# cd ${DolphinConfigDirectory}
cd Pipes
mkfifo ctrl1
mkfifo ctrl2
mkfifo ctrl3
mkfifo ctrl4
```

https://wiki.dolphin-emu.org/index.php?title=Pipe_Input

### Controller Config
In `DolphinConfigDirectory/Config` open up `GCPadNew.ini` and replace its contents with the following [file](https://raw.githubusercontent.com/ajaymerchia/dolphin-controller/master/GCPadNew.ini)
```
[GCPad1]
Device = Pipe/0/ctrl1
Buttons/A = Button A
Buttons/B = `Button B`
Buttons/X = `Button X`
Buttons/Y = `Button Y`
Buttons/Z = `Button Z`
Buttons/Start = `Button START`
D-Pad/Up = `Button D_UP`
D-Pad/Down = `Button D_DOWN`
D-Pad/Left = `Button D_LEFT`
D-Pad/Right = `Button D_RIGHT`
Triggers/L = `Button L`
Triggers/R = `Button R`
Main Stick/Up = `Axis MAIN Y +`
Main Stick/Down = `Axis MAIN Y -`
Main Stick/Left = `Axis MAIN X -`
Main Stick/Right = `Axis MAIN X +`
C-Stick/Up = `Axis C Y +`
C-Stick/Down = `Axis C Y -`
C-Stick/Left = `Axis C X -`
C-Stick/Right = `Axis C X +`
Main Stick/Center = 0.00 0.00
C-Stick/Center = 0.00 0.00
```
Repeat for `GCPad2`, `GCPad3`, `GCPad4` in the same file.

## Server Setup
Make sure you have npm and node installed (https://nodejs.org/en/).

Download this repository and open the `gcserver` directory in terminal. 

1. Update the `DolphinConfigDirectory` constant in `index.js` to the filepath on your machine.
2. Run `node index.js` from the `gcserver` directory. You should get a QR code that you can scan in-app.


## Get Started
Once you're all set up, you can launch games in Dolphin. Launch Dolphin and make sure to run the node server from `gcserver`.

| Game | Link to ISO |
| :------------- | :------------- |
| Super Smash Bros Melee | https://drive.google.com/file/d/181oRBAA4pLR3ZRETagZ_tu1t78C9Sbl7/view |


