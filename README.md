# adbw

Dead simple script to connect your Android device wirelessly via ADB using NordVPN Meshnet.

## Requirements

- [ADB](https://developer.android.com/studio/command-line/adb) installed
- [NordVPN](https://nordvpn.com/) with Meshnet enabled
- **Your phone connected via USB when running the script**

## Installation

Just download the `adbw.sh` script and give it execute permissions:

```bash
chmod +x adbw.sh
```

**REMEMBER TO CHANGE THE `TARGET_HOSTNAME` VARIABLE INSIDE THE SCRIPT** to match your device's Meshnet hostname!!

## Usage

```bash
./adbw.sh          # Connect normally
./adbw.sh -r       # Restart ADB server and connect
./adbw.sh --help   # Show help
```

## Pro tip

Put the script somewhere in your PATH (e.g., `/usr/local/bin/`) and make it executable:

```bash
chmod +x /path/to/adbw.sh
mv /path/to/adbw.sh /usr/local/bin/adbw
```

Then you can just run `adbw` from anywhere!
