# Lab 0 — Inventory your own machine
Pair: Yermukhan — individual work    Driver: Yermukhan (whole session)
Machine: ASUS Vivobook Pro 15 OLED (K3500PH), Windows 10 Pro 22H2 — the laptop I use for the whole course
Date: 25.10.2026

## What I did
Every value below came from PowerShell. No graphical system information window was used for the table.
Each evidence file contains the command (`PS> ...`) followed by its raw output.

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List
Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, @{n='GB';e={$_.Capacity/1GB}}, Speed, ConfiguredClockSpeed | Format-Table -AutoSize
Get-CimInstance Win32_PhysicalMemoryArray | Select-Object MemoryDevices, @{n='MaxGB';e={$_.MaxCapacity/1MB}} | Format-List
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystem, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}} | Format-Table -AutoSize
$env:firmware_type
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Format-List
Get-CimInstance Win32_Processor | Select-Object VirtualizationFirmwareEnabled, VMMonitorModeExtensions, SecondLevelAddressTranslationExtensions | Format-List
Get-CimInstance Win32_ComputerSystem | Select-Object HypervisorPresent | Format-List
```

## Result
| What | Value | Where I got it |
|---|---|---|
| CPU model | 11th Gen Intel Core i5-11300H @ 3.10 GHz | `Get-CimInstance Win32_Processor` → `Name` |
| CPU cores | 4 | `Get-CimInstance Win32_Processor` → `NumberOfCores` |
| CPU threads | 8 | `Get-CimInstance Win32_Processor` → `NumberOfLogicalProcessors` |
| Total memory | 8 GB | `Get-CimInstance Win32_PhysicalMemory` → sum of `Capacity` |
| Memory modules | 2 × 4 GB, Micron 4ATF51264HZ-3G2J1, one per channel (Controller0 / Controller1) | `Get-CimInstance Win32_PhysicalMemory` → `DeviceLocator`, `Capacity`, `PartNumber` |
| Memory speed | 3200 MT/s (configured 3200) | `Get-CimInstance Win32_PhysicalMemory` → `Speed`, `ConfiguredClockSpeed` |
| Memory slots reported | 2, both occupied | `Get-CimInstance Win32_PhysicalMemoryArray` → `MemoryDevices` |
| Disk model | NVMe INTEL SSDPEKNU512GZ, 476.9 GB | `Get-PhysicalDisk` → `FriendlyName`, `Size` |
| Disk type | NVMe SSD (`MediaType` = SSD; see below about `BusType`) | `Get-PhysicalDisk` → `MediaType`, `BusType`, `FriendlyName` |
| Volume C: | 150.5 GB, 21.6 GB free | `Get-Volume` → `Size`, `SizeRemaining` |
| Volume D: (for VMs) | 325.8 GB, **314.7 GB free** | `Get-Volume` → `Size`, `SizeRemaining` |
| Firmware type | UEFI | `$env:firmware_type` |
| Firmware version | American Megatrends, X3500PH.302 | `Get-CimInstance Win32_BIOS` → `Manufacturer`, `SMBIOSBIOSVersion` |
| Firmware date | 08.08.2022 | `Get-CimInstance Win32_BIOS` → `ReleaseDate` |
| Hardware virtualization present | Yes: VT-x (`VMMonitorModeExtensions` = True), SLAT/EPT (`SecondLevelAddressTranslationExtensions` = True) | `Get-CimInstance Win32_Processor` |
| Hardware virtualization enabled | **Yes**: `VirtualizationFirmwareEnabled` = True | `Get-CimInstance Win32_Processor` |
| Hypervisor already running | No: `HypervisorPresent` = False, so Hyper-V does not hold VT-x and VirtualBox can use it directly | `Get-CimInstance Win32_ComputerSystem` |

**Memory and upgrades.** The 8 GB is two 4 GB modules in two channels, and the system reports two memory devices,
both filled. There is no free slot: more memory means replacing a module, not adding one.
(`MaxGB` = 128 is what the firmware's memory array reports, not a realistic limit for this laptop. Before buying
anything, I would check in the service manual whether both modules are removable or one is soldered.)

**Where VMs go.** The VMs go on **D:** with 314.7 GB free, not on C: with 21.6 GB. A Windows 11 guest in Lab 2
needs about 64 GB of disk, which C: cannot hold.

## What did not work the first time
- **I first did Lab 0 on the wrong computer.** My first version was measured on a desktop
  (Ryzen 7 7700, 32 GB), but the VMs run on this laptop. Lab 1 resource decisions have to match the host the VM
  actually runs on, so I redid the inventory here.
- **`BusType` says `RAID`, not `NVMe`.** The drive is an NVMe SSD (`FriendlyName` starts with "NVMe", `MediaType`
  is SSD), but Windows reports the bus as RAID. Most likely the drive sits behind Intel's storage controller (RST/VMD mode),
  so Windows reports the controller, not the bare NVMe interface. One field alone would have given the wrong answer.
- **The Lab 1 VM was created on the volume with no space.** VirtualBox's default folder is on C:, so the Lab 1 VM
  (25 GB dynamic disk) went to C:, which has only 21.6 GB free, while D: has 314.7 GB. The inventory made this visible.
  Fix: move the VM and the default VM folder to D: before Lab 2.

## Evidence
- [evidence/cpu.txt](evidence/cpu.txt) — CPU model, 4 cores, 8 threads
- [evidence/memory.txt](evidence/memory.txt) — two 4 GB modules at 3200 MT/s, two memory devices
- [evidence/disk.txt](evidence/disk.txt) — NVMe SSD model and size; free space on C: and D:
- [evidence/firmware.txt](evidence/firmware.txt) — UEFI, BIOS X3500PH.302 from 08.08.2022
- [evidence/virtualization.txt](evidence/virtualization.txt) — VT-x and SLAT present and enabled, no hypervisor running
