#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.57)
AC_INIT([libXCB],
        0.8,
        [xcb@pdx.freedesktop.org])
AC_CONFIG_SRCDIR([xcb.pc.in])
AM_INIT_AUTOMAKE([foreign dist-bzip2])

AM_MAINTAINER_MODE

AC_CONFIG_HEADERS([src/config.h])

AC_PROG_LIBTOOL
AC_PROG_CC
AC_CHECK_PROGS(M4, m4)

# Checks for pkg-config packages
PKG_CHECK_MODULES(XCBPROTO, xcb-proto)
PKG_CHECK_MODULES(XPROTO, xproto)
PKG_CHECK_MODULES(XAU, xau)

# Produce an XCB proto description search path
for flag in $XCBPROTO_CFLAGS; do
	case "$flag" in
	-I*)
		XCBPROTO_VPATH="$XCBPROTO_VPATH `echo "$flag" | sed 's/^-I//'`"
	;;
	esac
done
AC_SUBST(XCBPROTO_VPATH)

AC_HEADER_STDC

xcbincludedir='${includedir}/X11/XCB'
AC_SUBST(xcbincludedir)

AC_ARG_WITH(opt,
AC_HELP_STRING([--with-opt=debug], [compile for debugging (default)])
AC_HELP_STRING([--with-opt],       [compile with reasonable optimizations])
AC_HELP_STRING([--with-opt=small], [compile for smallest code]),
[ac_cv_opt=$withval], [ac_cv_opt=debug])
AC_CACHE_CHECK([whether to optimize generated code], [ac_cv_opt], [ac_cv_opt=debug])

case "$ac_cv_opt" in
yes)
	CDEBUGFLAGS="-O2"
	;;
small)
	CDEBUGFLAGS="-O2 -fomit-frame-pointer -DNDEBUG"
	;;
*)
	CDEBUGFLAGS="-g"
	;;
esac
CDEBUGFLAGS="$CDEBUGFLAGS -Wall -pedantic"
AC_SUBST(CDEBUGFLAGS)

AC_OUTPUT([Makefile src/Makefile xcb.pc])
