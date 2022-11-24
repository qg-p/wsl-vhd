#!/bin/bash
# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE
MNT_LOG=/mnt/wsl/mount.processing.log
STDIN=/proc/$$/fd/0
STDOUT=/proc/$$/fd/1
#TTY_PATH="//wsl$/Ubuntu/$(tty)"

log="Write-Output" # powershell 'echo' instruction

mount-vhd() {
	if [ ! -f $1 ]; then
		echo $1 is not a file
		exit
	fi
	VHD_PATH=$(wslpath -m $1) # <relative>/path/to/Ubuntu.vhdx -> Disk:/absolute/path/to/Ubuntu.vhdx
	if [ "//wsl" == "${VHD_PATH:0:5}" ]; then # not being a windows file, "//wsl.localhost/Ubuntu/**"
		echo "\"$1\" <$VHD_PATH> may be a virtual file"
	fi
	if [ -z "$DISK" ]; then
		declare -A MAP # <local> MAP: dictionary
		export DISK=$(declare -p MAP)
	fi
	eval "$DISK" # "declare -A MAP=(...)", unpack.
	if [ ! ${MAP[$VHD_PATH]+_} ]; then # if MAP[VHD_PATH] is None # not '==false'
# RunAs Administrator: mount-vhd, get-vhd, wsl --mount
		powershell.exe -NoProfile -Command \
		"Start-Process powershell -Verb RunAs -Wait -ArgumentList '-noexit -NoProfile -Command \"&{
			$log \\\"===powershell (Administrator) output===\\\"
			#$log $BASHPID $$
			$log \\\"VHD path=<$VHD_PATH>\\\"
			$log \\\"Get-VHD\\\"
			[int] \$diskno=(Get-VHD -Path $VHD_PATH).Number
			If ([String]::IsNullOrEmpty(\$diskno)) {
				$log \\\"Mount-VHD...\\\"
				[int] \$diskno=(Mount-VHD -Path $VHD_PATH).Number
			}
			If ([String]::IsNullOrEmpty(\$diskno)) {
				$log \\\"Cannot Mount-VHD: <$VHD_PATH>\\\"
				exit
			}
			$log \\\"Disk Number=\$diskno\\\"
			\$disk=\\\"$VHD_PREFIX\$diskno\\\"
			$log \\\"wsl --mount \\\\.\\\$disk\\\"
			wsl --mount \\\\.\\\$disk
			$log \\\"Write $MNT_LOG\\\"
			Set-Content -Path \$(wsl wslpath -m $MNT_LOG) -Encoding UTF8 -Value \$disk
		}\" *>&1 | wsl -d Ubuntu -- \"cat \\\">\\\" $STDOUT\"
		#Write-Output \"6a54s1d2f\" | wsl -d Ubuntu -- \"cat \\\">\\\" /proc/$$/fd/3\" # TODO
		'"
		#echo var=$var # TODO
		if [ -f $MNT_LOG ]; then
			read PHYSICAL_DRIVE < $MNT_LOG # remove \x00 \xff \xfe: (tr -cd "[:print:]")
			echo $PHYSICAL_DRIVE | xxd
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
	if [ ! -f $1 ]; then
		echo $1 is not a file
		exit
	fi
	VHD_PATH=$(wslpath -m $1)
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
	powershell.exe -NoProfile -Command \
	"Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList '-NoProfile -Command \"&{
		$log \\\"===powershell (Administrator) output===\\\"
		$log wsl_unmount
		wsl --unmount \\\\.\\$PHYSICAL_DRIVE
		$log dismount-vhd
		Dismount-VHD -Path $VHD_PATH
	}\" *>&1 | wsl -d Ubuntu -- \"cat \\\">\\\" $STDOUT\"
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
echo $DISK
mount-vhd /mnt/d/subsystem/ubuntu/Ubuntu.vhdx
echo $DISK
#unmount-vhd /mnt/d/subsystem/ubuntu/Ubuntu.vhdx
#echo $DISK
#ls -la /mnt/ramdisk/tmp

#powershell.exe -command "Start-Process -Verb RunAs cmd -ArgumentList \"/C $($portproxycmd)\""
#-Command &{ wsl --mount $(Write-Output "\\.\PhysicalDrive$((Mount-VHD -Path D:\subsystem\ubuntu\Ubuntu.vhdx -PassThru | Get-Disk).Number)") }
