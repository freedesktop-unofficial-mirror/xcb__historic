AC_PREREQ(2.57)
AC_INIT([xcb-util],0.1,[jamey@minilop.net])
AC_CONFIG_SRCDIR([Makefile.am])
AM_INIT_AUTOMAKE([foreign dist-bzip2])

AC_PROG_CC
AC_PROG_LIBTOOL

xcbincludedir='${includedir}/X11/XCB'
AC_SUBST(xcbincludedir)

PKG_CHECK_MODULES(XCB, xcb)

AC_OUTPUT([Makefile image/Makefile])
