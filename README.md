# wsl-vhd

Manage Virtual Hard Disk from Windows Subsystem for Linux

## Usage

To mount a VHD and bind a directory with it:
``` bash
wsl-vhd mount path/to/file.vhdx [mount point]
```

Unmount a VHD and unbind all directories mounted on if:
``` bash
wsl-vhd umount path/to/file.vhdx
```
or to unmount all virtual disk in the record and dismiss all their mountpoints:
``` bash
wsl-vhd umount-all
```

Show the record:
``` bash
wsl-vhd status
```

## Require

powershell.exe:
- Get-VHD
- Mount-VHD
- Dismount-VHD
- run as administrator

wsl:
- [Store version](https://aka.ms/wslstorepage)

Note: configure log file, $PATH etc. in the script.
