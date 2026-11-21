# Lab 6 — Live processes and memory pressure

Pair: Yermukhan / Imanbayeva  Driver first half: Yermukhan
Machine: MACHCREATOR L16A laptop (AMD Ryzen 7 7735HS, 16 GB RAM, Windows 11 Pro) — host, VirtualBox;
Ubuntu Server 26.04.1 LTS guest `ubuntu-server` (2 vCPU, 2048 MB in VirtualBox = 1.6 GiB usable, 2 GiB swap file);
Windows 11 Enterprise evaluation guest `win11` (4 vCPU, 8192 MB)
Date: 21.11.2026

The Ubuntu guest's clock is UTC; all Linux times below are UTC (host time = UTC+5).

## Part 1 — One process, three tools

**Process chosen: `ping` to the loopback address** — `ping 127.0.0.1` in Ubuntu, `ping -t 127.0.0.1` in Windows.
Why: the same program exists on both guests with nothing to install, it runs until stopped, and it is small enough
that every figure can be checked by hand. (The guide's first choice, VBoxService, is not available: Guest
Additions are not installed in the Ubuntu server guest.)

In Ubuntu I started it from a script, so its parent is a known shell
([`scripts/htop-view.sh`](scripts/htop-view.sh)): `bash` (PID 1891) → `ping` (PID 1894), inside a tmux session.

```bash
htop -t -p 1894,1891                      # tree view, ping and its parent; columns PID PPID … NLWP added in F2
ps -o pid,ppid,user,rss,vsz,nlwp,stat,lstart,cmd -p 1894,1891
pstree -sp 1894                           # systemd(1)---tmux: server(1890)---bash(1891)---ping(1894)
grep -E 'PPid|Threads|VmSize|VmRSS|RssAnon|RssFile|VmSwap' /proc/1894/status
sudo ls -l /proc/1894/fd
```

Windows (in the `win11` guest), started 13:19:57 local time from Command Prompt in Windows Terminal:

```cmd
ping -t 127.0.0.1
```

Task Manager → Details with extra columns (Select columns: Working set, Memory (private / shared working set),
Commit size, Handles, Threads, Command line); Process Explorer run as administrator with columns PPID, Handles,
Threads, Virtual Size, WS Private, WS Shareable and the lower pane in Handles view; plus the same figures from
PowerShell (`Get-Process`, `Win32_Process`, `Win32_PerfFormattedData_PerfProc_Process`) as a cross-check.

| | Task Manager (Details, 13:31) | Process Explorer (13:39) | htop / ps / `/proc` |
|---|---|---|---|
| Name | `PING.EXE` | `PING.EXE` | `ping` |
| PID | 6052 | 6052 | 1894 |
| Parent (name and PID) | — (not shown) | PPID 8944 = `cmd.exe` (its PPID 4772 = `explorer.exe`) | `bash` 1891 (PPID column; tree view) |
| "Memory" as shown by default | 560 K — *Memory (active private working set)* | Private Bytes 928 K and Working Set 5 408 K are the defaults | MEM% 0.1–0.2 % |
| Private memory | 560 K — *Memory (private working set)* | 524 K — WS Private; 928–932 K — Private Bytes | RssAnon 164 kB at 07:49, 128 kB at 08:16 (`/proc/1894/status`) |
| Working set / RES | 5 500 K — *Working set (memory)* | 5 408–5 420 K — Working Set | RES 3120 KiB at 07:49, 2220 KiB at 08:02 |
| Shared | 4 940 K — *Memory (shared working set)* | ≈ 4 850 K — WS Shareable | SHR 2956 → 2092 KiB (RssFile 2956 kB) |
| Virtual size | — (no column) | 2 151 730 564 K ≈ **2 TB** — Virtual Size | VIRT 8068 KiB (VmSize) |
| Commit | 928 K — *Commit size* | = Private Bytes (928 K) | — (no column) |
| Handles / file descriptors | 82 — *Handles* | 82, listed in the lower pane (`\KnownDlls`, `\Device\ConDrv\…`, `\Device\Nsi`, `ping.exe.mui`, `HKLM\…\WinSock2\…` keys, …) | 5 fds: 0,1 → `/dev/null`, 2 → `/dev/pts/0`, 3,4 → `socket:[…]` (`sudo ls -l /proc/1894/fd`) |
| Threads | 3 | 3 | 1 (NLWP, `Threads:`) |

PowerShell in the guest agrees: `Get-Process PING` → HandleCount 82, Threads 3, WorkingSet 5 480 K,
PrivateMemorySize 928 K, VirtualMemorySize 2 151 730 564 K; the perf counter *WorkingSetPrivate* = 552 K;
`Win32_Process` → `PING.EXE 6052 ← cmd.exe 8944 ← explorer.exe 4772`
([`windows-get-process.png`](evidence/windows-get-process.png),
[`windows-parent-and-counters.png`](evidence/windows-parent-and-counters.png)).

Evidence: [`evidence/htop.png`](evidence/htop.png), [`evidence/htop.txt`](evidence/htop.txt),
[`evidence/ping-details.txt`](evidence/ping-details.txt), [`evidence/ping-fds.txt`](evidence/ping-fds.txt),
[`evidence/task-manager.png`](evidence/task-manager.png), [`evidence/process-explorer.png`](evidence/process-explorer.png).

### Where the tools disagree

1. **The parent.** Task Manager has no parent column at all. Process Explorer shows it as the tree (one level up)
   and on the Image tab; htop shows it as a tree (F5) or as the PPID column, which is not on by default — I added it
   in F2 → Columns.
2. **"Memory" is three different things.**
   - Task Manager's default *Memory* column is the **private working set** — only pages that belong to this
     process alone and are in RAM.
   - htop's **RES** is the whole resident set *including shared library pages* (`RES = RssAnon + RssFile`:
     164 + 2956 ≈ 3120 KiB). For `ping` almost all of RES is shared code (SHR 2956 KiB); its truly private
     part is only 164 kB. So "RES 3 MB" in htop and "Memory 560 K" in Task Manager are not the same number
     measured differently — they are different quantities. The Windows tools show the same split:
     Working set 5 500 K = private 560 K + shared 4 940 K.
   - Even the two Windows tools disagree slightly on "private": Task Manager 560 K (private working set),
     Process Explorer 524 K (WS Private), the performance counter 552 K — sampled at different moments of a
     process that is constantly touching pages, and counted by slightly different rules.
   - **Commit size** (Task Manager) ≈ **Private Bytes** (Process Explorer): memory the process has *reserved
     the right* to use, in RAM or in the page file. htop has no column for this.
   - **Virtual size** is the most dramatic one: htop's VIRT is 8 MB, Process Explorer's Virtual Size for the
     same little program is **2 151 730 564 K ≈ 2 TB** — more than the guest's RAM and disk together. It is
     *reserved address space*, not memory: 64-bit Windows reserves a ~2 TB region in every process for the
     Control Flow Guard bitmap. Nothing is committed there, which is why Commit size is still 928 K. Task Manager
     does not even offer this column.
3. **RES changes without the process doing anything.** At 07:49 `ping` had RES 3120 KiB; at 08:02, after the
   memory-pressure experiment, 2220 KiB, and at 08:16 `/proc/1894/status` showed `VmSwap: 36 kB`. Its pages were
   evicted while `memhog.py` needed RAM. Same process, same work, different "memory" — depending on what else the
   machine was doing.
4. **Handles vs file descriptors.** Windows counts *handles* to every kernel object (files, registry keys,
   events, threads, the console…), so even `PING.EXE` has 82: the console device (`\Device\ConDrv\Input`,
   `Output`, `Reference`), the network store interface `\Device\Nsi`, the current directory, `ping.exe.mui`,
   a dozen registry keys (WinSock2 catalogs, Image File Execution Options…), events, a mutant, threads. Linux `/proc/<pid>/fd` lists only file
   descriptors: `ping` has 5 — stdin and stdout on `/dev/null` (started in the background with `> /dev/null`),
   stderr on the terminal `/dev/pts/0`, and two sockets (one ICMP socket for IPv4, one for IPv6).
5. **Threads.** Linux `ping` is single-threaded (NLWP 1); Windows `PING.EXE` has 3 threads although it does the
   same job — the Windows loader starts worker threads in every process.
6. **Where the process is at all.** On Task Manager's *Processes* tab `PING.EXE` is not listed by itself — it is
   folded into the app group "Terminal (3)". Only the *Details* tab and Process Explorer show it one by one.
7. **CPU %.** Task Manager counts the whole machine as 100 %; htop counts one core as 100 % (on this 2-vCPU guest
   a fully busy process can show 200 %).
8. **Permission to look.** As the same user `tima` I could read `ping`'s memory from `/proc/1894/status`, but
   `ls /proc/1894/fd` → *Permission denied*. `ping` has the file capability `cap_net_raw` (`getcap /usr/bin/ping`),
   so the kernel marks the process non-dumpable and its `/proc` fd directory belongs to root — `sudo` was needed.
   It stays that way even after `ping` has dropped the capability: `CapEff: 0000000000000000` in its status, yet
   the fd links are still `root root`.
   The Windows counterpart: Process Explorer must run as administrator to show handles of other processes.

## Part 2 — Memory pressure

Guest RAM: 2048 MB configured, **1.6 GiB** seen by Linux · swap: **2.0 GiB** file `/swap.img`.
Snapshot `before-lab6` was taken first (powered off — see "What did not work").

`stress-ng --vm` cannot run in this guest: its vm stressor dies with `SIGILL` (an AVX-512 instruction the virtual
CPU does not support — the same failure as in Lab 2). So I used a 15-line allocator,
[`scripts/memhog.py`](scripts/memhog.py): it adds 64 MiB every 0.5 s and fills each chunk with non-zero bytes, so
every page is really touched and must live in RAM or swap.

Steps ([`scripts/pressure.sh`](scripts/pressure.sh)):

```bash
# tmux session "rec":  free -h every 2 s + vmstat -t 2   -> memory-pressure.txt, vmstat.txt
# tmux session "hog":  python3 memhog.py 64 0.5         -> memhog.log
bash ~/lab06/pressure.sh
journalctl -k --since "07:45" | grep -i -E -B3 -A8 "out of memory|oom-kill" > kernel-log-extract.txt
```

| (run 2, UTC) | Before 07:59:24 | During — worst, 08:00:05 | After 08:00:18 |
|---|---|---|---|
| Used | 356 Mi | 1.6 Gi | 340 Mi |
| Available | 1.3 Gi | 44 Mi (lowest 33 Mi at 07:59:57) | 1.3 Gi |
| Swap used | 9.8 Mi | 1.9 Gi (101 Mi free; kernel: *Free swap = 12kB* at 08:00:08) | 23 Mi |
| vmstat `so` (swap-out) | 0 | up to 108 800 KiB/s (07:59:52) | 0 |
| vmstat `sy` (kernel CPU) | 2 % | up to 74 % | 2–3 % |

What happened, with times (from [`evidence/memory-pressure.txt`](evidence/memory-pressure.txt),
[`evidence/vmstat.txt`](evidence/vmstat.txt), [`evidence/memhog.log`](evidence/memhog.log)):

- **07:59:30** memhog starts. For 10 s free RAM drops ~250 MiB per 2 s and nothing else changes; a 64 MiB chunk
  takes 0.04 s.
- **07:59:41** *available* falls below 100 Mi. **07:59:42** swap starts to grow (10 → 200 MiB in one vmstat
  interval) and stays the only thing that grows: RAM is pinned at ~1.6 Gi, the kernel pushes 55–109 MB/s to swap.
- **Responsiveness:** a 64 MiB chunk now takes up to 0.58 s (×15), the CPU spends up to 74 % in the kernel
  (`sy`) doing page reclaim, and the 2-second recorder loop slipped once (08:00:05 → 08:00:08). SSH still answered —
  with a fast host disk this was heavy swapping, not a frozen machine.
- **08:00:05** swap almost full (1.9 Gi used, 101 Mi free), memhog at 3392 MiB.
- **08:00:08 the kernel killed it.** Within the same second used RAM dropped 1.6 Gi → 349 Mi, swap 1.9 Gi → 404 Mi
  → 23 Mi; `so` back to 0.
- After: the machine is exactly where it started (available 1.3 Gi). `ping` (PID 1894) and sshd survived.

### What the kernel did

[`evidence/kernel-log-extract.txt`](evidence/kernel-log-extract.txt):

```
Nov 21 08:00:08 tima kernel: python3 invoked oom-killer: gfp_mask=0x140dca(GFP_HIGHUSER_MOVABLE|__GFP_ZERO|__GFP_COMP), order=0, oom_score_adj=0
Nov 21 08:00:08 tima kernel: Free swap  = 12kB
Nov 21 08:00:08 tima kernel: [  pid  ]   uid  tgid total_vm      rss rss_anon rss_file rss_shmem pgtables_bytes swapents oom_score_adj name
Nov 21 08:00:08 tima kernel: [   1099]     0  1099     2686      831      293      538         0    61440        0         -1000 sshd
Nov 21 08:00:08 tima kernel: [   4191]  1000  4191   889462   356788   356183      605         0  7069696   516902             0 python3
Nov 21 08:00:08 tima kernel: oom-kill:constraint=CONSTRAINT_NONE,…,global_oom,task_memcg=/user.slice/user-1000.slice/user@1000.service/tmux-spawn-e21aa955-….scope,task=python3,pid=4191,uid=1000
Nov 21 08:00:08 tima kernel: Out of memory: Killed process 4191 (python3) total-vm:3557848kB, anon-rss:1424732kB, file-rss:2420kB, shmem-rss:0kB, UID:1000 pgtables:6904kB oom_score_adj:0
Nov 21 08:00:08 tima systemd[1772]: tmux-spawn-e21aa955-….scope: Failed with result 'oom-kill'.
```

- **Which process:** `python3`, PID 4191 — my `memhog.py`.
- **Why that one:** it was the process that itself asked for a page (`python3 invoked oom-killer`) when RAM and
  swap were both exhausted (*Free swap = 12kB*, `constraint=CONSTRAINT_NONE`, `global_oom` — the whole machine,
  not a cgroup limit). The killer picks the task with the highest badness score, which is essentially its memory
  share: `python3` held 356 788 resident pages (≈ 1.36 GiB) **plus 516 902 pages in swap** (≈ 1.97 GiB) — orders of
  magnitude more than anything else in the table. `sshd` has `oom_score_adj -1000` and could never be chosen;
  `systemd-journald` has -250.
- **When:** 08:00:08 UTC — the same second `memory-pressure.txt` shows used RAM collapsing from 1.6 Gi to 349 Mi
  and memhog's log stopping at 3392 MiB (08:00:07).
- **And then systemd:** the line after the kernel's is from the user's systemd: the whole tmux scope that held the
  hog *failed with result 'oom-kill'* and was stopped — every process in it, not only the one the kernel chose.
  That is `DefaultOOMPolicy=stop` (see below).

Run 1 (07:50:24, PID 1979) ended the same way; its file is
[`evidence/memory-pressure-run1.txt`](evidence/memory-pressure-run1.txt).

### Windows

On the `win11` guest:

```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Resource-Exhaustion-Detector'} -MaxEvents 5 |
  Format-List TimeCreated, Id, Message
```

Result ([`evidence/windows-event-log.png`](evidence/windows-event-log.png)):

```
Get-WinEvent : No events were found that match the specified selection criteria.
```

This guest has never run low on commit: commit limit 10 335 108 K (8 GB RAM + page file), free 7 853 868 K at
13:25 (`Win32_OperatingSystem`). The provider itself describes the event I would expect
(`Get-WinEvent -ListProvider Microsoft-Windows-Resource-Exhaustion-Detector`):

```
Id          : 2004
Description : Windows successfully diagnosed a low virtual memory condition. The following programs consumed
              the most virtual memory: %21 (%22) consumed %24 bytes, %28 (%29) consumed %31 bytes, and %35 (%36) consumed %38 bytes.
```

Windows has no OOM killer. When the commit charge reaches the commit limit (RAM + page file), new allocations
simply fail (`VirtualAlloc` returns an error, the program may crash or show "out of memory"), Windows grows the
page file if it is system-managed, and the **Resource-Exhaustion-Detector** writes **event 2004** to the System log
— *"Windows successfully diagnosed a low virtual memory condition"* — listing the processes that used the most
committed memory. The same class of event as Linux's OOM line, but a *report*, not an execution: Linux picks a
victim and kills it; Windows tells you who is responsible and leaves the decision to the applications and the user.
An empty result is the expected one here: nothing on this guest ever pushed the commit charge near the limit.

## What did not work the first time

- **The live snapshot hung.** `VBoxManage snapshot ubuntu-server take before-lab6 --live` stopped at 90 % for
  15 minutes; the VM log showed `RUNNING_LS` and *Guest seems to be unresponsive*, the `.sav` file stayed at 0 MB,
  and `controlvm poweroff` hung too. I had to kill the VM process (state `aborted`) and take the snapshot again with
  the VM powered off, which took seconds — as the guide recommends. The hard power-off left a trace in the guest:
  `systemd-journald: … user-1000.journal corrupted or uncleanly shut down, renaming and replacing`.
- **Run 1 lost its "after".** I ran the `free -h` recorder, `vmstat` and the hog in one script in one tmux session.
  At 07:50:24 the kernel killed only `python3`, but the recorder and vmstat stopped too: the user systemd instance
  has `DefaultOOMPolicy=stop`, so when the OOM killer hits a process in a scope, systemd stops the whole scope
  (`tmux-spawn-….scope: Failed with result 'oom-kill'`). Run 1's file ends at 07:50:22 with no "after". In run 2 the
  recorder and the hog run in two separate tmux sessions — two scopes — and the recorder survived.
- **`stress-ng --vm` crashes with `SIGILL`** in this guest (Lab 2) — replaced by `memhog.py`.
- **`ls /proc/1894/fd` → Permission denied** for my own process — `ping`'s `cap_net_raw` makes it non-dumpable;
  needed `sudo`.

## Evidence

- [evidence/task-manager.png](evidence/task-manager.png) — `PING.EXE` (PID 6052) in Task Manager → Details: working set, private / shared working set, commit, handles, threads, command line
- [evidence/process-explorer.png](evidence/process-explorer.png) — the same process in Process Explorer (administrator), PPID, handles, threads, virtual size, WS private / shareable, and its 82 handles in the lower pane
- [evidence/process-explorer-parent.png](evidence/process-explorer-parent.png) — its parent `cmd.exe` 8944, whose parent is 4772 (`explorer.exe`)
- [evidence/windows-get-process.png](evidence/windows-get-process.png), [windows-parent-and-counters.png](evidence/windows-parent-and-counters.png) — the same figures from PowerShell
- [evidence/windows-event-log.png](evidence/windows-event-log.png) — `Get-WinEvent` for Resource-Exhaustion-Detector: no events; what event 2004 would say; commit limit
- [evidence/htop.png](evidence/htop.png) — `ping` 1894 under `bash` 1891 in htop's tree view, PPID and NLWP columns
- [evidence/htop.txt](evidence/htop.txt) — the same htop screen as text (07:49)
- [evidence/ping-details.txt](evidence/ping-details.txt) — `ps`, `pstree`, `/proc/1894/status` and the *Permission denied*
- [evidence/ping-fds.txt](evidence/ping-fds.txt) — `sudo ls -l /proc/1894/fd`, `getcap /usr/bin/ping`
- [evidence/memory-pressure.txt](evidence/memory-pressure.txt) — run 2: `free -h` before, every 2 s during, after
- [evidence/vmstat.txt](evidence/vmstat.txt) — run 2: `vmstat -t 2` — swap-out rate and kernel CPU
- [evidence/memhog.log](evidence/memhog.log) — run 2: how far the allocator got and how slow each step became
- [evidence/kernel-log-extract.txt](evidence/kernel-log-extract.txt) — the OOM killer's records for both runs + systemd's reaction
- [evidence/memory-pressure-run1.txt](evidence/memory-pressure-run1.txt), [vmstat-run1.txt](evidence/vmstat-run1.txt), [memhog-run1.log](evidence/memhog-run1.log) — run 1, cut off by systemd
- [scripts/memhog.py](scripts/memhog.py), [scripts/pressure.sh](scripts/pressure.sh), [scripts/htop-view.sh](scripts/htop-view.sh)
