# SPDX-License-Identifier: GPL-3.0-or-later
#
# Makefile for the C rewrite of the RISC OS Territory system (manager + the
# built-in territory data, consolidated into one C module).
# Copyright (C) 2026 Martin Eastwood and contributors.  GPLv3 (see LICENSE).
#
# Built as a parallel component (does not disturb the asm Territory* modules).

COMPONENT          = TerritoryManager
TARGET             = TerrMgr
CMHGFILE           = TerritoryHdr
CMHGFILE_SWIPREFIX = Territory
CINCLUDES          = ${RINC}

# Self-contained ROM build: the Territory manager initialises very early in ROM
# (5th module), long before the SharedCLibrary module.  A normal C ROM module
# links against the shared C library (romcstubs + RISC_OSLib:o.c_abssym) and
# calls into it during its own init - impossible that early, and it would force
# the C library to be ROM-linked first (reordering the ROM destabilises the
# system).  Instead we link the *static* C library (ansilibm) straight into the
# module, so it needs neither c_abssym at link time nor the SharedCLibrary
# module at runtime, and the stock ROM module order is left untouched.
# CUSTOMROM=custom swaps in the self-contained rom / rom_link rules below.
CUSTOMROM          = custom

# Manager logic objects:
LOGIC_OBJS = module registry swi dispatch tables datetime daylight collate territories errors property
# Of those, the ones that #include the CMHG-generated h.TerritoryHdr:
HDR_OBJS   = module registry swi dispatch tables datetime daylight collate territories

# Territory data objects (these include only h.territory):
TERR_OBJS  = uk usa ireland canada1 france germany italy spain portugal \
             netherlands denmark norway sweden finland iceland \
             australia safrica turkey japan korea taiwan

OBJS        = ${LOGIC_OBJS} ${TERR_OBJS}
CMHGDEPENDS = ${HDR_OBJS}
HDRS        =
# Export the assembler SWI-definitions header (hdr/Territory -> Hdr:Territory).
# The system C swis.h is generated from this; without it RISC_OSLib/CLib fail to
# compile (Territory_* SWIs undeclared).  The old asm module did this via HEADER1.
ASMHDRS     = Territory

include CModule

# --- self-contained ROM rules (selected by CUSTOMROM=custom above) -----------
# rom_custom just builds the objects in the 'rom' phase (as the default would);
# rom_link_custom does a single fixed-position link of the objects + the static
# C library (ANSILIB = CLIB:o.ansilibm) at ${ADDRESS}.  This mirrors the proven
# standalone (-rmf) link but at a fixed ROM base and with no romcstubs/c_abssym,
# so nothing references the shared C library.
rom_custom: ${ROM_OBJS_} ${DIRS}
	@${ECHO} ${COMPONENT}: rom objects built (self-contained C library)

rom_link_custom: ${ROM_OBJS_} ${DIRS} ${FORCEROMLINK}
	${LD} ${LDFLAGS} ${LDLINKFLAGS} -o linked.${LNK_TARGET} -rmf -base ${ADDRESS} ${ROM_OBJS_} ${ANSILIB} ${LIBS} -Symbols linked.${LNK_TARGET}_sym
	${CP} linked.${LNK_TARGET} ${LINKDIR}.${TARGET} ${CPFLAGS}
	${CP} linked.${LNK_TARGET}_sym ${LINKDIR}.${TARGET}_sym ${CPFLAGS}
	@${ECHO} ${COMPONENT}: rom_link complete (self-contained C library)

# --- dependencies ---
# Manager logic depends on the generated CMHG header and the contract header.
o.module:	c.module	h.territory	h.TerritoryHdr	C:h.swis	C:h.kernel
o.registry:	c.registry	h.territory	h.TerritoryHdr	C:h.kernel
o.swi:		c.swi		h.territory	h.TerritoryHdr	C:h.kernel
o.tables:	c.tables	h.territory	h.TerritoryHdr	C:h.kernel
o.datetime:	c.datetime	h.territory	h.TerritoryHdr	C:h.kernel	C:h.swis
o.daylight:	c.daylight	h.territory	h.TerritoryHdr	C:h.kernel	C:h.swis
o.collate:	c.collate	h.territory	h.TerritoryHdr	C:h.kernel
o.dispatch:	c.dispatch	h.territory	h.TerritoryHdr	C:h.kernel
o.errors:	c.errors	C:h.kernel
o.property:	c.property
o.territories:	c.territories	h.territory	h.TerritoryHdr
# Each territory data file depends only on the contract header.
o.uk:		h.territory
o.usa:		h.territory
o.ireland:	h.territory
o.canada1:	h.territory
o.france:	h.territory
o.germany:	h.territory
o.italy:	h.territory
o.spain:	h.territory
o.portugal:	h.territory
o.netherlands:	h.territory
o.denmark:	h.territory
o.norway:	h.territory
o.sweden:	h.territory
o.finland:	h.territory
o.iceland:	h.territory
o.australia:	h.territory
o.safrica:	h.territory
o.turkey:	h.territory
o.japan:	h.territory
o.korea:	h.territory
o.taiwan:	h.territory
h.TerritoryHdr:	cmhg.TerritoryHdr	VersionNum
o.TerritoryHdr:	cmhg.TerritoryHdr	VersionNum

# Dynamic dependencies:
o.module:	c.module
o.module:	C:h.swis
o.module:	C:h.kernel
o.module:	h.territory
o.module:	C:h.kernel
o.module:	h.TerritoryHdr
o.registry:	c.registry
o.registry:	h.territory
o.registry:	C:h.kernel
o.registry:	h.TerritoryHdr
o.swi:	c.swi
o.swi:	C:h.swis
o.swi:	C:h.kernel
o.swi:	h.territory
o.swi:	C:h.kernel
o.swi:	h.TerritoryHdr
o.dispatch:	c.dispatch
o.dispatch:	h.territory
o.dispatch:	C:h.kernel
o.dispatch:	h.TerritoryHdr
o.tables:	c.tables
o.tables:	C:h.kernel
o.tables:	h.territory
o.tables:	C:h.kernel
o.tables:	h.TerritoryHdr
o.datetime:	c.datetime
o.datetime:	C:h.swis
o.datetime:	C:h.kernel
o.datetime:	C:h.kernel
o.datetime:	h.territory
o.datetime:	C:h.kernel
o.datetime:	h.TerritoryHdr
o.daylight:	c.daylight
o.daylight:	C:h.swis
o.daylight:	C:h.kernel
o.daylight:	C:h.kernel
o.daylight:	h.territory
o.daylight:	C:h.kernel
o.daylight:	h.TerritoryHdr
o.collate:	c.collate
o.collate:	C:h.kernel
o.collate:	h.territory
o.collate:	C:h.kernel
o.collate:	h.TerritoryHdr
o.territories:	c.territories
o.territories:	h.territory
o.territories:	C:h.kernel
o.territories:	h.TerritoryHdr
h.TerritoryHdr:	cmhg.TerritoryHdr
h.TerritoryHdr:	VersionNum
o.errors:	c.errors
o.errors:	C:h.kernel
o.property:	c.property
o.uk:	c.uk
o.uk:	h.territory
o.uk:	C:h.kernel
o.usa:	c.usa
o.usa:	h.territory
o.usa:	C:h.kernel
o.ireland:	c.ireland
o.ireland:	h.territory
o.ireland:	C:h.kernel
o.canada1:	c.canada1
o.canada1:	h.territory
o.canada1:	C:h.kernel
o.france:	c.france
o.france:	h.territory
o.france:	C:h.kernel
o.germany:	c.germany
o.germany:	h.territory
o.germany:	C:h.kernel
o.italy:	c.italy
o.italy:	h.territory
o.italy:	C:h.kernel
o.spain:	c.spain
o.spain:	h.territory
o.spain:	C:h.kernel
o.portugal:	c.portugal
o.portugal:	h.territory
o.portugal:	C:h.kernel
o.netherlands:	c.netherlands
o.netherlands:	h.territory
o.netherlands:	C:h.kernel
o.denmark:	c.denmark
o.denmark:	h.territory
o.denmark:	C:h.kernel
o.norway:	c.norway
o.norway:	h.territory
o.norway:	C:h.kernel
o.sweden:	c.sweden
o.sweden:	h.territory
o.sweden:	C:h.kernel
o.finland:	c.finland
o.finland:	h.territory
o.finland:	C:h.kernel
o.iceland:	c.iceland
o.iceland:	h.territory
o.iceland:	C:h.kernel
o.australia:	c.australia
o.australia:	h.territory
o.australia:	C:h.kernel
o.safrica:	c.safrica
o.safrica:	h.territory
o.safrica:	C:h.kernel
o.turkey:	c.turkey
o.turkey:	h.territory
o.turkey:	C:h.kernel
o.japan:	c.japan
o.japan:	h.territory
o.japan:	C:h.kernel
o.korea:	c.korea
o.korea:	h.territory
o.korea:	C:h.kernel
o.taiwan:	c.taiwan
o.taiwan:	h.territory
o.taiwan:	C:h.kernel
o.TerritoryHdr:	cmhg.TerritoryHdr
o.TerritoryHdr:	VersionNum
