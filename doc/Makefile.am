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
