#!/bin/bash
# export variable: $DISK
# tempfile: $MNT_LOG (/mnt/wsl/mount.log)
# mount or dismount ms-vhd files

VHD_PREFIX=PHYSICALDRIVE # pHYsiCaldrIVe, etc.
LOGFILE=/mnt/wsl/mnt.log

mount-vhd() {
	if [ ! -f "$1" ]; then
		echo >&2 "\"$1\" is not a file"
		exit
	fi
	VHD_PATH=$(wslpath -m $1) # <relative>/path/to/Ubuntu.vhdx -> Disk:/absolute/path/to/Ubuntu.vhdx
	if [ "//wsl" == "${VHD_PATH:0:5}" ]; then # not being a windows file, "//wsl.localhost/Ubuntu/**"
		echo >&2 "Warning: \"$1\" <$VHD_PATH> may be a virtual file"
	fi
	if [ -z "$DISK" ]; then
		declare -A MAP # <local> MAP: dictionary
		export DISK=$(declare -p MAP)
	fi
	eval "$DISK" # "declare -A MAP=(...)", unpack.
	if [ ${MAP[$VHD_PATH]+_} ]; then # if MAP[VHD_PATH] is not None # which is not '!=false'
		echo >&2 "MAP[$VHD_PATH]=\"${MAP[$VHD_PATH]}\""
		return 1
	fi
# form instr
	inner_bash_cmd_list+=( $(readlink -f $0) )
	inner_bash_cmd_list+=( _ )
	inner_bash_cmd_list+=( "_Admin_mount $VHD_PATH" )
	###inner_bash_cmd_list+=( "read" )
	for cmd in "${inner_bash_cmd_list[@]}"; do
		inner_bash_cmd+="\\\"$cmd\\\" "
	done
	inner_bash_cmd+="2\>/proc/\$\$/fd/2 1\>/proc/\$\$/fd/1"
	unset inner_bash_cmd_list

	ps_cmd="\&{Start-Process wsl -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList \'-d Ubuntu -- $inner_bash_cmd\'}"
	unset inner_bash_cmd
	bash_cmd="powershell.exe -NoProfile $ps_cmd"
	unset ps_cmd

	PHYSICAL_DRIVE=$(bash -c "$bash_cmd")
	echo -n $PHYSICAL_DRIVE | xxd >&2
	unset bash_cmd

	if [ -z "$PHYSICAL_DRIVE" ]; then
		echo >&2 "Fail to mount VHD \"$VHD_PATH\""
		return -1
	fi
	MAP+=( [$VHD_PATH]=$PHYSICAL_DRIVE ) # update MAP
	export DISK=$(declare -p MAP)
	return 0
}

# RunAs Administrator: mount-vhd, get-vhd, wsl --mount
# usage: _Admin_mount C:/path/to/file.vhdx
_Admin_mount() {
	VHD_PATH="$1"
	echo >&2 -n "====== bash (Administrator) output ======
VHD path=\"$VHD_PATH\"
Get-VHD..."
	diskno=$(powershell.exe -NoProfile -NonInteractive -Command \
		"(Get-VHD -Path \"$VHD_PATH\").Number")
	diskno=${diskno%?}
	if [ -z "$diskno" ]; then
		echo >&2 -n "Mount-VHD..."
		diskno=$(powershell.exe -NoProfile -NonInteractive -Command \
			"(Mount-VHD -Path \"$VHD_PATH\" -Passthru).Number")
		diskno=${diskno%?}
	fi
	if [ -z "$diskno" ]; then
		echo >&2 "Cannot mount VHD: \"$VHD_PATH\""
		return 0
	fi
	disk="$VHD_PREFIX$diskno"
	echo >&2 -e "Disk Number=$diskno
wsl.exe --mount \\\\\\\\.\\\\$disk"
	(wsl.exe --mount "\\\\.\\$disk" || return 1) | iconv -f unicode -t utf-8 >&2 # cause halt if write stderr directly
	echo -n "$disk" # return
	return 0
}

STDIN=/proc/$$/fd/0
STDOUT=/proc/$$/fd/1
STDERR=/proc/$$/fd/2
#TTY=$(tty)
unmount-vhd() {
	if [ ! -f "$1" ]; then
		echo >&2 "\"$1\" is not a file"
		exit
	fi
	VHD_PATH=$(wslpath -m $1)
# MAP is None
	if [ -z "$DISK" ]; then
		echo >&2 "Env Var \$DISK is not set"
		return -1
	fi
	eval "$DISK" # unpack
# MAP is loaded
	if [ ! ${MAP[$VHD_PATH]+_} ]; then
		echo >&2 "MAP\[$VHD_PATH\] is None"
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
#		echo >&2 "> $cmd"
#	done
	for cmd in "${@:2}"; do
#		echo >&2 "> $cmd"
		eval "$cmd"
	done
	RETVAL=0
;;
*)
	echo >&2 "Usage: $0 {start|stop|restart|reload|force-reload|load|save|status}"
	echo >&2 "$@"
	RETVAL=1
esac

exit $RETVAL
