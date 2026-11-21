# Part lists and compatibility check

## Why there are no PCPartPicker links

PCPartPicker has no Kazakhstan region and no Kazakh retailers. A PCPartPicker list would show US or EU prices in dollars or euros, which is exactly what the ticket forbids ("prices in tenge, from a vendor that actually delivers to Kazakhstan"). So the part lists below link straight to the vendor, shop.kz (Белый Ветер), which delivers across Kazakhstan.

PCPartPicker's main value is its automatic compatibility check. I did that check by hand from the specification tabs on shop.kz. The table is at the bottom of this file.

## Build 1 — Accountant (540,400 KZT)

- CPU: https://shop.kz/offer/protsessor-amd-ryzen-5-5600gt-am4-oem/
- Motherboard: https://shop.kz/offer/materinskaya-plata-msi-a520m-pro-am4/
- Memory: https://shop.kz/offer/ddr-4-udimm-16-gb-3200-mhz-hiksemi-armor-2x-8-gb-kit-box-hsc416u32d3/
- SSD: https://shop.kz/offer/ssd-nakopitel-1-tb-kingston-nv3-m-2-pcie-4-0/
- Case: https://shop.kz/offer/korpus-deepcool-matrexx-30-black/
- PSU: https://shop.kz/offer/blok-pitaniya-atx-500-w-msi-mag-a500n-h/
- Cooler: https://shop.kz/offer/kuler-deepcool-ag400/
- Windows 11 Pro OEM: https://shop.kz/offer/microsoft-windows-11-professional-64-bit-dvd/
- Monitor: https://shop.kz/offer/monitor-23-8-xiaomi-a24i-2026-black/
- Keyboard + mouse: https://shop.kz/offer/klaviatura-logitech-mk270-black-usb-mysh/
- UPS: https://shop.kz/offer/ups-fsp-ifp-1000-iec/

## Build 2 — Sales manager (626,700 KZT)

The same as Build 1 except:
- Memory 32 GB: https://shop.kz/offer/ddr-4-dimm-32-gb-3200-mhz-amd-radeon-r9-gamer-2x-16-gb-kit-box-r9s432g3206u2k/
- Headset: https://shop.kz/offer/garnitura-jabra-evolve-20-ms-stereo-usb-usb-c-black/
- Webcam: https://shop.kz/offer/web-kamera-logitech-brio-100-graphite/
- No UPS.

## Build 3 — Web developer (564,210 KZT)

- CPU: https://shop.kz/offer/protsessor-amd-ryzen-7-5700g-am4-oem/
- Motherboard: https://shop.kz/offer/materinskaya-plata-msi-b550m-pro-vdh-am4/
- Memory 32 GB: https://shop.kz/offer/ddr-4-dimm-32-gb-3200-mhz-amd-radeon-r9-gamer-2x-16-gb-kit-box-r9s432g3206u2k/
- SSD, case, PSU, cooler, keyboard: as in Build 1.
- 2 × monitor: https://shop.kz/offer/monitor-23-8-xiaomi-a24i-2026-black/
- OS: Ubuntu 24.04 LTS, https://ubuntu.com/download/desktop

## Build 4 — Designer (1,157,610 KZT)

- CPU: https://shop.kz/offer/protsessor-amd-ryzen-7-5700x-am4-oem/
- Motherboard: https://shop.kz/offer/materinskaya-plata-msi-b550m-pro-vdh-am4/
- Memory 32 GB: https://shop.kz/offer/ddr-4-dimm-32-gb-3200-mhz-amd-radeon-r9-gamer-2x-16-gb-kit-box-r9s432g3206u2k/
- SSD: https://shop.kz/offer/ssd-nakopitel-1-tb-samsung-990-m-2-pcie-4-0/
- GPU: https://shop.kz/offer/videokarta-palit-rtx-5050-stormx-8-gb-geforse-rtx-5050/
- PSU 650 W: https://shop.kz/offer/blok-pitaniya-atx-650-w-msi-mag-a650bn/
- Monitor: https://shop.kz/offer/monitor-27-asus-proart-pa279crv-black-silver/
- Case, cooler, Windows 11 Pro, keyboard: as in Build 1.

## Compatibility check (by hand, from the vendor's specification tabs)

| Check | Values | Result |
|---|---|---|
| CPU socket ↔ board | Ryzen 5000 = AM4; A520M PRO and B550M PRO-VDH = AM4 | OK |
| Memory type ↔ board | DDR4 kits; both boards are DDR4 (A520M: 2 slots, B550M: 4 slots) | OK |
| Board ↔ case | Both boards are Micro-ATX; Matrexx 30 takes Micro-ATX / Mini-ITX | OK |
| Cooler height ↔ case | AG400 150 mm; Matrexx 30 maximum 151 mm | OK, **1 mm to spare**. A taller cooler would not fit. |
| GPU length ↔ case | Palit RTX 5050 StormX 169.9 mm; case maximum 250 mm | OK |
| Video outputs, developer's 2 monitors | Both boards: DisplayPort + HDMI + VGA; Xiaomi A24i: HDMI + DisplayPort | OK: one on DP, one on HDMI |
| Video output, designer | 5700X has no iGPU, so the board outputs are dead. The monitor goes into the RTX 5050 (3 × DP, HDMI) | OK, but the cable must go into the graphics card |
| OEM CPUs have no cooler | All three CPUs are "OEM" (tray) | That is why every build has an AG400 |
| Power, office builds | 65 W CPU + board + SSD, well under 200 W; 500 W PSU | OK |
| Power, designer | 65 W CPU + RTX 5050 (about 130 W) ≈ 250–300 W peak; 650 W PSU | Wattage OK. **Open item:** the shop lists the A650BN's GPU leads as "6-pin × 2" without saying whether they are 6+2. Confirm before ordering that the PSU has an 8-pin (6+2) lead for the card. |
| Windows OEM licence | Listed as "sold only together with a computer" | OK: it is bought together with the parts for a new PC |
