AC_PREREQ(2.57)
AC_INIT([xcb-util],0.1,[jamey@minilop.net])
AC_CONFIG_SRCDIR([Makefile.am])
AM_INIT_AUTOMAKE([foreign dist-bzip2])

AC_CHECK_PROGS(M4, m4)
AC_CHECK_PROGS(GPERF, gperf)
AC_PROG_CC
AC_PROG_LIBTOOL

xcbincludedir='${includedir}/X11/XCB'
AC_SUBST(xcbincludedir)

pkgconfigdir='${libdir}/pkgconfig'
AC_SUBST(pkgconfigdir)

PKG_CHECK_MODULES(XCB, xcb)

AC_OUTPUT([Makefile
	image/Makefile image/xcb-image.pc
	atom/Makefile atom/xcb-atom.pc
	event/Makefile event/xcb-event.pc
	property/Makefile property/xcb-property.pc
	icccm/Makefile icccm/xcb-icccm.pc
	wm/Makefile wm/xcb-wm.pc
	])
