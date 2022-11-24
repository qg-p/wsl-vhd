#!/bin/bash
# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE # pHYsiCaldrIVe, etc.
MNT_LOG=/mnt/wsl/mount.processing.log
STDIN=/proc/$$/fd/0
STDOUT=/proc/$$/fd/1
#TTY=$(tty)

log="Write-Output" # powershell 'echo' instruction

mount-vhd() {
	if [ ! -f "$1" ]; then
		echo "\"$1\" is not a file"
		exit
	fi
	VHD_PATH=$(wslpath -m $1) # <relative>/path/to/Ubuntu.vhdx -> Disk:/absolute/path/to/Ubuntu.vhdx
	if [ "//wsl" == "${VHD_PATH:0:5}" ]; then # not being a windows file, "//wsl.localhost/Ubuntu/**"
		echo "Warning: \"$1\" <$VHD_PATH> may be a virtual file"
	fi
	if [ -z "$DISK" ]; then
		declare -A MAP # <local> MAP: dictionary
		export DISK=$(declare -p MAP)
	fi
	eval "$DISK" # "declare -A MAP=(...)", unpack.
	if [ ${MAP[$VHD_PATH]+_} ]; then # if MAP[VHD_PATH] is not None # which is not '!=false'
		echo "MAP[$VHD_PATH]=\"${MAP[$VHD_PATH]}\""
		return 1
	fi
# RunAs Administrator: mount-vhd, get-vhd, wsl --mount
		#wsl -d Ubuntu -- \"{
		#	;
		#}<\"(wsl.exe --mount \\\\.\\\$disk)
		#Get-Content [System.Text.Encoding]::GetEncoding('utf-16').GetString(
		#	(Format-Hex $(wsl wslpath -m )).Bytes
		#)
		#wsl.exe --mount \\\\.\\\$disk
	powershell.exe -NoProfile -Command \
	"Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList '-NoProfile -Command &{
		$log \\\"===powershell (Administrator) output===\\\"
		#$log $BASHPID $$
		$log \\\"VHD path=<$VHD_PATH>\\\"
		$log \\\"Get-VHD\\\"
		\$diskno=(Get-VHD -Path $VHD_PATH).Number
		If ([String]::IsNullOrEmpty(\$diskno)) {
			$log \\\"Mount-VHD...\\\"
			\$diskno=(Mount-VHD -Path $VHD_PATH).Number
		}
		If ([String]::IsNullOrEmpty(\$diskno)) {
			$log \\\"Cannot Mount VHD: <$VHD_PATH>\\\"
			return
		}
		$log \\\"Disk Number=\$diskno\\\"
		\$disk=\\\"$VHD_PREFIX\$diskno\\\"
		$log \\\"wsl --mount \\\\.\\\$disk\\\"
		wsl -d Ubuntu -- wsl.exe --mount \\\"\\\\\\\\.\\\\\$disk\\\" \\\">\\\" \\\"$STDOUT\\\"
		$log \\\"Write $MNT_LOG\\\"
		Set-Content -Path \$(wsl wslpath -m $MNT_LOG) -Encoding UTF8 -NoNewline -Value \$disk
	} *>&1 | wsl -d Ubuntu -- cat \\\">\\\" \\\"$STDOUT\\\"
	'"
	#Write-Output \"6a54s1d2f\" | wsl -d Ubuntu -- cat \">\" /proc/$$/fd/3 # TODO
	#echo var=$var # TODO
	if [ ! -f $MNT_LOG ]; then
		echo "Fail to mount VHD \"$VHD_PATH\""
		return -1
	fi
	PHYSICAL_DRIVE=$(tr -cd "[:print:]" < $MNT_LOG) # remove \x00 \xff \xfe: (tr -cd "[:print:]")
	xxd $MNT_LOG
	echo -n $PHYSICAL_DRIVE | xxd
	MAP+=( [$VHD_PATH]=$PHYSICAL_DRIVE ) # update MAP
	export DISK=$(declare -p MAP)
	rm $MNT_LOG
	return 0
}

unmount-vhd() {
	if [ ! -f "$1" ]; then
		echo "\"$1\" is not a file"
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
		echo "MAP\[$VHD_PATH\] is None"
		return -1
	fi
	sync # !!! IMPORTANT !!!
	PHYSICAL_DRIVE="${MAP[$VHD_PATH]}"
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

case "$1" in
_)
#	for cmd in "${@:2}"; do
#		echo "> $cmd"
#	done
	for cmd in "${@:2}"; do
#		echo "> $cmd"
		eval "$cmd"
	done
	RETVAL=0
;;
*)
	echo "Usage: $0 {start|stop|restart|reload|force-reload|load|save|status}" >&2
	echo "$@" >&2
	RETVAL=1
esac

exit $RETVAL

#### 1

#powershell.exe -command "Start-Process -Verb RunAs cmd -ArgumentList \"/C $($portproxycmd)\""
#-Command &{ wsl --mount $(Write-Output "\\.\PhysicalDrive$((Mount-VHD -Path D:\subsystem\ubuntu\Ubuntu.vhdx -PassThru | Get-Disk).Number)") }

#### 2

#\$dollar=\\\"\`\$\\\"
##\$le=\\\"\`<\\\"
##\$ge=\\\"\`>\\\"

#\\\"\\\"\`\$(wslpath -m <( wsl.exe --mount \\\\.\\\$disk ))\\\"\\\" 

#&{
#	wsl -d Ubuntu -- \\\"$(readlink -f $0)\\\" _ \
#	path=\\\"<(\\\" wsl.exe --mount \\\\.\\\$disk \\\")\\\" \
#	\\\"ls -la --color \\\\\"\$dollar( wslpath -m \$dollar\`\\\"path\`\\\" )\\\\\" \\\" \ 
#	\\\"powershell.exe Get-Content -Path \\\\\"\$dollar( wslpath -m \$dollar\`\\\"path\`\\\" )\\\\\" -Encoding Unknown -Raw\\\"
#}

#&{wsl -d Ubuntu -- \\\"$(readlink -f $0)\\\" _ \
#	path=\\\"<(\\\" wsl.exe --mount \\\\.\\\$disk \\\")\\\" \
#	\\\"path=\\\\\"\$dollar( wslpath -m \$dollar\`\\\"path\`\\\" )\\\\\" \\\" \
#	\\\"echo \$dollar\`\\\"path\`\\\" \\\" \
#	\\\"powershell.exe Get-Content -Path \$dollar\`\\\"path\`\\\" -Encoding Unknown -Raw\\\"
#}

#### 3

##$procI=New-Object System.Diagnostics.ProcessStartInfo
##$procI.FileName="wsl"
##$procI.RedirectStandardOutput=$true
##$procI.UseShellExecute=$false
##$procI.Arguments="--mount \\.\PHYSICALDRIVE2"
##$procE=New-Object System.Diagnostics.Process
##$procE.StartInfo=$procI
##$procE.Start() *>&1 | Out-Null
##$procE.WaitForExit()
##$str=$procE.StandardOutput.ReadToEnd()
#$str=$(wsl --mount 1)
#[System.Text.Encoding]::GetEncoding('utf-16').GetString([System.Text.Encoding]::Default.GetBytes($str))

####
