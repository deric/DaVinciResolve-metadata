# DaVinci Resolve EXIF Metadata Synchronization Tool

## Requirements:

  - [exif tool](https://exiftool.org/), see [install page](https://exiftool.org/install.html)
    * Debian/Ubuntu: `sudo apt install libimage-exiftool-perl`

## Installation

### Linux

```
wget https://raw.github.com/deric/DaVinciResolve-metadata/EXIF-metatata.lua -P ~/.local/share/DaVinciResolve/Fusion/Scripts/Comp/
```

## How does it work

Resolve API currently doesn't offer original location of clips in Project's Media Pool, thus the original files needs to be matched with files from Media Storage. The matching is done solely on filename basis, thus it might be inaccurate (if filenames in your project aren't unique or camera generated names rotated counter etc.).



