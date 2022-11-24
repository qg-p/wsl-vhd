#!/bin/bash

# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE
MNT_LOG=/mnt/wsl/mount.processing.log
# powershell 'echo' instruction
log=Write-Host

mount_vhd() {
	if [ -z "$DISK" ]; then
		declare -Ax DISK # <global> DISK: dictionary
	fi
	VHD_PATH=$1
	if [ ! ${DISK[$VHD_PATH]+_} ]; then # if DISK[VHD_PATH] is None # not '==false'
# RunAs Administrator: mount-vhd, get-vhd, wsl --mount
		powershell.exe -Command "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-Command \"
			$log \\\"VHD path=<$VHD_PATH>\\\"
			$log \\\"Get-VHD\\\"
			\$diskno=(Get-VHD -Path $VHD_PATH).Number
			If ([String]::IsNullOrEmpty(\$diskno)) {
				$log \\\"Mount-VHD...\\\"
				\$diskno=(Mount-VHD -Path $VHD_PATH -PassThru).Number
			}
			If ([String]::IsNullOrEmpty(\$diskno)) {
				$log \\\"Cannot Mount-VHD: <$VHD_PATH>\\\"
				pause
				exit
			}
			$log \\\"Disk Number=\$diskno\\\"
			\$disk=\\\"$VHD_PREFIX\$diskno\\\"
			$log \\\"wsl --mount \\\\.\\\$disk\\\"
			wsl --mount \\\\.\\\$disk
			$log \\\"Write $MNT_LOG\\\"
			\$disk > \\\\wsl$\\Ubuntu$MNT_LOG
			pause\"
		'"
		if [ -f $MNT_LOG ]; then
			PHYSICAL_DRIVE=$(tr -cd "[:print:]" < $MNT_LOG) # remove \x00 \xff \xfe
			DISK+=( [$VHD_PATH]=$PHYSICAL_DRIVE ) # update DISK
			export DISK
			rm $MNT_LOG
			for key in ${!DISK[@]}; do echo ${DISK[$key]}	$key; done
			return 0
		else
			echo Fail to mount VHD \"$VHD_PATH\"
			return -1
		fi
	fi
}

dismount_vhd() {
	VHD_PATH=$1
	for key in ${!DISK[@]}; do echo ${DISK[$key]}	$key; done
	if [ ${DISK[$VHD_PATH]+_} ]; then
		echo DISK\[$VHD_PATH\] is None
		return -1
	fi
	PHYSICAL_DRIVE=${DISK[$VHD_PATH]}
	for key in ${!DISK[@]}; do # unregister all pair from DISK whose value equals to ${DISK[$VHD_PATH]}
		if [ ${DISK[$key]} -eq $PHYSICAL_DRIVE ]; then
			unset DISK[$key]
		fi
	done
	export DISK
# RunAs Administrator: dismount-vhd, wsl --unmount
	powershell.exe -Command "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-Command \"
		echo wsl_unmount
		wsl --unmount \\\\.\\$PHYSICAL_DRIVE
		echo dismount-vhd
		Dismount-VHD -Path $VHD_PATH
	'"
	return 0
}

(mount_vhd "D:\\subsystem\\ubuntu\\Ubuntu.vhdx") && (dismount_vhd "D:\\subsystem\\ubuntu\\Ubuntu.vhdx")

#powershell.exe -command "Start-Process -Verb RunAs cmd -ArgumentList \"/C $($portproxycmd)\""
#-Command &{ wsl --mount $(Write-Output "\\.\PhysicalDrive$((Mount-VHD -Path D:\subsystem\ubuntu\Ubuntu.vhdx -PassThru | Get-Disk).Number)") }
