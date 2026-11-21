# Four builds for the second office

All prices are from **shop.kz (Белый Ветер)**, which delivers across Kazakhstan (EMS, Kazpost, DHL, CDEK, Exline). They are the "internet shop" price including VAT, taken on **21.11.2026 at 16:39 Almaty time**. Every line is in [budget.csv](budget.csv), and each product page is screenshotted in [evidence/vendor-quotes/](evidence/vendor-quotes/).

| # | Role | Total, KZT | budget.csv rows |
|---|---|---:|---|
| 1 | Accountant | 540,400 | 2–12 |
| 2 | Sales manager | 626,700 | 13–24 |
| 3 | Web developer | 564,210 | 25–35 |
| 4 | Designer | 1,157,610 | 36–46 |
| | **Total** | **2,888,920** | |
| | Reserve left of 3,000,000 | 111,080 (3.7%) | |

## The decision that shaped all four: DDR4, not DDR5

Memory is unusually expensive in November 2026. On the same day, at the same shop:

| | DDR4-3200 | DDR5-5600 | Difference |
|---|---:|---:|---:|
| 16 GB (2×8 GB kit) | 66,990 | 159,990 (Kingston Fury Beast 5200) | ×2.4 |
| 32 GB (2×16 GB kit) | 152,990 | 282,990 | ×1.85 |

Three of the four machines need 32 GB. On DDR5 the memory alone would cost about 390,000 KZT more for the office, and the budget would not hold. So all four use **AMD AM4** (Ryzen 5000, DDR4).

**Trade-off accepted:** AM4 is an end-of-line platform. The CPU upgrade path stops at the Ryzen 5000 series, and in four or five years the next machine is a new platform anyway. For office work over 4–5 years, the CPUs below are not the limit. Memory and storage are, and both stay upgradeable on AM4.

**Where I kept the director's "same machines" idea:** the parts that do not depend on the job are shared, so spares and repairs are simpler. That is the same case, cooler, keyboard and mouse, the same 23.8" monitor on three desks, and the same SSD in three machines. What differs is what each job actually loads.

---

## Build 1 — Accountant

**Load:** 1C:Accounting, Excel, a browser with the tax portal (cabinet.salyk.kz) and the bank client, PDFs and scanned documents. Light but constant, all day. The data is the company's money, and a corrupted 1C database is the worst thing that can happen to this desk.

**Bottleneck:** not the CPU. It is **reliability and single-thread responsiveness**. 1C's file-mode database is damaged by power loss in the middle of a write. Almaty office buildings get short power dips.

**Choices:**
- Ryzen 5 5600GT (6 cores, Vega 7 iGPU). It is more than enough for 1C and Excel, and the iGPU means no graphics card to buy or to fail.
- 16 GB as 2×8 GB. Two sticks give dual-channel memory, which the iGPU depends on. One 16 GB stick would cost about the same (69,990) and halve graphics bandwidth.
- **A UPS (FSP iFP 1000, 46,990).** This is the only build with one, because it is the only desk where a power cut can destroy data rather than just a few minutes of work.
- Windows 11 **Pro**, not Home. This gives BitLocker for the accounting data and Remote Desktop, which I need if 1C runs from the main office (see the README, question 3).

**Trade-off:** the cheapest motherboard (A520M, 2 memory slots). The upgrade to 32 GB therefore means replacing the kit rather than adding to it. I accepted that because memory is at a price peak today. It is better to buy the minimum now and upgrade in 18 months, when prices have usually come down.

**Total:** 540,400 KZT (budget.csv, rows 2–12)

## Build 2 — Sales manager

**Load:** CRM in a browser with 30–40 tabs, WhatsApp Web, Excel, and several hours of video calls a day (Zoom/Meet/Teams), often all at once.

**Bottleneck:** **memory, not CPU.** A browser with forty tabs plus a video call uses about 11–12 GB. On 16 GB the machine is already near the edge and starts paging in the middle of a customer call. That is the worst possible moment, and it is exactly what Lab 6 showed: the machine stays "working", but everything stalls while the disk is paging.

**Choices:**
- The same CPU and board as the accountant. The CPU idles in this role.
- **32 GB (2×16 GB).** This is where the extra money goes.
- A USB headset (Jabra Evolve 20) and a 1080p webcam (Logitech Brio 100). The Xiaomi monitor has no camera or microphone. Calls are this person's job, and audio is what customers notice first.

**Trade-off:** I took a Ryzen 5 rather than a Ryzen 7 (115,590) and an A520 board rather than a B550. The roughly 36,000 KZT saved went towards the 32 GB, which costs 86,000 more than 16 GB.

**Total:** 626,700 KZT (budget.csv, rows 13–24)

## Build 3 — Web developer

**Load:** an IDE (VS Code or a JetBrains IDE), Docker with 3–5 containers (database, backend, frontend dev server), `npm`/`composer` builds, two or three browsers with dev tools open, and a call now and then.

**Bottleneck:** **memory first, then cores and disk.** Each container is a set of processes with its own memory. Docker plus an IDE plus browsers passes 16 GB easily. Builds and test runs use every core they get, and `node_modules` means hundreds of thousands of small files, so an NVMe SSD makes a noticeable difference.

**Choices:**
- Ryzen 7 5700G: 8 cores / 16 threads **with integrated graphics**. A developer does not need a graphics card, and the iGPU drives both monitors.
- B550M PRO-VDH: 4 memory slots, so 32 → 64 GB later just by adding a kit.
- 32 GB DDR4.
- **Two monitors**: code on one, the browser on the other. For this role that is a bigger productivity gain than a faster CPU.
- **Ubuntu 24.04 LTS** instead of Windows. The developer's code will almost certainly run on Linux servers, and Docker runs natively on Linux, with no WSL2 virtual machine eating memory. It is a properly licensed OS (free, GPL/Canonical licence), and it saves 102,990 KZT.

**Trade-off:** the 5700G's iGPU limits the CPU to PCIe 3.0, so the PCIe 4.0 SSD runs at about 3.5 GB/s instead of 6 GB/s. I kept the same SSD as the other machines anyway (identical spares). The difference does not matter for this workload. Random small-file access matters, not sequential speed.

**Risk:** if the developer must test in Windows-only software, Windows 11 Pro still fits in the reserve (+102,990 → total 2,991,910).

**Total:** 564,210 KZT (budget.csv, rows 25–35)

## Build 4 — Designer

**Load:** Photoshop, Illustrator and Figma, layered PSD files of several hundred MB, and export for web and print. I assume a 2D graphic designer, not video or 3D (see the README, section 2).

**Bottleneck:** two of them. **First, colour accuracy.** A designer on an uncalibrated office monitor produces work that looks different everywhere else, and no amount of CPU fixes that. **Second, memory and GPU** for large layered files. Photoshop uses the GPU for canvas rendering and for its filters and AI features, and keeps the history in RAM and on the scratch disk.

**Choices:**
- **ASUS ProArt PA279CRV** (27", 4K IPS, a factory-calibrated colour line). At 359,990 KZT it is the most expensive single part in the office, and deliberately so. The 24" Xiaomi monitors on the other desks have no colour specification at all.
- RTX 5050 8 GB. It handles Adobe GPU acceleration and AI filters, plus 4K output.
- Ryzen 7 5700X (32 MB L3, no iGPU, cheaper than the 5700G) and 32 GB DDR4.
- Samsung 990 SSD, running at full PCIe 4.0 speed on this CPU. Photoshop's scratch disk and large files are the one place in the office where a faster disk shows.
- A 650 W PSU, because of the graphics card.

**Trade-off:** I took an **RTX 5050 (220,990) instead of an RTX 5060 (305,990)**. The 5060 is up to 25–30% faster in games, which is not this workload. The 85,000 KZT saved paid for most of the gap between an office monitor and the ProArt. For 2D design the monitor is the part that decides quality. The GPU only decides how fast filters run.

**Total:** 1,157,610 KZT (budget.csv, rows 36–46)

---

## What "four identical machines" would have cost

| If all four were… | Cost | What goes wrong |
|---|---:|---|
| Accountant-class (Build 1) | 4 × 540,400 = 2,161,600 | It fits the budget, but the designer gets no GPU and an uncalibrated screen, and sales and the developer get 16 GB. Two of the four people complain in the first week. |
| Designer-class (Build 4) | 4 × 1,157,610 = 4,630,440 | 54% over budget. The accountant gets a 360,000 KZT colour monitor to look at 1C. |

There is no single machine that is both affordable and adequate for all four jobs. The loads are different, so the bottlenecks are different, and the money should go where each bottleneck is.
