# Lab 5 — Encoding forensics

Pair: Yermukhan / Imanbayeva  Driver first half: Yermukhan
Machine: MACHCREATOR L16A laptop (AMD Ryzen 7 7735HS, 16 GB RAM, Windows 11 Pro) — host, Excel + LibreOffice Calc + PowerShell;
Ubuntu Server 26.04.1 LTS guest in VirtualBox on the same laptop — `file`, `xxd`, `iconv`, `cat`
Date: 21.11.2026

## What I received

`staff-broken.csv` from the Lab 5 assignment in Canvas, 852 bytes, a staff list of 15 people with Russian
and Kazakh names. I copied it to `evidence/staff-broken.csv` and never edited that copy.

| Where | How it looked (nothing saved) |
|---|---|
| Excel (double-click) | Read in the Windows ANSI code page (Windows-1251): Russian names correct, every Kazakh letter replaced by a 1251 one — `Јбдірахманова`, `Ќасымов;Нўрлан`, `Ерєали`, `Ґмірзаќова;Гїлнўр`, `Ґскемен`. All in column A (list separator on this en-US Windows is `,`) |
| LibreOffice Calc | Split into columns on `;`, but with the same Windows-1251 default: `Јбдірахманова`, `Нўрлан`, `Їміт`, `Шјріпова`, `Ґскемен` |
| `cat` in Ubuntu | `ID;�������;���;�����;…`, `103;�������;͢����;…` — the terminal is UTF-8, single bytes `C0–FF` are not valid UTF-8 and become `�` |

Screenshot of Excel and LibreOffice: [`evidence/opens-before.png`](evidence/opens-before.png).
The two Windows programs fail *the same way* (as 1251), the terminal fails differently (invalid UTF-8) — so the
file is a single-byte Cyrillic code page that is almost, but not exactly, Windows-1251.

## What I did

### 1. Diagnosis — before changing anything

In the Ubuntu guest, from `labs/lab05-encoding`:

```bash
{ echo '$ file evidence/staff-broken.csv'; file evidence/staff-broken.csv; } > evidence/file-before.txt
{ echo '$ xxd evidence/staff-broken.csv | head -n 8'; xxd evidence/staff-broken.csv | head -n 8; } > evidence/hexdump-before.txt
iconv -f WINDOWS-1251 -t UTF-8 evidence/staff-broken.csv | head -n 5
iconv -f RK1048       -t UTF-8 evidence/staff-broken.csv | head -n 5
```

First 16 bytes:

```
49 44 3b d4 e0 ec e8 eb e8 ff 3b c8 ec ff 3b ce   ID;Фамилия;Имя;О
```

| Question | Answer | Proof (bytes) |
|---|---|---|
| `file` says | `Non-ISO extended-ASCII text, with CRLF line terminators` | `evidence/file-before.txt` — "extended-ASCII" = one byte per character, a legacy code page; `file` cannot say which one |
| BOM | **No BOM** | the file starts with `49 44` = `ID`, not `EF BB BF` / `FF FE` |
| Bytes per letter | **one byte** → a legacy code page, not UTF-8/UTF-16 | `Ф` = `D4`, `а` = `E0`, `я` = `FF`: single bytes in `C0–FF`, no `D0 xx` pairs, no `xx 04` pairs |
| Which code page | **KZ-1048** (STRK1048-2002, iconv name `RK1048`), the Kazakh variant of Windows-1251 | Russian letters match Windows-1251 (`И` = `C8`, `я` = `FF`), but Kazakh letters sit on positions that Windows-1251 uses for other characters: `Ә` = `A3` (1251: `Ј`), `Қ` = `8D` (1251: `Ќ`), `ұ` = `A2` (1251: `ў`), `ғ` = `BA` (1251: `є`), `Ө` = `A5` (1251: `Ґ`), `ү` = `BF` (1251: `ї`) |
| Line ending | **CRLF** (Windows) | every line ends with `0D 0A`, e.g. end of line 1: `…E4 0D 0A 31 30 31` (`…д`, CR, LF, `101`); 16 lines, 16 × `0D 0A`, no bare `0A` |
| Separator | `;` | `49 44 3B` = `ID;` |

**Diagnosis: KZ-1048, CRLF line endings, no BOM, `;` separator.**

The two `iconv` test lines show it: with `WINDOWS-1251` the Russian names are correct but
`101;Јбдірахманова`, `103;Ќасымов;Нўрлан`, `106;Жўмабаев;Ерєали`; with `RK1048` every name reads correctly —
`Әбдірахманова`, `Қасымов`, `Нұрлан`, `Жұмабаев`, `Ерғали`.
This is also why each program showed it differently: Excel and LibreOffice guess a Cyrillic ANSI code page
(Windows-1251), which gets the Russian letters right and the Kazakh ones wrong; the UTF-8 terminal rejects
every non-ASCII byte and shows `�`.

### 2. Decisions for the fixed file

- **Encoding: UTF-8.** It has every Kazakh and Russian letter and is what Linux, LibreOffice and GitHub expect.
- **BOM: added (`EF BB BF`).** The brief says the file must open correctly *everywhere*, including Excel by
  double-click. Without a BOM, Excel on Windows reads a CSV in the ANSI code page (1251) and the UTF-8 names
  turn into `Ð¤Ð°Ð¼…`. LibreOffice and `cat` handle the BOM without problems. Price: a script that reads the
  first header naively will see `﻿ID` instead of `ID`.
- **Line ending: LF.** CRLF leaves `\r` at the end of the last field (`Алматы\r`), which breaks comparisons and
  loops in shell scripts. Excel and LibreOffice read LF files correctly.

### 3. Conversion — `scripts/fix.sh` (Ubuntu guest)

```sh
iconv -f RK1048 -t UTF-8 evidence/staff-broken.csv > evidence/staff-fixed.csv   # encoding
sed -i 's/\r$//' evidence/staff-fixed.csv                                        # CRLF -> LF
printf '\357\273\277' | cat - evidence/staff-fixed.csv > tmp && mv tmp evidence/staff-fixed.csv  # BOM
```

Run: `sh scripts/fix.sh`.

On Windows there is `scripts/fix.ps1`. .NET has no KZ-1048 decoder, so the script decodes as Windows-1251 and
overrides the 18 byte values where KZ-1048 differs (`8C–8E`, `9C–9E`, `A1–A3`, `A5`, `AA`, `AF`, `B2–B4`, `BA`,
`BC`, `BF`). Both scripts give a byte-identical file:

```
sha256 staff-fixed.csv = ef47c56b3395fe37ad713dd412e68f2acc2f5c1a20ad0157232e1128e7f135da  (1509 bytes)
```

## Result

```bash
{ echo '$ file evidence/staff-fixed.csv'; file evidence/staff-fixed.csv; echo; echo '$ xxd evidence/staff-fixed.csv | head -n 4'; xxd evidence/staff-fixed.csv | head -n 4; } > evidence/file-after.txt
sha256sum evidence/staff-fixed.csv
cat evidence/staff-fixed.csv
```

- `file`: `Unicode text, UTF-8 (with BOM) text` — no "CRLF" any more; `grep -c $'\r'` → `0`.
- `sha256sum` in the guest after `sh scripts/fix.sh`: `ef47c56b…f135da` — the same as `fix.ps1` on Windows.
- Starts with `ef bb bf 49 44 3b d0 a4 d0 b0` = BOM, `ID;`, `Фа` — Cyrillic is now `D0 xx` / `D1 xx` pairs;
  Kazakh `Ә` = `D3 98`, `Қ` = `D2 9A`.
- File grew from 852 to 1509 bytes: 3 bytes BOM + every Cyrillic letter 1 → 2 bytes − 16 removed CRs.
- Opened in LibreOffice Calc (Character set UTF-8, separator `;`), Excel (double-click) and `cat` in the Ubuntu
  guest: all 15 names correct, including `Әбдірахманова`, `Қасымов`, `Өмірзақова`, `Шәріпова`, and the cities
  `Қарағанды`, `Өскемен` — [`evidence/opens-correctly.png`](evidence/opens-correctly.png).
- In Excel every line sits in column A (`101;Әбдірахманова;Аружан;…`). That is the separator, not the encoding:
  this Windows is en-US, its list separator is `,`, and Excel splits a double-clicked CSV on that. The letters are
  right, which is what the BOM is for.

## What did not work the first time

- The Russian letters match the Windows-1251 table (`А` = `C0`, `я` = `FF`), and `iconv -f WINDOWS-1251` runs
  without any error — but the Kazakh names come out as `Јбдірахманова`, `Ќасымов`, `Нўрлан`. No error does not
  mean the right encoding: every byte is valid in 1251, it is just a different letter there. The bytes of `Ә`
  (`A3`) and `Қ` (`8D`) point to the Kazakh code page, KZ-1048.
- `iconv -f KZ-1048` → ``iconv: conversion from `KZ-1048' is not supported``; `iconv -l | grep -i 1048` showed
  that glibc knows it as `RK1048` and `STRK1048-2002`.
- Piping a script from Windows PowerShell 5.1 into `ssh … bash` failed with ``﻿cd: command not found`` —
  PowerShell prepended a UTF-8 BOM to the text, so bash saw `EF BB BF cd`. The same BOM issue this lab is about.
  Fixed by writing the script to a file as UTF-8 *without* BOM and copying it with `scp`.
- Excel itself broke during the lab: every start ended in "Excel has run into an error… repair now?", even
  `excel /safe`. Office Quick Repair finished but did not help; Online Repair (full reinstall of Microsoft 365,
  ~10 min) did. After it Excel opens again, with an "Office product is inactive" banner until I sign in.
- On an en-US Windows the list separator is `,`, so Excel by double-click puts each line of this `;`-file into
  column A — letters correct, no columns (`evidence/excel-doubleclick.png`). Data → Text to Columns with `;`
  would split it, but it was disabled while Office was not activated.

## Evidence

- [evidence/staff-broken.csv](evidence/staff-broken.csv) — the original from Canvas, unchanged
- [evidence/file-before.txt](evidence/file-before.txt) — `file` before the fix, command above the output
- [evidence/hexdump-before.txt](evidence/hexdump-before.txt) — first 8 lines of `xxd`: no BOM, one byte per letter, `0D 0A`
- [evidence/staff-fixed.csv](evidence/staff-fixed.csv) — UTF-8 with BOM, LF
- [evidence/file-after.txt](evidence/file-after.txt) — `file` and `xxd` after: UTF-8, BOM, `D0 xx` pairs
- [evidence/opens-correctly.png](evidence/opens-correctly.png) — Excel, LibreOffice Calc and `cat` side by side
- [evidence/opens-before.png](evidence/opens-before.png) — the original in Excel and LibreOffice: Kazakh letters wrong in both
- [evidence/excel-doubleclick.png](evidence/excel-doubleclick.png) — fixed file by double-click in Excel: letters correct thanks to the BOM
- [scripts/fix.sh](scripts/fix.sh) — the fix (iconv); [scripts/fix.ps1](scripts/fix.ps1) — same result on Windows
- [scripts/screenshots.ps1](scripts/screenshots.ps1) — opens the file in the three applications and takes the screenshot
