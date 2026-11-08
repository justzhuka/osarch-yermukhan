# collect-windows-specs.ps1 -- Lab 3, second half: CPU, memory and disk facts from the Windows command line.
#
# Usage (from the folder the script is in):
#   powershell -ExecutionPolicy Bypass -File .\collect-windows-specs.ps1
#   powershell -ExecutionPolicy Bypass -File .\collect-windows-specs.ps1 -OutFile ..\evidence\windows-specs.txt
#
# Works in Windows PowerShell 5.1 (Windows 10/11) and PowerShell 7. No admin rights needed.
# Every command is printed (with a "PS> " prompt) right before its raw output.
# The file is written as UTF-8 so GitHub shows it as text (5.1 would default to UTF-16 otherwise).

param(
    [string]$OutFile = ".\windows-specs.txt"
)

$lines = New-Object System.Collections.Generic.List[string]

function Add-Line([string]$text) {
    $lines.Add($text)
    Write-Host $text
}

function Section([string]$title) {
    Add-Line ""
    Add-Line "==================== $title ===================="
}

function Run([string]$cmd) {
    Add-Line ""
    Add-Line "PS> $cmd"
    try {
        $result = Invoke-Expression $cmd 2>&1 | Out-String -Width 220
    } catch {
        $result = "[error] $($_.Exception.Message)"
    }
    Add-Line $result.TrimEnd()
}

Add-Line "Lab 3 -- Windows specs"
Add-Line ("Collected: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss K"))
Add-Line "PowerShell version: $($PSVersionTable.PSVersion)"

Section "System"
Run 'Get-CimInstance Win32_OperatingSystem | Format-List Caption, Version, OSArchitecture'
Run 'Get-CimInstance Win32_ComputerSystem | Format-List Name, Manufacturer, Model, HypervisorPresent'

Section "CPU"
Run 'Get-CimInstance Win32_Processor | Format-List Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, SocketDesignation, VirtualizationFirmwareEnabled'
Run '$env:NUMBER_OF_PROCESSORS'
Run 'wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors'

Section "Memory"
Run 'Get-CimInstance Win32_ComputerSystem | Format-List @{n="TotalPhysicalMemory_bytes";e={$_.TotalPhysicalMemory}}, @{n="TotalPhysicalMemory_GiB";e={[math]::Round($_.TotalPhysicalMemory/1GB,2)}}'
Run 'Get-CimInstance Win32_PhysicalMemory | Format-Table BankLabel, DeviceLocator, Manufacturer, PartNumber, @{n="GiB";e={$_.Capacity/1GB}}, Speed, ConfiguredClockSpeed, SMBIOSMemoryType -AutoSize'
Run 'Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Format-List @{n="Modules";e={$_.Count}}, @{n="TotalGiB";e={$_.Sum/1GB}}'
Run 'Get-CimInstance Win32_PhysicalMemoryArray | Format-List MemoryDevices, @{n="MaxCapacity_GiB";e={$_.MaxCapacityEx/1MB}}'
Run 'wmic memorychip get BankLabel,Capacity,Speed,PartNumber'

Section "Disk"
Run 'Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, BusType, @{n="SizeGB";e={[math]::Round($_.Size/1GB,1)}} -AutoSize'
Run 'Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{n="SizeGB";e={[math]::Round($_.Size/1GB,1)}}, @{n="FreeGB";e={[math]::Round($_.SizeRemaining/1GB,1)}} -AutoSize'
Run 'wmic diskdrive get Model,InterfaceType,MediaType,Size'

# Write UTF-8 (5.1 adds a BOM, which GitHub handles fine)
$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$lines | Set-Content -Path $OutFile -Encoding UTF8
Write-Host ""
Write-Host "Saved to: $OutFile"
