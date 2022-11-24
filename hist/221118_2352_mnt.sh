#!/bin/bash
if [ -z "$DISK" ]; then
# exec diskpart script to attach a vdisk file named D:\\subsystem\\ubuntu\\Ubuntu.vhdx'\nattach vdisk
#	echo -e select vdisk file=\'D:\\\\subsystem\\\\ubuntu\\\\Ubuntu.vhdx\'\\nattach vdisk | powershell.exe diskpart
# exec powershell script to get <drive path> of the attached vdisk,
# if any vdisk is mounted, DISK=PHYSICALDRIVEx, in which x is a digit;
# else DISK='';
	CMD_RESULT="\$(Get-CimInstance -Query \"SELECT DeviceID from Win32_DiskDrive where Model like 'Microsoft %'\")"
	CMD_ATTACH="diskpart.exe /s 'D:\\\\subsystem\\\\MountVHD.diskpart.script.txt'"
	export DISK=$(
		powershell.exe -Command \&\{`echo "
\\\$result=$CMD_RESULT;
If (\\\$result -eq '') {
	$CMD_ATTACH;
	\\\$result=$CMD_RESULT;
}
If (\\\$result -ne '') {
	\\\$(\\\$result | findstr \"PHYSICALDRIVE\").Trim(' ')
}" # powershell script
		`\}
	)
	if [ -z "$DISK" ]; then
		echo "No 'Microsoft VHD' is attached to the host."
		exit
	fi
	DISK=${DISK:4:-3}
	powershell.exe runas /noprofile /user:Administrators\\Y.Lin \"powershell /noexit wsl --mount \\\\.\\$DISK\"
	#ln -vsf wsl/$DISK /mnt/data
	echo $DISK | xxd
fi
