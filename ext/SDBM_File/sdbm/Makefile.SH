: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.

case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

if test -f config.sh; then TOP=.;
elif test -f ../config.sh; then TOP=..;
elif test -f ../../config.sh; then TOP=../..;
elif test -f ../../../config.sh; then TOP=../../..;
elif test -f ../../../../config.sh; then TOP=../../../..;
else
	echo "Can't find config.sh."; exit 1
fi

: Find absolute path name for TOP.  This is needed when we cd to TOP
: to run perl on autosplit.
oldpwd=`pwd`; cd $TOP; ABSTOP=`pwd`; cd $oldpwd

case $CONFIG in
'')
	. $TOP/config.sh
	;;
esac

echo "Extracting ext/SDBM_File/sdbm/Makefile (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >Makefile <<!GROK!THIS!
#
# This Makefile is for the library part of sdbm.  For the
# Full package, see makefile.sdbm.
# 
# Makefile for public domain ndbm-clone: sdbm
# DUFF: use duff's device (loop unroll) in parts of the code
#
#
CC = $cc
RANLIB = $ranlib
TOP = $TOP
ABSTOP = $ABSTOP
LDFLAGS = $ldflags
CLDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split

# To use an alternate make, set \$altmake in config.sh.
MAKE = ${altmake-make}

# The following are used to build and install shared libraries for
# dynamic loading.
LDDLFLAGS = $lddlflags
CCDLFLAGS = $ccdlflags
CCCDLFLAGS = $cccdlflags

!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>Makefile <<'!NO!SUBS!'
SHELL = /bin/sh
CCCMD = `sh $(shellflags) $(TOP)/cflags $@`

.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(TOP) -DSDBM -DDUFF $*.c

LIBOBJS = sdbm.o pair.o hash.o
LIBSRCS = sdbm.c pair.c hash.c
HDRS = tune.h sdbm.h pair.h $(TOP)/config.h

all:	libsdbm.a

libsdbm.a: $(LIBOBJS)
	ar cr libsdbm.a $(LIBOBJS)
	$(RANLIB) libsdbm.a

$(LIBOBJS): $(HDRS)

lint:
	lint -abchx $(LIBSRCS)

clean:
	rm -f *.o *.a mon.out core

realclean: 	clean
	rm -f dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag
	rm -f makefile Makefile

purge:	realclean

sdbm.o : sdbm.c $(TOP)/config.h sdbm.h tune.h pair.h 
hash.o : hash.c $(TOP)/config.h sdbm.h 
pair.o : pair.c $(TOP)/config.h sdbm.h tune.h pair.h 

!NO!SUBS!
chmod 755 Makefile
$eunicefix Makefile
