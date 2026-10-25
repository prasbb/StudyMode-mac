# Study Mode for macOS

A lightweight menu-bar utility that reminds you to connect headphones when you log in.

## Install

1. Unzip the download.
2. Open **Terminal**, enter `cd ` (including the space), drag the extracted **StudyMode-macOS** folder into Terminal, and press Return.
3. Run `bash install.sh`.
4. If prompted, install Apple Command Line Tools (`xcode-select --install`), then rerun step 3.
5. If macOS asks whether to allow a background item, allow **Study Mode** in **System Settings → General → Login Items & Extensions**.

No root/sudo privileges or third-party packages are required. The app is compiled on your own Mac and runs entirely offline.

## Behavior

- Starts on login (using a per-user LaunchAgent).
- Enables Study Mode by default.
- Shows a floating reminder at the upper right if your current audio output is not recognized as headphones.
- Checks every ~3 seconds; hides the reminder as soon as headphones are selected as the default output.
- Shows the reminder again if headphones are disconnected or output changes to speakers.
- Headphones icon in menu bar → toggle Study Mode on/off or quit.
- Toggle preference persists across logins. The agent restarts the app if you quit; toggle Study Mode **off** to pause reminders. Uninstall to remove automatic startup.

## Detection limitations

Detection is based on the **currently selected macOS sound output**, not merely whether a headset is paired. Bluetooth output is generally counted as headphones, so a **Bluetooth speaker may be incorrectly counted**. Wired headphones are detected by output name or a Core Audio jack-connection property when the device exposes it. Some USB/headphone models with unusual names may not be recognized. To use connected Bluetooth headphones, select them in System Settings → Sound → Output.

## Remove

Run `bash uninstall.sh` from the extracted folder.

## Compatibility

Designed for macOS 12+ on Intel and Apple silicon. Requires Apple's Swift compiler (Command Line Tools). Source is included. This package cannot be compiled or live-tested on macOS in the creation environment, so if your Mac reports a Swift compiler error, the source may need a small SDK-specific adjustment.
