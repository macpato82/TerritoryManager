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
