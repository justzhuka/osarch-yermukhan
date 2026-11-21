# Lab 5: open a CSV in Excel, LibreOffice Calc and `cat` in the Ubuntu guest side by side,
# take one full-screen screenshot, then close everything WITHOUT saving.
# Run from labs/lab05-encoding in your own PowerShell window:
#   powershell -ExecutionPolicy Bypass -File scripts\screenshots.ps1 -Mode before   -> evidence\opens-before.png
#   powershell -ExecutionPolicy Bypass -File scripts\screenshots.ps1 -Mode after    -> evidence\opens-correctly.png
#   powershell -ExecutionPolicy Bypass -File scripts\screenshots.ps1 -Mode doubleclick -> evidence\excel-doubleclick.png
# before      : staff-broken.csv - Excel as by double-click, LibreOffice import dialog at its default charset
# after       : staff-fixed.csv  - Excel via import (UTF-8, ';'), LibreOffice with UTF-8 and ';'
# doubleclick : staff-fixed.csv  - Excel as by double-click only (shows the BOM works; columns depend on list separator)
param([ValidateSet('before','after','doubleclick')][string]$Mode = 'after',
      [string]$SshTarget = 'tima@127.0.0.1', [int]$SshPort = 2222)
$ErrorActionPreference = 'Stop'
$lab  = (Get-Location).Path
$name = if ($Mode -eq 'before') { 'staff-broken.csv' } else { 'staff-fixed.csv' }
$file = Join-Path $lab "evidence\$name"
$png  = Join-Path $lab ('evidence\' + @{ before = 'opens-before.png'; after = 'opens-correctly.png'; doubleclick = 'excel-doubleclick.png' }[$Mode])
if (-not (Test-Path $file)) { throw "Not found: $file (run from labs/lab05-encoding)" }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices; using System.Collections.Generic;
public class W {
  public delegate bool EP(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EP f, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool r);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  public static List<KeyValuePair<IntPtr,string>> All() {
    var r = new List<KeyValuePair<IntPtr,string>>();
    EnumWindows((h,l) => { if (IsWindowVisible(h)) { var s = new StringBuilder(512); GetWindowText(h,s,512); if (s.Length>0) r.Add(new KeyValuePair<IntPtr,string>(h,s.ToString())); } return true; }, IntPtr.Zero);
    return r; }
}
"@
function Find-Win([string[]]$patterns, $timeout = 60) {
  for ($i = 0; $i -lt $timeout * 2; $i++) {
    foreach ($p in $patterns) { $w = [W]::All() | Where-Object { $_.Value -like $p } | Select-Object -First 1; if ($w) { return $w.Key } }
    Start-Sleep -Milliseconds 500 }
  throw "window '$($patterns -join ' / ')' not found" }
function Place($h, $x, $y, $w, $ht) { [void][W]::ShowWindow($h, 9); [void][W]::MoveWindow($h, $x, $y, $w, $ht, $true); [void][W]::SetForegroundWindow($h) }

# 1. Terminal: `file` and `cat` inside the Ubuntu guest (needs evidence/ there, see README)
$guestScript = "cd ~/lab05-encoding && clear && echo '`$ file evidence/$name' && file evidence/$name && echo '`$ cat evidence/$name' && cat evidence/$name && exec bash"
$enc = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($guestScript))
Start-Process wt -ArgumentList @('-w','new','--title','LAB5-TERM','--suppressApplicationTitle','ssh','-t','-p',"$SshPort",$SshTarget,"echo $enc | base64 -d | bash")
$term = Find-Win @('LAB5-TERM*')

# 2. Excel
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $true
if ($Mode -eq 'after') {
  # = Data > From Text/CSV: File origin 65001 (UTF-8), delimited, separator ';'
  $xl.Workbooks.OpenText($file, 65001, 1, 1, 1, $false, $false, $true, $false, $false, $false)
} else {
  [void]$xl.Workbooks.Open($file)   # = double-click
}
[void]$xl.ActiveSheet.UsedRange.Columns.AutoFit()
$xlh = [IntPtr]$xl.Hwnd

# 3. LibreOffice Calc
$lo = $null
if ($Mode -ne 'doubleclick') {
  $so = @("$env:ProgramFiles\LibreOffice\program\soffice.exe", "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $so) { throw 'LibreOffice not found' }
  if ($Mode -eq 'after') { Start-Process $so -ArgumentList @('--calc','--nologo','--infilter="CSV:59,34,76,1"',"`"$file`"") }   # 59=';' 76=UTF-8
  else                   { Start-Process $so -ArgumentList @('--calc','--nologo',"`"$file`"") }                              # import dialog, default charset
  $lo = Find-Win @("*$name*") 120     # import dialog "... - [staff-*.csv]" or the Calc window
}

Start-Sleep 2
if ($lo) { Place $xlh 0 0 960 620; Place $lo 960 0 960 620 } else { Place $xlh 0 0 1920 620 }
Place $term 0 620 1920 420
Start-Sleep 2

$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
$g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size)
$bmp.Save($png, [Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
"Saved $png"

# 4. Close everything without saving
foreach ($wb in @($xl.Workbooks)) { $wb.Close($false) }
$xl.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
Get-Process soffice, soffice.bin -ErrorAction SilentlyContinue | Stop-Process -Force
[void][W]::PostMessage($term, 0x10, [IntPtr]::Zero, [IntPtr]::Zero)
