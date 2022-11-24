#!/bin/bash

# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE
MNT_LOG=/mnt/wsl/mount.processing.log
# powershell 'echo' instruction
log=Write-Host

mount-vhd() {
	if [ -z "$DISK" ]; then
		declare -A MAP # <local> MAP: dictionary
		export DISK=$(declare -p MAP)
	fi
	VHD_PATH=$1
	eval "$DISK" # "declare -A MAP=(...)", unpack.
	if [ ! ${MAP[$VHD_PATH]+_} ]; then # if MAP[VHD_PATH] is None # not '==false'
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
			\$disk > \\\\wsl$\\Ubuntu$MNT_LOG\"
		'"
		if [ -f $MNT_LOG ]; then
			PHYSICAL_DRIVE=$(tr -cd "[:print:]" < $MNT_LOG) # remove \x00 \xff \xfe
			MAP+=( [$VHD_PATH]=$PHYSICAL_DRIVE ) # update MAP
			export DISK=$(declare -p MAP)
			rm $MNT_LOG
			return 0
		else
			echo Fail to mount VHD \"$VHD_PATH\"
			return -1
		fi
	fi
}

unmount-vhd() {
	VHD_PATH=$1
# MAP is None
	if [ -z "$DISK" ]; then
		echo Env Var \$DISK is not set
		return -1
	fi
	eval "$DISK" # unpack
# MAP is loaded
	if [ ! ${MAP[$VHD_PATH]+_} ]; then
		echo MAP\[$VHD_PATH\] is None
		return -1
	fi
	sync # !!! IMPORTANT !!!
	PHYSICAL_DRIVE=${MAP[$VHD_PATH]}
# RunAs Administrator: dismount-vhd, wsl --unmount
	powershell.exe -Command "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-Command \"
		echo wsl_unmount
		wsl --unmount \\\\.\\$PHYSICAL_DRIVE
		echo dismount-vhd
		Dismount-VHD -Path $VHD_PATH
	'"
	for key in ${!MAP[@]}; do # unregister all pair from MAP whose value equals to ${MAP[$VHD_PATH]}
		if [ "${MAP[$key]}" == "$PHYSICAL_DRIVE" ]; then
			unset MAP[$key]
		fi
	done
	export DISK=$(declare -p MAP)
	return 0
}

#	for key in ${!MAP[@]}; do echo ${MAP[$key]}	$key; done # debug log
#mount-vhd "D:\\subsystem\\ubuntu\\Ubuntu.vhdx"
#echo $DISK
#unmount-vhd "D:\\subsystem\\ubuntu\\Ubuntu.vhdx"
#echo $DISK

#powershell.exe -command "Start-Process -Verb RunAs cmd -ArgumentList \"/C $($portproxycmd)\""
#-Command &{ wsl --mount $(Write-Output "\\.\PhysicalDrive$((Mount-VHD -Path D:\subsystem\ubuntu\Ubuntu.vhdx -PassThru | Get-Disk).Number)") }
