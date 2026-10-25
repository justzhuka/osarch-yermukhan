# Lab 1 — Your first virtual machine
Pair: Yermukhan — individual work, as instructed in class for this lab    Driver: Yermukhan (whole session)
Machine: ASUS Vivobook Pro 15 OLED, Windows; guest: Ubuntu Server 26.04.1 LTS in VirtualBox
Date: 25.10.2026

## What I did
1. Created VM `tima` in VirtualBox: 2 vCPU, 2048 MB RAM, 25 GB dynamically allocated VDI,
   NAT network with port forwarding host 2222 → guest 22. Unattended install switched off.
2. Installed Ubuntu Server 26.04.1 LTS from the ISO, with OpenSSH server.
3. Saved the guest release from the host over SSH, so the evidence is text, not a picture:
```powershell
ssh -p 2222 tima@127.0.0.1 "echo '$ lsb_release -a'; lsb_release -a" | Out-File -Encoding utf8 guest-release.txt
```
4. Powered the guest off and took the snapshot before changing anything:
```powershell
VBoxManage snapshot "tima" take clean-install --description "fresh install, nothing changed"
```
5. Broke the system on purpose and confirmed it was broken after a reboot:
```bash
cat /etc/hostname
sudo rm /etc/hostname
cat /etc/hostname
sudo reboot
# after reboot
cat /etc/hostname
hostnamectl
```
6. Powered off and restored `clean-install`. Before restoring, the broken state was kept as a snapshot named `broken`.
7. Booted again and checked:
```bash
cat /etc/hostname
hostnamectl
```

## Resource allocation
Host: ASUS Vivobook Pro 15 OLED (K3500PH), Windows 10 Pro 22H2, Intel Core i5-11300H (4 cores / 8 threads),
8 GB RAM at 3200 MHz in 2 modules of 4 GB, 477 GB NVMe SSD with 20 GB free on C:, where the VMs are stored.

```powershell
Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed        # 2 x 4294967296 bytes, 3200
Get-PSDrive C | Select-Object @{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}} # 20
Get-CimInstance Win32_OperatingSystem | Select-Object @{n='UsedGB';e={[math]::Round(($_.TotalVisibleMemorySize-$_.FreePhysicalMemory)/1MB,1)}} # 5.2
```

Note: my first Lab 0 was measured on a different computer (a desktop). I redid it on this laptop,
see [Lab 0](../lab00-inventory/README.md); the numbers here match it.

I gave the guest 2 vCPU of 8 threads, 2 GB of 8 GB RAM and a 25 GB dynamically allocated disk.

- **Memory is the tightest resource.** Windows on the host already uses 5.2 GB, which leaves about 2.8 GB.
  2 GB for the guest leaves the host under 1 GB of headroom, so 2 GB is the most I can give, not a default.
  Ubuntu Server has no graphical shell and used 19% of its 2 GB right after login, so it does not need more.
- **CPU:** 2 vCPU leave six of eight threads for the host and, in Lab 2, the second guest.
- **Disk:** the 25 GB disk is dynamic, so it only takes the space actually written. But 25 GB is more than
  the 20 GB free on C:. If the guest ever filled its disk, the host would run out of space first.
  That is a deliberate overcommitment I have to watch.

Consequence for Lab 2: a Windows 11 guest with 4 GB RAM and a 64 GB disk does not fit this host as it stands.
Before Lab 2 I need to move the VMs to D: (314.7 GB free, see Lab 0) and lower the Linux guest's memory.

## Result
| | Broken | After rollback |
|---|---|---|
| `cat /etc/hostname` | No such file or directory | `tima` |
| Static hostname | (unset) | `tima` |
| Transient hostname | `tima` | not shown, same as static |

The prompt stayed `tima@tima` even in the broken state: a transient hostname was set at boot,
so the damage was invisible in the prompt and only `hostnamectl` showed that the static hostname was gone.
After the rollback the file and the static hostname are back.

## What did not work the first time
- **Restore failed with `VBOX_E_INVALID_VM_STATE`.** I tried to restore the snapshot while the VM was
  still running ("Cannot delete the current state of the running machine"). A snapshot can only be restored
  on a powered-off machine. I powered the VM off and the restore worked.
- **Two snapshots named `clean-install`.** I took one in the GUI and then another with VBoxManage.
  Two snapshots with the same name make "restore by name" ambiguous, so I deleted the duplicate by its UUID:
  `VBoxManage snapshot "tima" delete <uuid>`.
- **Installer waiting on "Please remove the installation medium, then press ENTER".** The optical drive
  was already empty (VirtualBox had ejected the ISO, so "Eject" was greyed out); the installer was only waiting for Enter.
- **The root filesystem is 11.2 GB, not 25 GB.** The guided LVM install gives `/` only about half of the disk
  and leaves the rest free in the volume group. Disk size and free space on the volume are different numbers.

## Evidence
- [evidence/vm-settings.png](evidence/vm-settings.png) — CPU, RAM and disk as configured
- [evidence/guest-release.txt](evidence/guest-release.txt) — the guest runs Ubuntu Server 26.04.1 LTS, with the command that produced it
- [evidence/broken.png](evidence/broken.png) — /etc/hostname missing after reboot, static hostname unset
- [evidence/restored.png](evidence/restored.png) — after the rollback /etc/hostname and the static hostname are back
- [evidence/snapshot-list.png](evidence/snapshot-list.png) — snapshots `clean-install` and `broken` after the rollback
- [evidence/restore-error.txt](evidence/restore-error.txt) — the failed restore on a running VM, from the VirtualBox log
