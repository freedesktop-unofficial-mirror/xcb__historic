dnl Process this file with autoconf to produce a configure script.

dnl Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
dnl All Rights Reserved.  See the file COPYING in this directory
dnl for licensing information.

AC_INIT(xcb_conn.m4)
AM_INIT_AUTOMAKE([xcb], [0.1])

AM_PROG_LIBTOOL
AC_CHECK_PROGS(M4, m4)

AC_CHECK_HEADERS(X11/X.h X11/Xproto.h pthread.h)
AC_CHECK_FUNCS(pthread_mutex_lock)

AC_OUTPUT([Makefile client/Makefile test/Makefile doc/Makefile])
