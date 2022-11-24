# wsl-vhd

Manage Virtual Hard Disk from Windows Subsystem for Linux

# Usage

`wsl-vhd mount path/to/file.vhdx [mount point]`
`wsl-vhd umount path/to/file.vhdx`
`wsl-vhd umount-all`
`wsl-vhd status`

# Requirement

powershell.exe:
- Get-VHD
- Mount-VHD
- Dismount-VHD
- run as administrator

wsl:
- [Store version](https://aka.ms/wslstorepage)

