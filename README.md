# DaVinci Resolve EXIF Metadata Synchronization Tool

## Requirements:

  - [exif tool](https://exiftool.org/), see [install page](https://exiftool.org/install.html)
    * Debian/Ubuntu: `sudo apt install libimage-exiftool-perl`

## Installation

Copy the lua script file to following paths:

* Linux: `~/.local/share/DaVinciResolve/Fusion/Scripts/Comp`
* macOS `~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Comp`
* Windows `%AppData%\Roaming\DaVinci Resolve\Support\Fusion\Scripts\Comp`

### Linux

From command line:
```
wget https://raw.githubusercontent.com/deric/DaVinciResolve-metadata/main/EXIF-metadata.lua -P ~/.local/share/DaVinciResolve/Fusion/Scripts/Comp/
```

## Usage

 1. Import some media files from Media Storage to Project's Media Pool
 2. Select from main menu `Workspace > Scripts > EXIF-metadata`
 3. Choose subdirectory from dropdown menu that will be recursively scanned
 4. Select meta fields
 5. Run Sychronize Media Store

![EXIF synchronizer window](docs/exif_window.png)

## How does it work

Resolve API currently doesn't offer original location of clips in Project's Media Pool, thus the original files needs to be matched with files from Media Storage. The matching is done solely on filename basis, thus it might be inaccurate (if filenames in your project aren't unique or camera generated names rotated counter etc.).



