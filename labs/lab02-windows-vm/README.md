# Lab 2 — A Windows guest, and a network between them

Pair: Yermukhan / Imanbayeva  Driver first half: Yermukhan
Machine: DESKTOP-3BUM2A8 (AMD Ryzen 7 7700, 32 GB DDR5, Windows 11 Pro 10.0.26300), VirtualBox 7.2.22
Guests: `win11` (Windows 11 Enterprise Evaluation), `ubuntu-server` (Ubuntu Server 26.04.1 LTS)
Date: 01.11.2026

## What I did

### 1. Host check

Host facts were collected from the command line ([evidence/host-specs.txt](evidence/host-specs.txt)):

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, ConfiguredClockSpeed
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent
```

### 2. Windows 11 evaluation VM

Built from the Windows 11 Enterprise **evaluation** ISO (no licence key entered, 90-day evaluation).
Unattended install skipped; local account created through *Sign-in options → Domain join instead*.
Guest Additions installed for the shared clipboard.

| VM | vCPU | RAM | Disk | Firmware |
|---|---|---|---|---|
| win11 | 4 | 8192 MB | 64 GB, dynamic | EFI, TPM 2.0, Secure Boot |
| ubuntu-server | 2 | 2048 MB | 25 GB, dynamic | BIOS |

**Why these numbers.** The host has 16 threads and 31,863 MB of usable RAM. With both guests off, the host
itself already holds about 10 GB (21,619 MB free, 14,961 MB committed — see
[host-memory-before.txt](evidence/host-memory-before.txt)). Windows 11 needs at least 4 GB and 64 GB of disk
to install; I gave it 8 GB so it is usable, not just bootable. Ubuntu Server has no graphical shell and runs
comfortably in 2 GB. Together the guests take 10 GB of RAM and 6 of 16 threads, which leaves the host about
11 GB free and 10 threads — enough to keep the browser and terminal responsive while both guests run.

### 3. Network: VirtualBox NAT Network

```
Tools → Network → NAT Networks → Create
  Name: NatNetwork   Prefix: 10.0.2.0/24   DHCP: on
Both VMs → Settings → Network → Adapter 1 → Attached to: NAT Network → NatNetwork
```

| Mode | Guests see each other | Internet | Verdict |
|---|---|---|---|
| NAT (default) | no — each guest gets its own isolated 10.0.2.0/24 | yes | fails the task |
| Host-only | yes | no | fails the task |
| Internal | yes | no | fails the task |
| Bridged | yes | yes | risky on campus: MAC filtering can silently drop the guest |
| **NAT Network** | **yes** | **yes** | **chosen** |

NAT Network is the only mode that meets both requirements without depending on the outside network:
the guests share one virtual subnet behind a virtual router (10.0.2.1) that NATs them to the internet.
A port forward (host 127.0.0.1:2222 → 10.0.2.3:22) was added so I could SSH into Ubuntu from the host
terminal and copy output as text.

```
                 Internet
                     │
        ┌────────────┴────────────┐
        │ Host DESKTOP-3BUM2A8    │
        │ VirtualBox NAT Network  │
        │ "NatNetwork" 10.0.2.0/24│
        │ gateway 10.0.2.1        │
        └─────┬─────────────┬─────┘
              │             │
     ┌────────┴──────┐ ┌────┴───────────┐
     │ ubuntu-server │ │ win11          │
     │ 10.0.2.3      │◄►│ 10.0.2.15      │
     │ TTL 64        │ │ TTL 128        │
     └───────────────┘ └────────────────┘
```

Addresses:

```bash
# Ubuntu
ip addr | tee ip-addr-linux.txt
```
```powershell
# Windows
ipconfig /renew
ipconfig /all | Tee-Object ipconfig-windows.txt
```

### 4. Connectivity in both directions

The first ping from Linux to Windows failed:

```bash
ping -c 4 10.0.2.15        # 4 transmitted, 0 received, 100% packet loss
```

Windows Firewall drops inbound ICMP Echo Requests by default, and the new adapter was classified as a
**Public** network ([firewall-profile.txt](evidence/firewall-profile.txt)), the most restrictive profile.
The firewall was **not** turned off — one inbound rule was added for ICMPv4 type 8 (echo request) only.
`-Profile Any` makes the rule independent of how Windows classifies the network:

```powershell
Get-NetConnectionProfile | Tee-Object firewall-profile.txt
New-NetFirewallRule -DisplayName "Allow ICMPv4 Echo In" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow -Profile Any
Get-NetFirewallRule -DisplayName "Allow ICMPv4 Echo In" | Format-List DisplayName,Enabled,Direction,Action,Profile | Tee-Object firewall-rule.txt
```

Then both directions plus the internet:

```bash
ping -c 4 10.0.2.15 | tee ping-linux.txt
ping -c 4 8.8.8.8 | tee -a ping-linux.txt
ping -c 4 google.com | tee -a ping-linux.txt
```
```powershell
ping -n 4 10.0.2.3 | Tee-Object ping-windows.txt
ping -n 4 8.8.8.8 | Tee-Object ping-windows.txt -Append
ping -n 4 google.com | Tee-Object ping-windows.txt -Append
```

### 5. Memory overcommitment

Host memory was measured with the same block before and during the experiment
(`Get-Counter` fails on a Russian-locale Windows because counter names are localized, so CIM classes were used):

```powershell
& {
  "=== $(Get-Date) ==="
  Get-CimInstance Win32_OperatingSystem | Select-Object @{n='TotalMB';e={[int]($_.TotalVisibleMemorySize/1KB)}}, @{n='FreeMB';e={[int]($_.FreePhysicalMemory/1KB)}}
  Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory | Select-Object AvailableMBytes, @{n='CommittedMB';e={[int]($_.CommittedBytes/1MB)}}, @{n='CommitLimitMB';e={[int]($_.CommitLimit/1MB)}}, PercentCommittedBytesInUse, PagesPerSec
  Get-CimInstance Win32_PageFileUsage | Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage
} | Format-List | Tee-Object host-memory-before.txt   # and host-memory-after.txt
```

1. Both guests off → measured "before".
2. Raised allocations: win11 **20480 MB**, ubuntu-server **16384 MB** — 36 GB promised on a 32 GB host.
3. Started both guests and filled memory in Ubuntu:
   ```bash
   sudo apt install -y stress
   stress --vm 2 --vm-bytes 7G --vm-keep --timeout 180
   ```
   and opened many Edge tabs in the Windows guest.
4. Measured "after" while the load was running.
5. Returned the allocations to 8192 MB / 2048 MB.

## Result

**Network:** both guests reach each other and the internet ([ping-both-ways.txt](evidence/ping-both-ways.txt)).

| From → To | Result | TTL in reply |
|---|---|---|
| Linux → Windows, before rule | 100% loss | — |
| Linux → Windows, after rule | 0% loss, ~0.27 ms | 128 (Windows) |
| Windows → Linux | 0% loss, <1 ms | 64 (Linux) |
| Linux → 8.8.8.8 / google.com | 0% loss, ~88 ms | 116 / 112 |
| Windows → 8.8.8.8 / google.com | 0% loss, ~85 ms | 116 / 112 |

**Memory overcommitment:**

| Metric | Before (guests off) | During overcommit |
|---|---|---|
| Free physical memory | 21,619 MB | **223 MB** |
| Available | 21,546 MB | 364 MB |
| Committed | 14,961 MB | **40,450 MB** |
| Commit limit (RAM + pagefile) | 35,831 MB | **44,075 MB** |
| Committed in use | 41 % | 91 % |
| Pages/sec | 0 | **176,151** |
| pagefile.sys allocated | 3,968 MB | **12,212 MB** |

What the host did, in order:

1. **Ran out of physical RAM.** Free memory fell from 21.6 GB to 223 MB; Task Manager showed 30.9 of 31.1 GB
   in use and the file cache shrunk to 244 MB.
2. **Paged hard to disk.** Pages/sec went from 0 to 176,151 and the NVMe system disk sat at 100 %.
3. **Grew the page file on the fly.** pagefile.sys went from 3,968 MB to 12,212 MB, which raised the commit
   limit from 35.8 GB to 44.1 GB — Windows bought itself room by promising disk as memory.
4. **Became unusable for the person at the keyboard.** The mouse lagged, and Chrome and Discord on the host
   closed on their own.
5. **Stopped a guest.** When the commit limit was reached, VirtualBox could not get pages for Ubuntu and put it
   into **Guru Meditation** ([vbox-log-extract.txt](evidence/vbox-log-extract.txt)):
   ```
   PGM: Failed to procure handy pages; rc=VERR_NO_PAGE_MEMORY
   Changing the VM state from 'RUNNING' to 'GURU_MEDITATION'
   ```
   At that moment Ubuntu had 0x2b7bcf = 2,849,743 pages × 4 KB ≈ **10.9 GB** actually backed by the host,
   out of the 16 GB it had been promised.

Conclusion: overcommitment "works" only while guests do not use what they were promised. Once they do,
the host trades RAM for disk, becomes unresponsive, kills its own applications, and finally the hypervisor
fails a guest outright. After the experiment the allocations were returned to 8192 MB / 2048 MB.

## What did not work the first time

**1. The Windows guest hung on a black screen.**
*What I saw:* the installer never appeared. The VM's execution-engine indicator showed
`native API`, Nested Paging *inactive* ([execution-engine-before.png](evidence/execution-engine-before.png)).
*What it was:* virtualization was enabled in firmware, but Windows on the host was already running its own
hypervisor. `HypervisorPresent` was `True`, `systeminfo` reported "A hypervisor has been detected", and the
registry had `EnableVirtualizationBasedSecurity = 1` — Virtualization-Based Security / Memory Integrity was
holding VT-x/AMD-V, so VirtualBox had to run on top of Hyper-V.
*What I did:*
```powershell
bcdedit /set hypervisorlaunchtype off
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Name EnableVirtualizationBasedSecurity -Value 0
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled -Value 0
# reboot
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent   # False
```
`bcdedit` alone was not enough — `HypervisorPresent` stayed `True` until VBS was turned off in the registry.
Afterwards the indicator showed `VT-x/AMD-V`, Nested Paging *active*
([execution-engine-after.png](evidence/execution-engine-after.png),
[hypervisor-after.txt](evidence/hypervisor-after.txt)), and the installer loaded in seconds.

**2. Ping from Linux to Windows: 100 % packet loss.**
Expected — Windows Firewall blocks inbound echo requests. Fixed with a single ICMPv4 type 8 rule instead of
disabling the firewall ([ping-linux-to-win-blocked.txt](evidence/ping-linux-to-win-blocked.txt),
[firewall-rule.txt](evidence/firewall-rule.txt)).

**3. stress-ng crashed with SIGILL instead of using memory.**
*What I saw:* `caught SIGILL, address ... (ILL_ILLOPN)`, both workers failed in 20 seconds
([stress-ng-sigill.txt](evidence/stress-ng-sigill.txt)).
*What it was:* the faulting bytes start with `62 f1 fd 48` — an EVEX prefix, i.e. an AVX-512 instruction.
stress-ng detected AVX-512 support (the Ryzen 7 7700 has it) and picked an optimized code path, but the
instruction was not allowed to execute inside the VirtualBox guest.
*What I did:* switched to the older `stress` tool, which uses plain code, with `--vm-keep` so the memory
stays allocated for the whole run.

## Evidence

- [evidence/host-specs.txt](evidence/host-specs.txt) — host CPU, RAM, disks, firmware, hypervisor state, from PowerShell
- [evidence/ipconfig-windows.txt](evidence/ipconfig-windows.txt) — Windows guest got 10.0.2.15 on NatNetwork, gateway 10.0.2.1
- [evidence/ip-addr-linux.txt](evidence/ip-addr-linux.txt) — Ubuntu guest got 10.0.2.3 on the same /24
- [evidence/ping-linux-to-win-blocked.txt](evidence/ping-linux-to-win-blocked.txt) — first attempt, blocked by the firewall
- [evidence/firewall-profile.txt](evidence/firewall-profile.txt) — Windows guest network classified as Public
- [evidence/firewall-rule.txt](evidence/firewall-rule.txt) — the ICMPv4 echo rule, enabled, inbound, allow
- [evidence/ping-both-ways.txt](evidence/ping-both-ways.txt) — both directions and the internet, after the fix
- [evidence/execution-engine-before.png](evidence/execution-engine-before.png) — VirtualBox running on Hyper-V (native API)
- [evidence/execution-engine-after.png](evidence/execution-engine-after.png) — VirtualBox using VT-x/AMD-V directly
- [evidence/hypervisor-after.txt](evidence/hypervisor-after.txt) — `HypervisorPresent: False` after disabling VBS
- [evidence/host-memory-before.txt](evidence/host-memory-before.txt) / [.png](evidence/host-memory-before.png) — host memory with guests off
- [evidence/host-memory-after.txt](evidence/host-memory-after.txt) / [.png](evidence/host-memory-after.png) — host memory during overcommit
- [evidence/stress-ng-sigill.txt](evidence/stress-ng-sigill.txt) — stress-ng failing with an illegal instruction
- [evidence/vbox-log-extract.txt](evidence/vbox-log-extract.txt) — VirtualBox log: `VERR_NO_PAGE_MEMORY` → Guru Meditation
- [evidence/guru-meditation.png](evidence/guru-meditation.png) — the Guru Meditation dialog for ubuntu-server during overcommit
- [evidence/vm-settings.png](evidence/vm-settings.png) — win11 as configured: 8192 MB, 4 CPUs, 64 GB disk, EFI/TPM 2.0/Secure Boot, NAT Network
