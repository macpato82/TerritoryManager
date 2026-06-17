# TerritoryManager (C rewrite)

A reimplementation, in C, of the RISC OS **Territory** subsystem — the
`TerritoryManager` (SWI/API layer) and `TerritoryModule` (21 built-in
territories) — consolidated into a single relocatable module.

**Status:** builds with the RISC OS DDE and runs (loaded with `*RMLoad`, the
Territory SWIs and `*Territories`/`*Territory` commands exercised on RISC OS 5).

## What it provides

- The full **Territory SWI ABI** (chunk base `&43040`, 56 SWIs): `Number`,
  `Register`, `NumberToName`, `NameToNumber`, `Exists`, `Select`, the alphabet/
  case/property/collation table SWIs, `ReadSymbols`, `ReadCalendarInformation`,
  the date/time conversion family, `DaylightSaving`/`DaylightRules`, `IME`, …
- The `*Territory` and `*Territories` commands.
- **21 built-in territories** (UK, USA, Ireland, Canada1, France, Germany,
  Italy, Spain, Portugal, Netherlands, Denmark, Norway, Sweden, Finland,
  Iceland, Australia, South Africa, Turkey, Japan, Korea, Taiwan), each as a
  `territory_data` table: alphabet, case/collation tables, locale symbols,
  calendar, time zones + DST rules, and (Japan) calendar eras.

## Layout

```
cmhg/TerritoryHdr     CMHG module header (identity, SWI table, commands)
h/territory           the frozen data contract (territory_data + registry API)
c/                    module/registry/dispatch/swi + tables/datetime/collate
                      + property + errors + territories (registrar) + 21 data files
Resources/UK/Messages resource stub
Makefile, VersionNum  DDE (CModule) build
MkRom / MkSA / MkClean  Obey build files
Tests/TestTerr        BASIC smoke test
DESIGN.md             design notes, phased plan, status, known limitations
```

## Building (RISC OS DDE)

```
*Dir <this directory>
Run MkSA          | build a stand-alone RAM module: rm.TerritoryManager
                  | (MkRom builds the ROM/AOF version; MkClean cleans)
```

## Testing

```
*RMKill TerritoryManager        | unload the assembler module first (SWI clash)
*RMLoad rm.TerritoryManager
*BASIC -quit Tests.TestTerr
```

## Licence

GPLv3 (see `LICENSE`).  This is a **derivative work** of the Apache-2.0 RISC OS
Territory module (© Acorn / Pace / Castle / RISC OS Open) — see `NOTICE` for the
required attribution.

## Known limitations

See `DESIGN.md`. In brief: `Territory_Exists` reports presence in R1 rather than
the PSR Z flag (a CMHG C-veneer constraint); property tables carry Latin1 data
with a fallback for other alphabets; a few alphabet-specific collation ligature
rules are not yet data-driven. Behaviour should be validated against the original
module before any production use.
