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

## Using it in a ROM build

This module is a **drop-in replacement** for the assembler `TerritoryManager`
(and the separate `TerritoryModule` territory modules) in a ROOL-style ROM
build (e.g. the BCM2835 / Raspberry Pi build). It is designed so that **you do
NOT have to change the ROM module order** — see "Why it is self-contained"
below. The changes required are:

### 1. Replace the component sources

Put this module's files in your build tree's Territory component directory,
replacing the assembler sources:

```
RiscOS/Sources/Internat/Territory/TerritoryManager/
    c/  cmhg/  h/  hdr/Territory  Makefile  VersionNum  Resources/
```

Keep the assembler `hdr/Territory` (the SWI-definitions header) — it is exported
to the rest of the build (see step 4). The old `s/` assembler sources are no
longer used.

### 2. Tell the build it is a C component (`BuildSys/ModuleDB`)

Change the `TerritoryManager` line's type from `ASM` to `C`:

```
TerritoryManager   C   Sources.Internat.Territory.TerritoryManager   Internat   TerrMgr
```

`C`-type components are linked into the ROM via the C build rules; leaving it as
`ASM` makes the `install_rom`/`rom_link` step fail to find the module image.

### 3. Leave the ROM module order ALONE

Do **not** move `SharedRISC_OSLib`, and do **not** change the default
`LanguageCMOS` (Desktop stays the 11th module). The module is built
self-contained precisely so the stock order keeps working — see below.

### 4. Nothing else to configure

The supplied `Makefile` already does the rest:

- `ASMHDRS = Territory` exports `hdr/Territory` as `Hdr:Territory`. The system C
  `swis.h` is regenerated from it; without this, `RISC_OSLib`/`CLib` fail to
  compile with `Territory_*` undeclared. (This is the equivalent of the old asm
  module's `HEADER1 = Territory`.)
- `CUSTOMROM = custom` selects the self-contained ROM link (see below).
- `VersionNum` is **0.65**, chosen to exceed *both* originals it replaces
  (asm `TerritoryManager` 0.58 and `TerritoryModule` 0.64). This matters:
  components do `RMEnsure TerritoryManager <version>` — notably the `!Boot`
  **"Time and Date" Configure plugin** — and silently fail to appear if the
  module reports a lower version. Keep the version `>=` the original you replace.

The 21 territories are built in, so the separate assembler territory data
modules (`UK`, `Germany`, … / `TerritoryModule`) are redundant; you may remove
them from the ROM component list, or leave them (the C manager carries all data
itself and does not delegate to them).

### Why it is self-contained (the important bit)

In a fixed-position ROM, a *normal* C module links against the shared C
library's `c_abssym` and calls into it during its own initialisation — so the
C library (`SharedCLibrary` / `SharedRISC_OSLib`) must be linked **and
initialised before it**. But Territory initialises very early (≈5th module),
long before the C library. Two ways out:

- ❌ **Move the C library earlier in the ROM.** This links and boots, but
  initialising the shared C library that early destabilises the running system
  (pervasive I/O errors, bogus "file too big" errors, PipeFS/TaskWindow
  failures). **Do not do this.**
- ✅ **Build the module self-contained** (what this `Makefile` does):
  `CUSTOMROM = custom` links the *static* C library (`ANSILIB = CLIB:o.ansilibm`)
  straight into the module at the fixed ROM address — a single `-rmf -base
  <ADDRESS>` link with **no** `romcstubs` and **no** `c_abssym`. The module then
  depends on neither the C library's ROM position nor the `SharedCLibrary`
  module at runtime, so it runs correctly at its stock early position and the
  ROM module order is left untouched.

### Host-toolchain note

Building the host tools (`kstrip`, `unictype`, …) needs the DDE's host C library
stubs at `<Build$HostLibs>` (`RiscOS/Library/Acorn/HostLibs/CLib/o/stubs`). On a
freshly-downloaded tree, populate them once by running `InstallTools` from
`RiscOS/Library/` (with AcornC/C++ `!SetPaths` seen). This is a general build
prerequisite, not specific to this module, but it surfaces here as
`Don't know how to make '<Build$HostLibs>.CLib.o.stubs'`.

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
