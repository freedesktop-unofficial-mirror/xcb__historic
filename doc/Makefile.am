## Process this file with automake to produce Makefile.in

## Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
## All Rights Reserved.  See the file COPYING in this directory
## for licensing information.

SUFFIXES = .tex .dvi .ps .pdf

pkgdata_DATA = xcb_proto_macros.ps xcb_proto_macros.pdf
EXTRA_DIST = xcb_proto_macros.tex
CLEANFILES = $(pkgdata_DATA)

LATEX = latex
.tex.dvi:
	$(LATEX) -interaction=batchmode $<
	-rm -f xcb_proto_macros.aux xcb_proto_macros.log

DVIPS = dvips
.dvi.ps:
	$(DVIPS) -o -q $<

PS2PDF = ps2pdf
.ps.pdf:
	$(PS2PDF) $<
