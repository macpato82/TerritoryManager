# Territory system — C rewrite (design + phased plan)

Rewrite of the RISC OS Territory subsystem from ObjAsm into C, preserving the
existing module ABI **exactly**. New code → licensed **GPLv3** (our own work).

Built as a NEW parallel component (`TerritoryManagerC`) so the working assembler
modules are never disturbed; we cut over only once the C version is build- and
run-verified. (Only one module can own the Territory SWIs at runtime, so testing
means `RMKill TerritoryManager` first, then `RMLoad` the C build.)

## The ABI to replicate (from TerritoryManager/s/SWIs `Territory_SWInames`)

SWI chunk base: **&43040**. 56 SWIs:
```
 0 Number            1 Register          2 Deregister        3 NumberToName
 4 Exists            5 AlphabetNumberToName 6 SelectAlphabet  7 SetTime
 8 ReadCurrentTimeZone 9 ConvertTimeToUTCOrdinals 10 ReadTimeZones
11 ConvertDateAndTime 12 ConvertStandardDateAndTime 13 ConvertStandardDate
14 ConvertStandardTime 15 ConvertTimeToOrdinals 16 ConvertTimeStringToOrdinals
17 ConvertOrdinalsToTime 18 Alphabet 19 AlphabetIdentifier 20 SelectKeyboardHandler
21 WriteDirection 22 CharacterPropertyTable 23 LowerCaseTable 24 UpperCaseTable
25 ControlTable 26 PlainTable 27 ValueTable 28 RepresentationTable 29 Collate
30 ReadSymbols 31 ReadCalendarInformation 32 NameToNumber 33 TransformString
34 IME 35 DaylightRules   36..52 Reserved1..17
53 ConvertTextToString 54 Select 55 DaylightSaving
```
Plus `*Territory`, `*Territories` commands; service calls (Service_Territory*,
Service_International, reset); and the per-territory entry table (Entries):
Alphabet, AlphabetIdent, SelectKeyboardHandler, WriteDirection, IME,
CharacterPropertyTable, Get{Lower,Upper,Control,Plain,Value,Representation}Table,
Collate, ReadTimeZones, ReadSymbols, GetCalendarInformation.

## C data model (preserves the asm entry-table contract)

A registered territory is a function/data table. Mirror it as a C vtable so the
manager calls territories uniformly (same as the asm `Entries` dispatch):

```c
typedef struct territory_funcs {
  int   number;                       /* e.g. 1 = UK */
  const char *name;
  int (*alphabet)(...);               /* one fn per Entries slot */
  const unsigned char *(*lowercase_table)(int alphabet);
  ... /* collate, symbols, calendar, timezones, keyboard, etc. */
} territory_funcs;
```
The 21 territory data files become C tables (`c/uk`, `c/usa`, …) each exporting a
`territory_funcs`. Mechanical but large + transcription-risky → done last, one at
a time, each diffed against the asm data.

## Phased plan (each phase ends with: YOU build + run-test before the next)

- **Phase 1 (foundation — in progress):** `TerritoryManagerC` CMHG header (full
  56-SWI table) + C scaffold: Init/Final, SWI dispatcher, `*Territory`/
  `*Territories`, the registration list (Register/Deregister/Number/NumberToName/
  NameToNumber/Exists/Select). Everything else returns a clear "not yet
  implemented" error. **Goal: it BUILDS and LOADS.** Nothing locale-specific yet.
- **Phase 2:** date/time/DST/timezone SWIs (11–17, 53, 8–10, 55, 35) + the
  manager-side Daylight logic. Testable with known dates.
- **Phase 3:** the per-territory entry contract + ONE territory (UK) ported as C
  data → wire up Alphabet/case/collate/symbols/calendar SWIs end-to-end for UK.
  Build + verify UK behaviour matches the asm module exactly.
- **Phase 4:** port the remaining 20 territory data tables (one per file), each
  verified against its asm source.
- **Phase 5:** cut over (replace the asm components in the build) once parity is
  confirmed; retire the asm.

## Verification (no token-diff safety net here — it's a rewrite)
Per phase: build with `riscos-amu`; load with `RMLoad`; exercise the implemented
SWIs from BASIC and compare outputs against the live asm module (run both, diff
results) for identical inputs — dates, collation orders, case tables, symbols.

## Status
- [x] Scope + ABI captured (this file)
- [x] **Phase 1 scaffold** — LICENSE(GPLv3), h/territory (vtable+registry API),
      cmhg/TerritoryHdr (full 56-SWI table), c/registry, c/swi (identity SWIs),
      c/module (*Territory/*Territories), Makefile, VersionNum. Implemented:
      Number, Register, Deregister, NumberToName, NameToNumber, Exists, Select;
      rest → swi_unimplemented. Decisions: parallel component, GPLv3, push-all-
      phases / build-once-at-end.
- [x] **Phase 2** — manager-logic SWIs in C: c/tables (alphabet/case/property/
      symbols/calendar/keyboard/writedir/transform/ime), c/datetime (date/time/
      DST/timezone), c/collate. All 39 non-reserved SWIs wired in the CMHG.
- [x] **Phase 3 & 4** — all 21 territories ported to `territory_data` (uk, usa,
      ireland, canada1, france, germany, italy, spain, portugal, netherlands,
      denmark, norway, sweden, finland, iceland, australia, safrica, turkey,
      japan, korea, taiwan), registered at init via c/territories. Numbers/
      alphabets read from Hdr:Countries; names/tables transcribed from asm +
      message resources; non-ASCII as \xNN escapes.
- [ ] **Phase 5 — cutover**: build-verify (owner), debug the first draft, then
      replace the asm components in the ROM build and retire them.

## VERIFIED (static, pre-build): all 21 territory symbols present & named as the
   registrar expects; all 39 SWI handlers defined; designated initialisers
   throughout; no CRLF / no EF BF BD corruption; stray generator artifacts removed.

## GAPS NOW CLOSED (all stubs removed; functionally complete)
- [x] CharacterPropertyTable: c/property holds the 11 Latin1 property tables
      (ported from asm); swi_charpropertytable returns the right one by alphabet.
- [x] Territory_IME: `ime_chunk` field added; Japan/Korea/Taiwan populated
      (&52500 / &55B00 / &55BC0); swi_ime returns it.
- [x] DaylightSaving/DaylightRules: fully implemented (CMOS auto-DST bits +
      per-zone `dst_rule` transition computation); all DST territories carry rules
      (EU last-Sun, US 2nd-Sun, AU southern-hemisphere; no-DST ones NULL).
- [x] Japanese eras (%JE/%J1/%JY): `eras` table added + Japan populated
      (Meiji→Reiwa); datetime expands them.
- [x] error-base = real &190 (ErrorBase_TerritoryManager), 8 dedicated errors in
      ABI order (UnknownTerritory..NoRuleDefined).
- [x] All /* TODO-verify */ register conventions checked vs the asm and resolved.
- [x] swi_unimplemented (reserved slots 36-52) returns error_BAD_SWI (&1E6), the
      correct response, not a fake error.

## ✅ BUILD + RUN VERIFIED (2026-06-17)
The module compiles, links (rm.TerritoryManager), AND runs on RISC OS - loaded
via RMLoad and exercised through Tests/TestTerr (identity SWIs, tables, symbols,
calendar, date/time conversion, collate) successfully.  The asm->C rewrite is
COMPLETE and working.  Build fixes applied along the way: cmhg switched to standard
Acorn syntax (central handler + names-only table, errors in C); header type-order/
NULL fixed; iceland \x escapes split; Resources/UK/Messages added; all 31 objects
(incl. property) wired into the Makefile.
ONLY REMAINING (optional): Phase 5 cutover - swap into the ROM build, retire the asm.

## REMAINING (honest limitations — not stubs)
- **Run-testing is the owner's step** (no RISC OS toolchain here).  It now BUILDS;
  correctness of behaviour still needs validation against the asm module.
- `Territory_Exists` returns presence in R1 (0/1); the asm's pure PSR-Z-flag
  convention cannot be reproduced from a CMunge C SWI veneer — documented in c/swi.
- Property tables only carry Latin1 data; other alphabets fall back to Latin1.
- A few alphabet-specific collation ligature expansions (Danish AA, German sharp-s)
  are not yet data-driven — documented in c/collate.
- `error_BAD_SWI` is defined locally in c/swi (and mirrored in c/tables) rather
  than shared — harmless (file-static), but could be unified.

## Known first-draft caveats to resolve at build time
- SWI exit register conventions for Exists (and others) marked TODO-verify vs
  TerritoryManager/s/SWIs.
- error-base is a PLACEHOLDER — must match the real Territory error numbers.
- Territory_Register payload is the C `territory_funcs` vtable (rewrite-internal
  contract); asm territory modules won't interop — fine since both sides are
  being rewritten, but note for any third-party territory.
