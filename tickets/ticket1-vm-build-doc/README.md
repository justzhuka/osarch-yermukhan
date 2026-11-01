# Ticket 1 — New developer starts Monday, needs a test machine

> **Credit.** The two virtual machines this ticket documents (`win11`, `ubuntu-server`, NatNetwork) were built in
> [Lab 2](../../labs/lab02-windows-vm/), which I did in a pair with **Imanbayeva Daiana** (I was the driver for the first half).
> The evidence linked from `../../labs/lab02-windows-vm/` comes from that joint work.
> This ticket — the report, BUILD.md, the new evidence in `evidence/` and the screenshots — is my individual submission.

## 1. What was asked

> From: Aigerim T. (Office Manager)
> Subject: test machine for new dev
>
> Hi, we have someone starting on Monday and he needs a test computer
> set up. Nothing special, just so he can try things without breaking
> anything. Can you write down how to do it so I can do the next one
> myself? Thanks

## 2. What was actually needed

**What the request left out, and what I assumed instead:**

| Gap | What I would have asked Aigerim | What I assumed |
|---|---|---|
| Physical or virtual? | "Do you want to buy a second PC, or run it inside his work computer?" | Virtual machines on an existing PC. Cheaper, ready by Monday, and resettable — a second physical PC cannot be "un-broken" in one click. |
| Which operating system | "What will he develop for — servers, Windows apps, web?" | Both: Ubuntu Server 26.04 LTS (most dev/server work) and Windows 11 (desktop/testing). Covers the likely cases without knowing his stack. |
| Host hardware | "What computer will this run on — how much memory and disk?" | My own desktop (AMD Ryzen 7 7700, 16 threads, 32 GB RAM, 948 GB free on C:); the build doc states minimum host requirements so Aigerim can check the next PC herself. |
| Internet / network | "Does he need internet? Do the machines need to talk to each other?" | Yes to both — a developer test environment that cannot download packages is useless, and testing client/server needs two machines that see each other. |
| Licensing | "Is there a Windows licence for this?" | None. Used the 90-day Windows 11 Evaluation and wrote the expiry into the build doc. |

**Where the request is wrong:**

1. *"Nothing special"* — two things in it are special. "Try things without breaking anything" is a real requirement: it needs **snapshots** (restore to a clean state), not just a machine. And "so I can do the next one myself" means the actual deliverable is **the document**, written for a non-technical reader — the VM is only the proof that the document works.
2. *"A test computer"* — taken literally, one machine. For a developer, one isolated machine cannot test anything networked; the useful unit is two machines on a shared network.
3. Default VirtualBox networking (NAT) would have satisfied "it has internet" but silently failed "the machines see each other". The request gives no hint of this, and it is the kind of thing Aigerim would not discover until the developer complains.

## 3. What I did

**Resource calculation** (host: AMD Ryzen 7 7700, 16 logical CPUs, 32 GB RAM (31 GB usable), 948 GB free on C: — see `evidence/07-host-specs.txt`)

| | RAM | vCPU | Disk (max, dynamic) |
|---|---|---|---|
| ubuntu-server | 2 GB | 2 | 25 GB |
| win11 | 8 GB | 4 | 64 GB |
| Both together | 10 GB (32%) | 6 of 16 | 89 GB (~9% of free) |
| Left for host | ~11 GB free (host itself uses ~10 GB) | 10 | ~859 GB |

Reasoning: the host has 31.9 GB usable, and with both guests off Windows on the host already holds about 10 GB (measured in Lab 2: [host-memory-before.txt](../../labs/lab02-windows-vm/evidence/host-memory-before.txt)). The guests add 10 GB, which leaves the host about 11 GB free — enough for a browser and terminal to stay responsive. Windows 11 runs on 4 GB but is sluggish with updates and a browser; 8 GB makes it usable, not just bootable. Ubuntu Server has no desktop and is fine in 2 GB. 6 of 16 threads go to guests, leaving 10 for the host. I know where the ceiling is: in Lab 2 I deliberately promised 36 GB to the guests on this host, and it ran out of RAM, paged at 176,000 pages/sec and VirtualBox stopped Ubuntu with Guru Meditation ([vbox-log-extract.txt](../../labs/lab02-windows-vm/evidence/vbox-log-extract.txt)). 10 GB is well inside the safe zone. Disk: 64 GB is Windows 11's hard minimum, 25 GB is plenty for a server; both are dynamically allocated, so they only take what is actually written (`ubuntu-server.vdi` 6.6 GB, `win11.vdi` 26.1 GB on disk now — 33 GB actually used out of 89 GB allowed).

Trade-off accepted: these numbers are for a 32 GB host. On a 16 GB machine 8 GB for Windows would leave the host 6 GB with both guests running — so BUILD.md tells the reader to drop Windows to 4 GB there.

**Settings that differ from the default, and why:**

| Setting | Default | Mine | Why |
|---|---|---|---|
| Network adapter (both) | NAT | NAT Network `NatNetwork` | Default NAT isolates each VM; NAT Network gives internet *and* guest-to-guest. |
| Ubuntu RAM / CPUs / disk | 2048 MB / 2 / 25 GB | unchanged | Checked the wizard's proposals against the load and kept them: a server without a desktop doesn't need more. Not every setting has to be changed to be a decision. |
| Windows RAM / CPUs | 4096 MB / 2 | 8192 MB / 4 | See calculation above: the host has the headroom, and 4 GB makes Windows sluggish once updates and a browser run. |
| Windows disk | 80 GB | 64 GB | 64 GB is the Windows 11 minimum and the installed system uses 26 GB, leaving ~38 GB for a test machine's tools. Trade-off: less room for large feature updates; if the developer installs heavy SDKs, the disk can be enlarged later, while shrinking a VDI is much harder — so I started at the minimum. |
| OpenSSH on Ubuntu | off | on | Lets me pull command output out as text (evidence), and the dev will want it. |
| Windows firewall | inbound ICMP blocked, network classified Public | one inbound rule: ICMPv4 type 8, `-Profile Any` | Otherwise Ubuntu → Windows ping fails (100% loss — [ping-linux-to-win-blocked.txt](../../labs/lab02-windows-vm/evidence/ping-linux-to-win-blocked.txt)); opened one thing instead of switching the firewall off. |
| Snapshots | none | `clean-install` on both | The "without breaking anything" requirement. |
| Interface language | — | Russian | The reader in the Almaty office will most likely have VirtualBox in Russian; menu names in BUILD.md match what they will see. |

**Decision: NAT Network vs the alternatives**

- *NAT (default)* — internet yes, guests can't see each other. Fails a requirement.
- *Bridged* — guests get real network addresses and see each other, but the Innotech network filters unknown MAC addresses, and at the office it would expose test machines on the real LAN.
- *NAT + second Host-only adapter* — works, but two adapters per VM is two more steps for Aigerim and two IP addresses to explain.
- *NAT Network* — one adapter, internet + guest-to-guest, isolated from the real LAN. Trade-off I accepted: the host can't reach the guests directly without a port-forwarding rule (I added one, 2222 → Ubuntu:22, only for collecting evidence; Aigerim doesn't need it).

**Steps:** followed `BUILD.md` Steps 1–10. To get command output out of the guests as text rather than screenshots, I added one port-forwarding rule to the NAT Network so the host can SSH into Ubuntu, then ran everything from the host in PowerShell:

```powershell
$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
& $vbm natnetwork modify --netname NatNetwork --port-forward-4 "ssh:tcp:[]:2222:[10.0.2.3]:22"

ssh -p 2222 tima@127.0.0.1 "hostnamectl; echo; uname -a; echo; ip -4 addr show" | Out-File -Encoding utf8 evidence\04-guest-uname.txt
ssh -p 2222 tima@127.0.0.1 "ping -c 4 8.8.8.8; echo; ping -c 4 10.0.2.15" | Out-File -Encoding utf8 evidence\05-ping-between-guests.txt
```

`Out-File -Encoding utf8` instead of `>` because Windows PowerShell 5.1 writes `>` as UTF-16, which GitHub shows as binary. The Windows side (`ver`, `ipconfig`, `ping 8.8.8.8`, `ping 10.0.2.3`) was copied out of `cmd` through the shared clipboard and appended to `05`. `07` and `08` come from `VBoxManage` and `Get-CimInstance` on the host.

**What went wrong and how I fixed it:**

**The Windows installer hung on a black screen.**

*What I saw:* after **Запустить**, the `win11` window stayed black — the installer never appeared. Virtualization was "Включено" in Task Manager, so the hardware looked fine.

*What I first thought:* a bad ISO or wrong EFI/TPM settings.

*What it actually was:* the VM's status bar showed the execution engine as `native API` with Nested Paging inactive ([execution-engine-before.png](../../labs/lab02-windows-vm/evidence/execution-engine-before.png)). `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent` returned `True`: Windows 11 on the host was running its own hypervisor for Virtualization-Based Security / Memory Integrity and holding AMD-V, so VirtualBox had to run on top of Hyper-V instead of the hardware.

*What fixed it:* `bcdedit /set hypervisorlaunchtype off` alone was **not** enough — `HypervisorPresent` stayed `True`. Only after also turning VBS off in the registry and rebooting did it become `False` ([hypervisor-after.txt](../../labs/lab02-windows-vm/evidence/hypervisor-after.txt)); the engine switched to `VT-x/AMD-V`, Nested Paging active ([execution-engine-after.png](../../labs/lab02-windows-vm/evidence/execution-engine-after.png)), and the installer loaded in seconds.

*What prevents it now:* BUILD.md "Before you start" has a second check — `HypervisorPresent` must be `False` — because the Task Manager check that Aigerim would naturally do says "Включено" in exactly this broken situation. This is the most likely place for her to get stuck on a new Windows 11 PC.

## 4. Evidence

| File | What it proves |
|---|---|
| [evidence/01-new-vm-wizard.png](evidence/01-new-vm-wizard.png) | Wizard section 1: name, Ubuntu 26.04.1 ISO, automatic installation unticked. Name typed as `ubuntu server` because `ubuntu-server` already exists on this host |
| [evidence/02-disk-settings.png](evidence/02-disk-settings.png) | 25 GB VDI, "Выделить место в полном размере" unticked — dynamically allocated |
| [evidence/03-network-adapter.png](evidence/03-network-adapter.png) | Адаптер 1 of ubuntu-server attached to Сеть NAT / NatNetwork, not default NAT |
| [evidence/04-guest-uname.txt](evidence/04-guest-uname.txt) | Ubuntu 26.04.1 LTS running inside VirtualBox (`Virtualization: oracle`), kernel 7.0.0, address 10.0.2.3 in 10.0.2.0/24 |
| [evidence/05-ping-between-guests.txt](evidence/05-ping-between-guests.txt) | Ubuntu → internet (8.8.8.8, 0% loss) and Ubuntu → Windows (10.0.2.15, 0% loss); Windows section shows the reverse direction |
| [evidence/06-snapshot-list.png](evidence/06-snapshot-list.png) | Both machines show `(clean-install)`, taken while powered off; current state unchanged — the rollback mechanism |
| [evidence/07-host-specs.txt](evidence/07-host-specs.txt) | Real host CPU/RAM/disk figures the resource calculation is based on |
| [evidence/09a-win11-wizard-default-hardware.png](evidence/09a-win11-wizard-default-hardware.png) / [09b-…-disk.png](evidence/09b-win11-wizard-default-disk.png) | What VirtualBox proposes for Windows 11 on its own (4096 MB, 2 CPUs, 80 GB) — the "default" column in the settings table above is read off the wizard, not guessed |
| [evidence/08-vm-config.txt](evidence/08-vm-config.txt) | Actual VM settings from `VBoxManage` — RAM, CPUs, firmware, both NICs on `NatNetwork`, disk capacities — so the numbers in this report are checkable, not remembered |

Evidence carried over from Lab 2 (same host, same two machines), linked rather than copied:

| File | What it proves |
|---|---|
| [execution-engine-before.png](../../labs/lab02-windows-vm/evidence/execution-engine-before.png) / [-after.png](../../labs/lab02-windows-vm/evidence/execution-engine-after.png) | VirtualBox ran on top of Hyper-V before the VBS fix and on AMD-V after it |
| [hypervisor-after.txt](../../labs/lab02-windows-vm/evidence/hypervisor-after.txt) | `HypervisorPresent` is `False` after the fix — the check BUILD.md now asks for |
| [ping-linux-to-win-blocked.txt](../../labs/lab02-windows-vm/evidence/ping-linux-to-win-blocked.txt) | Before the firewall rule, Ubuntu → Windows was 100% loss — why BUILD.md Step 9 exists |
| [firewall-rule.txt](../../labs/lab02-windows-vm/evidence/firewall-rule.txt) | The one inbound ICMPv4 rule, enabled, Profile Any |
| [host-memory-before.txt](../../labs/lab02-windows-vm/evidence/host-memory-before.txt) | What the host itself uses with guests off — the base of the resource calculation |

## 5. What I would do differently

I built the machines first (in Lab 2) and wrote BUILD.md afterwards, and the first draft — written with an AI assistant, see the declaration in the root README — described a generic VirtualBox, not the one on this host. Re-walking the wizard for screenshots showed it was wrong in three places: VirtualBox 7.2 has a one-page wizard with no "Далее"/summary page (a whole step had to be deleted), the **Сеть** section of the settings is hidden until you switch to **Расширенные**, and "skip automatic installation" was not a non-default choice at all — the box is unticked by default. Any of these would have stopped the peer reviewer. Next time I would write each step while clicking through it on the real machine, in the interface language the reader will have, and only then fill in the reasons.
