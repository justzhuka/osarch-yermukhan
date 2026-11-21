# Lab 5: convert evidence/staff-broken.csv from KZ-1048 (RK1048) to UTF-8 with BOM, LF line endings.
# Run from labs/lab05-encoding:  powershell -ExecutionPolicy Bypass -File scripts\fix.ps1
#
# .NET has no KZ-1048 decoder. KZ-1048 is Windows-1251 with 18 positions replaced by
# Kazakh letters, so: decode as 1251, then override those 18 byte values.
$in  = "$PWD\evidence\staff-broken.csv"
$out = "$PWD\evidence\staff-fixed.csv"

$kz = @{
    0x8C = 0x04A2; 0x8D = 0x049A; 0x8E = 0x04BA   # Ң Қ Һ
    0x9C = 0x04A3; 0x9D = 0x049B; 0x9E = 0x04BB   # ң қ һ
    0xA1 = 0x04B0; 0xA2 = 0x04B1; 0xA3 = 0x04D8   # Ұ ұ Ә
    0xA5 = 0x04E8; 0xAA = 0x0492; 0xAF = 0x04AE   # Ө Ғ Ү
    0xB2 = 0x0406; 0xB3 = 0x0456; 0xB4 = 0x04E9   # І і ө
    0xBA = 0x0493; 0xBC = 0x04D9; 0xBF = 0x04AF   # ғ ә ү
}
$cp1251 = [Text.Encoding]::GetEncoding(1251)
$table  = $cp1251.GetString([byte[]](0..255)).ToCharArray()
foreach ($k in $kz.Keys) { $table[$k] = [char]$kz[$k] }

$bytes = [IO.File]::ReadAllBytes($in)
$sb = New-Object Text.StringBuilder $bytes.Length
foreach ($b in $bytes) { [void]$sb.Append($table[$b]) }
$text = $sb.ToString() -replace "`r`n", "`n"          # CRLF -> LF

$utf8 = New-Object Text.UTF8Encoding($true)           # $true = with BOM (for Excel)
[IO.File]::WriteAllText($out, $text, $utf8)
"Written $out"
