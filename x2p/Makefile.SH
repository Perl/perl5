case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

: Configure sets byacc=byacc if byacc is not found.  We reset it to ''
case "$byacc" in
'byacc') byacc='';;
esac

echo "Extracting x2p/Makefile (with variable substitutions)"
rm -f Makefile
cat >Makefile <<!GROK!THIS!
# $RCSfile: Makefile.SH,v $$Revision: 4.1 $$Date: 92/08/07 18:29:07 $
#
# $Log:	Makefile.SH,v $

CC = $cc
BYACC = $byacc
mansrc = $mansrc
manext = $manext
LDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split
mallocsrc = $mallocsrc
mallocobj = $mallocobj
shellflags = $shellflags

libs = $libs
!GROK!THIS!

cat >>Makefile <<'!NO!SUBS!'

CCCMD = `sh $(shellflags) cflags $@`

public = a2p s2p find2perl

private = 

manpages = a2p.man s2p.man

util =

sh = Makefile.SH cflags.SH find2perl.SH s2p.SH

h = EXTERN.h INTERN.h ../config.h handy.h hash.h a2p.h str.h util.h

c = hash.c $(mallocsrc) str.c util.c walk.c

obj = hash.o $(mallocobj) str.o util.o walk.o

lintflags = -phbvxac

# grrr
SHELL = /bin/sh

.c.o:
	$(CCCMD) $*.c

all: $(public) $(private) $(util)
	touch all

a2p: $(obj) a2p.o
	$(CC) $(LDFLAGS) $(obj) a2p.o $(libs) -o a2p

!NO!SUBS!

: Only print out the rules for running byacc if the user _has_ byacc.
: Otherwise, comment them out.  Users who really know what they are
: doing can uncomment them and run yacc or bison or whatever.
: Configure sets byacc=byacc if byacc is not found.
case "$byacc" in
'')
	comment1='#' 
	comment2='' ;;
*)	comment1=''
	comment2='#' ;;
esac

$spitshell >>Makefile <<!GROK!THIS!

# I now supply a2p.c with the kits, so the following section is
# commented out if you don't have byacc.

${comment1}a2p.c: 	a2p.y
${comment1}	@ echo Expect many shift/reduce and reduce/reduce conflicts
${comment1}	\$(BYACC) a2p.y
${comment1}	mv y.tab.c a2p.c

# This version is used if you do not have byacc.
${comment2}a2p.c:	a2p.y
${comment2}	touch a2p.c

!GROK!THIS!
cat >>Makefile <<'!NO!SUBS!'

a2p.o: a2p.c a2py.c a2p.h EXTERN.h util.h INTERN.h handy.h ../config.h str.h hash.h
	$(CCCMD) $(LARGE) a2p.c

clean:
	rm -f a2p *.o 

realclean: clean
	rm -f *.orig core $(addedbyconf) all malloc.c
	rm -f Makefile cflags find2perl s2p makefile makefile.old

# The following lint has practically everything turned on.  Unfortunately,
# you have to wade through a lot of mumbo jumbo that can't be suppressed.
# If the source file has a /*NOSTRICT*/ somewhere, ignore the lint message
# for that spot.

lint:
	lint $(lintflags) $(defs) $(c) > a2p.fuzz

depend: $(mallocsrc) ../makedepend
	../makedepend

clist:
	echo $(c) | tr ' ' '\012' >.clist

hlist:
	echo $(h) | tr ' ' '\012' >.hlist

shlist:
	echo $(sh) | tr ' ' '\012' >.shlist

malloc.c: ../malloc.c
	sed <../malloc.c >malloc.c \
	    -e 's/"perl.h"/"..\/perl.h"/' \
	    -e 's/my_exit/exit/'

# AUTOMATICALLY GENERATED MAKE DEPENDENCIES--PUT NOTHING BELOW THIS LINE
$(obj):
	@ echo "You haven't done a "'"make depend" yet!'; exit 1
makedepend: depend
!NO!SUBS!
$eunicefix Makefile
case `pwd` in
*SH)
    $rm -f ../Makefile
    ln Makefile ../Makefile
    ;;
esac
rm -f makefile
