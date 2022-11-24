#!/bin/bash

# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE
MNT_LOG=/mnt/wsl/mount.log

mount_vhd() {
	if [ -z "$DISK" ]; then
		declare -A DISK
		if [ -f $MNT_LOG ]; then
			VHD_PATH=$0
# RunAs Administrator: mount-vhd, get-vhd, wsl --mount
			powershell.exe -command "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-Command \"
				\$disk=(Get-VHD -Path $VHD_PATH).Number
				echo \$disk
				If ([String]::IsNullOrEmpty(\$disk)) {
					echo MOUNT
					\$disk=(Mount-VHD -Path $VHD_PATH -PassThru).Number
				}
				If ([String]::IsNullOrEmpty(\$disk)) {
					pause No_Online_VHD
					exit
				}
				\$disk=\\\"$VHD_PREFIX\$disk\\\"
				wsl --mount \$disk
				\$disk >> \\\\wsl$\\Ubuntu$MNT_LOG
				pause\"
			'"
		fi
		export DISK[$(cat /mnt/wsl/mount.log)]
	fi
}

dismount_vhd() {
	if [ -f $MNT_LOG ]; then
		VHD_PATH=$0
		export -n DISK
		unset DISK
		rm $MNT_LOG
# RunAs Administrator: dismount-vhd, wsl --unmount
		powershell.exe -command "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-Command \"
			wsl --unmount \$disk
			Dismount-VHD -Path $VHD_PATH
			pause\"
		'"
	fi
}

mount_vhd "D:\\subsystem\\ubuntu\\Ubuntu.vhdx"
if [ -z "$DISK" ]; then
	export DISK=$(cat /mnt/wsl/mount.log)
fi

#powershell.exe -command "Start-Process -Verb RunAs cmd -ArgumentList \"/C $($portproxycmd)\""
#-Command &{ wsl --mount $(Write-Output "\\.\PhysicalDrive$((Mount-VHD -Path D:\subsystem\ubuntu\Ubuntu.vhdx -PassThru | Get-Disk).Number)") }
