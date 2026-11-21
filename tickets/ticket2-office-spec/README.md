# Ticket 2 — We are kitting out the new office

## 1. What was asked

> From: Daniyar K. (Director)
> Subject: computers for the new office
>
> We are opening the second office and need four computers — accountant,
> sales, web developer, designer. Budget 3,000,000 tenge for everything.
> Everyone says we should just buy the same four machines, is that right?
> Make sure they last a few years. Monitors included.

## 2. What was actually needed

**Short answer to the director's question: no, four identical machines is the wrong idea.** The four people put four different loads on a computer, and each load runs out of a different resource first:

| Role | Runs out of first |
|---|---|
| Accountant | reliability (power loss corrupts the 1C database) |
| Sales | memory (browser tabs plus video calls) |
| Developer | memory and cores (containers, builds) |
| Designer | colour accuracy of the screen, then GPU and memory |

One identical machine is either too weak for the designer and developer, or wastes money on the accountant. Priced out: four copies of the accountant's machine come to 2,161,600 KZT and leave two people without what they need. Four copies of the designer's machine come to 4,630,440 KZT, 54% over budget (builds.md, last section). The useful part of the director's idea is **standardising the parts that do not depend on the job**: the same case, cooler, keyboard, SSD and monitor model wherever possible. I did that.

**What the request left out, and what I assumed instead:**

| Gap | What I would have asked Daniyar | What I assumed |
|---|---|---|
| What software each person uses | "Which programs does each of them work in all day?" | Accountant: 1C + Excel + bank client. Sales: browser CRM + video calls. Developer: web stack with Docker. Designer: Adobe (Photoshop/Illustrator) + Figma, **2D only, no video or 3D**. If the designer edits video, the build changes (more memory, a stronger GPU). |
| Is software inside the 3,000,000? | "Does the budget include 1C, Microsoft Office, Adobe licences?" | **No.** Only hardware and the operating system (the ticket requires a licensed OS). Adobe Creative Cloud is a yearly subscription per person and alone would eat a large share of what is left. It has to be a separate budget line, and the director should know that now, not after delivery. |
| "Monitors included", how many? | "One per person, or two where it helps?" | One each, except **two for the developer** (code and browser side by side). That is the cheapest productivity gain in the office. The designer gets one *good* monitor rather than two ordinary ones. |
| "Last a few years", how many? | "When do you plan to replace them?" | 4–5 years. That is why every machine has room to grow: free memory slots or a cheap path to more memory, and a standard ATX power supply and case rather than a proprietary small-form-factor box. |
| Where is the 1C database? | "Does the new office work in the same 1C database as the first one?" | Yes, the database stays in the main office. This decides question 3 below. |
| Who builds the machines? | "Is there someone to assemble them, or should we pay for assembly?" | The parts list is for self-assembly (or the shop's paid assembly service, which its delivery page mentions but does not price). The 111,080 KZT reserve covers assembly or delivery. |
| Buying as a company | "Will the company pay by bank transfer with an invoice?" | Yes. Shop.kz prices include VAT, and shop.kz has a legal-entities section. A real purchase should get a written quote (счёт на оплату) at the moment of buying, because prices move. |
| Existing kit | "Are there any peripherals, a UPS or network gear in the new office already?" | Nothing. Every machine includes keyboard and mouse. Network equipment (router, switch) is **not** part of "four computers" and is not in this budget. |

**Where the request is wrong or incomplete:**

1. *"Same four machines"* — wrong, as shown above.
2. *"Make sure they last a few years"* — a computer does not last by being expensive. It lasts by having headroom where the load grows. For three of these four people, memory is what grows, so memory got the money.
3. *"Budget 3,000,000 for everything"* — "everything" quietly includes things nobody mentioned: an operating system licence (about 103,000 KZT per Windows machine), CPU coolers (the cheaper "OEM" processors come without one), a UPS for the accountant, and a headset and camera for the person who lives on video calls. All of these are in the budget.
4. The hidden constraint the request could not know about: **memory prices in November 2026**. DDR5 costs 1.85–2.4 times as much as DDR4 at the same shop on the same day. This one fact decided the platform for all four machines (builds.md, first section).

## 3. What I did

1. **Wrote down the load for each role, then the bottleneck for that load**, before looking at any prices (the table in section 2). The bottleneck decides where the money goes, not the other way round.

2. **Chose a vendor that actually delivers to Kazakhstan.** That is shop.kz (Белый Ветер): its delivery page lists courier delivery across Kazakhstan by EMS, Kazpost, DHL, CDEK and Exline. I used the "internet shop" price, which includes VAT. I did not use PCPartPicker, because it has no Kazakhstan region (explained in [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md)).

3. **Searched the shop and compared platforms.** The first plan was AM5 (Ryzen 7000/8000, DDR5). The memory prices killed it:

   | | DDR4-3200 | DDR5-5600 |
   |---|---:|---:|
   | 32 GB (2×16) | 152,990 | 282,990 |

   Three machines need 32 GB, so DDR5 would have cost about 390,000 KZT more for nothing the users would notice. I switched all four to AM4 (Ryzen 5000, DDR4).

4. **Chose each part against its role** (reasoning per build in [builds.md](builds.md)). The two decisions with real alternatives:
   - Designer: **RTX 5050 + ASUS ProArt colour-accurate 4K monitor** rather than **RTX 5060 + an ordinary monitor**. The extra 85,000 KZT goes where 2D design actually needs it.
   - Developer: **Ubuntu 24.04 LTS** rather than Windows 11 Pro. It is a licensed OS at zero cost, Docker runs natively, and the code will run on Linux servers. If the developer needs Windows, it still fits in the reserve.

5. **Checked every price on the product page itself, not on the search results.** One SSD showed 78,990 in search but 85,990 on its page; I used the page price. All prices were taken on **21.11.2026, 16:39 (Almaty)**.

6. **Checked compatibility by hand**: socket, memory type, board size, cooler height, GPU length, video outputs, power. The table is in [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md). Two near-misses turned up:
   - the cooler is 150 mm tall in a case that takes 151 mm;
   - the shop does not say whether the 650 W PSU's GPU leads are 6+2-pin.

7. **Wrote budget.csv and checked the totals with PowerShell** rather than adding them by hand:

   ```powershell
   $c = Import-Csv .\budget.csv
   $c | Group-Object role | % { "{0}: {1:N0} ({2} rows)" -f $_.Name, ($_.Group | Measure-Object price_kzt -Sum).Sum, $_.Count }
   "TOTAL: {0:N0}" -f ($c | Measure-Object price_kzt -Sum).Sum
   ```
   ```
   accountant: 540,400 (11 rows)
   sales: 626,700 (12 rows)
   webdev: 564,210 (11 rows)
   designer: 1,157,610 (11 rows)
   TOTAL: 2,888,920
   ```

8. **Screenshotted every product page as proof of price and date** with headless Microsoft Edge, one command per page:

   ```powershell
   & msedge.exe --headless=new --disable-gpu --window-size=1280,1000 `
       --virtual-time-budget=15000 --screenshot=01-cpu-ryzen5-5600gt.png `
       https://shop.kz/offer/protsessor-amd-ryzen-5-5600gt-am4-oem/
   ```

### Result

| Role | Total, KZT |
|---|---:|
| Accountant | 540,400 |
| Sales manager | 626,700 |
| Web developer | 564,210 |
| Designer | 1,157,610 |
| **Total** | **2,888,920** |
| Reserve (assembly, delivery, price movement) | 111,080 |

### Question 1 — Which machine do I upgrade first, in eighteen months, and why?

**The accountant's, and the upgrade is memory: 16 → 32 GB.**

- It is the only machine I deliberately gave the minimum (16 GB). 1C, a browser with the tax and bank portals, Excel and PDFs grow by a few gigabytes every year. Every 1C platform update and every browser update asks for a little more.
- I held it back *on purpose*, because memory is at a price peak right now (DDR4 32 GB costs 152,990 today). Buying the minimum now and upgrading later is the cheaper path, provided prices come down. If they do not, the upgrade still costs only about one kit.
- The A520 board has only two slots, so the upgrade is a swap (replace 2×8 with 2×16), not an addition. That was the price of the cheaper board.

The runner-up is the designer's GPU. Adobe keeps moving features onto the GPU, and 8 GB of video memory is the first thing that will feel tight. But that upgrade is expensive and not certain to be needed. The accountant's is cheap and almost certain.

### Question 2 — The same four as pre-built machines

Pre-built equivalents from the same vendor, same date ([screenshots 24–27](evidence/vendor-quotes/)). Where a pre-built machine fell short of the hard requirements (512 GB SSD, 16 GB memory, no OS), I added what was missing so the comparison is like for like:

| Role | Pre-built model | Base price | Added to meet the requirements | Total |
|---|---|---:|---|---:|
| Accountant | Lenovo ThinkCentre Neo 50s Gen 6 SFF (Core Ultra 5, 16 GB, 512 GB, no OS) | 499,990 | 1 TB SSD 85,990 + Win 11 Pro 102,990 + monitor 51,790 + keyboard/mouse 14,290 + UPS 46,990 | 802,040 |
| Sales | Lenovo ThinkCentre Neo 50s Gen 6 SFF (same) | 499,990 | +16 GB DDR5 121,500 + 1 TB SSD 85,990 + Win 11 Pro 102,990 + monitor 51,790 + keyboard/mouse 14,290 + headset 26,400 + webcam 20,890 | 923,840 |
| Developer | Lenovo ThinkCentre M70t Gen 6 (Core Ultra 7, 32 GB, 512 GB, Win 11 Pro, keyboard + mouse) | 889,990 | 1 TB SSD 85,990 + 2 monitors 103,580 | 1,079,560 |
| Designer | WW-KZ (shop's own assembly: Core i5-14400, RTX 3050 6 GB, 32 GB DDR5, 1 TB, no OS) | 731,390 | Win 11 Pro 102,990 + ProArt monitor 359,990 + keyboard/mouse 14,290 | 1,208,660 |
| | | | **Total** | **4,014,100** |

That is **1,125,180 KZT (39%) more** than building them, and **over the 3,000,000 budget** by more than a million.

**What the company gains by buying pre-built:**
- One warranty and one place to take the whole machine when something breaks. With a self-built PC, a fault has to be traced to a part before anyone will replace it.
- It is assembled and tested before it arrives. Nobody in the office has to build anything, and there is no risk of a build mistake.
- Business-line machines (ThinkCentre) are made to be managed in numbers, with the same model for years, which suits an office that will keep growing.

**What it loses:**
- **Over a million tenge**, the difference between fitting the budget and not.
- Hard requirements are not met out of the box: three of the four come with 512 GB SSDs, so a new 1 TB SSD has to be bought anyway, and the 512 GB one is wasted.
- Upgradability, which was the whole point of "last a few years". The small-form-factor Neo 50s has room only for low-profile expansion cards and a compact power supply, not a standard ATX one. The designer's pre-built uses an H610 board, the most basic Intel chipset.
- Worse fit for the roles. The pre-built "designer" machine has a weaker GPU (RTX 3050 6 GB vs RTX 5050 8 GB) and still costs more. The pre-built machines spend money on DDR5 and new CPUs, which these users will not notice, and save it on SSD size, which they will.

**Verdict:** for this office, building is right. Even one pre-built machine breaks the budget. The cheapest swap, the accountant's machine as a ThinkCentre, adds 261,640 KZT and brings the total to 3,150,560. That only makes sense if the company has nobody to assemble and maintain machines and the director accepts going over budget.

### Question 3 — Who complains about performance within a month, and about what?

**The accountant: "1C is slow."** And it will not be the computer's fault.

The 1C database lives in the main office (my assumption in section 2). If the new office opens it in the usual **file mode over the network**, 1C reads the database file in many small requests. Over an internet link between two offices, each request waits for a round trip. Opening a document journal or running a month-end report takes minutes instead of seconds, and sometimes the database gets damaged when the connection drops. To the accountant it looks exactly like a slow computer.

A faster PC changes nothing. The fix is how 1C is reached:
- **Remote Desktop** into a machine or terminal server in the main office (why the accountant's machine has Windows 11 **Pro**);
- or the **1C web client / client-server mode**.

This should be decided before the office opens, not after the first complaint.

The runner-up is the designer, if the assumption "2D only" turns out wrong. The first 4K video export on an RTX 5050 with 32 GB would be the complaint.

## 4. Evidence

| File | What it proves |
|---|---|
| [budget.csv](budget.csv) | Every part: role, component, model, price in KZT, vendor URL, date (2026-11-21). The totals in this report are computed from it. |
| [builds.md](builds.md) | The load → bottleneck → trade-off reasoning for each of the four machines. |
| [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md) | Why PCPartPicker was not used, the vendor links per build, and the hand-made compatibility check. |
| [evidence/vendor-quotes/](evidence/vendor-quotes/) | A screenshot of each product page on shop.kz taken on 21.11.2026: price, "Весь Казахстан" region, and availability. Files 01–23 are the parts in budget.csv. 08 and 12 are the comparison items I rejected (DDR5 kit, RTX 5060). 24–27 are the pre-built machines and the DDR5 stick used in question 2. The shop page itself shows no date. The date comes from when the screenshots were taken (21.11.2026, 16:39–16:55 Almaty) and from the commit that added them. |
| [evidence/vendor-quotes/delivery.png](evidence/vendor-quotes/delivery.png) | The shop's delivery page: courier delivery across Kazakhstan. This proves the "vendor that actually delivers to Kazakhstan" requirement. |

## 5. What I would do differently

1. **Get prices from a second vendor.** Every price here comes from one shop. A second source would show whether 85,990 for an SSD is a fair price or just this shop's price, and some parts (the ProArt monitor especially) might be noticeably cheaper elsewhere. With one vendor I cannot prove I got a good price, only a real one.
2. **Ask the four people, not the director.** My whole section 2 is built on guessed software lists. Ten minutes with each person would turn the biggest assumptions into facts: whether the designer touches video, and where the 1C database lives. The most expensive line in the budget depends on the first; the most likely complaint depends on the second.
3. **Get a written quote (счёт на оплату) before the price expires.** Memory and SSD prices moved even within my own search (78,990 vs 85,990 for the same SSD). A web price on 21 November is evidence, not a commitment from the vendor.
4. **Resolve the two near-misses before ordering**: the cooler height (1 mm margin) and the PSU's 8-pin GPU lead. In a real order I would ask the shop, or pick a PSU whose page says "6+2" explicitly.
