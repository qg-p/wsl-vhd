$target=[System.Text.Encoding]::GetEncoding('utf-8')
##$default=[System.Text.Encoding]::Default
##$u16=[System.Text.Encoding]::GetEncoding('utf-16')
##$src=$(wsl --mount 1)


#$src | Format-Hex
foreach ($msg in $src) {
if ($msg.Length>1) {
$str=$default.GetBytes($msg)
#$str | Format-Hex
$str=[System.Text.Encoding]::Convert($u16, $target, $str)
#$str | Format-Hex
$str=$target.GetString($str)
#$str | Format-Hex
$str
}
}