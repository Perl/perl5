case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi
    . config.sh
    ;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

case "$d_symlink" in
*define*) sln='ln -s' ;;
*) sln='ln';;
esac

echo "Extracting Makefile (with variable substitutions)"
cat >Makefile <<!GROK!THIS!
# $Header: Makefile.SH,v 1.0.1.5 88/02/02 11:20:49 root Exp $
#
# $Log:	Makefile.SH,v $
# Revision 1.0.1.5  88/02/02  11:20:49  root
# patch13: added d_symlink dependency, changed TEST to ./perl TEST.
# 
# Revision 1.0.1.4  88/01/28  10:17:59  root
# patch8: added perldb.man
# 
# Revision 1.0.1.3  88/01/26  14:14:52  root
# Added mallocsrc stuff.
# 
# Revision 1.0.1.2  88/01/26  08:46:04  root
# patch 4: make depend didn't work right if . wasn't in PATH.
# 
# Revision 1.0.1.1  88/01/24  03:55:18  root
# patch 2: remove extra Log lines.
# 
# Revision 1.0  87/12/18  16:11:50  root
# Initial revision
# 

CC = $cc
bin = $bin
lib = $lib
mansrc = $mansrc
manext = $manext
CFLAGS = $ccflags -O
LDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split
mallocsrc = $mallocsrc
mallocobj = $mallocobj
SLN = $sln

libs = $libs $cryptlib $libnm -lm
!GROK!THIS!

cat >>Makefile <<'!NO!SUBS!'

public = perl perldb

private = 

manpages = perl.man perldb.man

util =

sh = Makefile.SH makedepend.SH

h1 = EXTERN.h INTERN.h arg.h array.h cmd.h config.h form.h handy.h
h2 = hash.h perl.h search.h spat.h stab.h str.h util.h

h = $(h1) $(h2)

c1 = arg.c array.c cmd.c dump.c form.c hash.c $(mallocsrc)
c2 = search.c stab.c str.c util.c version.c

c = $(c1) $(c2)

obj1 = arg.o array.o cmd.o dump.o form.o hash.o $(mallocobj)
obj2 = search.o stab.o str.o util.o version.o

obj = $(obj1) $(obj2)

lintflags = -phbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.c.o:
	$(CC) -c $(CFLAGS) $(LARGE) $*.c

all: $(public) $(private) $(util)
	touch all

perl: $(obj) perl.o
	$(CC) $(LDFLAGS) $(LARGE) $(obj) perl.o $(libs) -o perl

perl.c: perl.y
	@ echo Expect 2 shift/reduce errors...
	yacc perl.y
	mv y.tab.c perl.c

perl.o: perl.c perly.c perl.h EXTERN.h search.h util.h INTERN.h handy.h
	$(CC) -c $(CFLAGS) $(LARGE) perl.c

# if a .h file depends on another .h file...
$(h):
	touch $@

perl.man: perl.man.1 perl.man.2
	cat perl.man.1 perl.man.2 >perl.man

install: perl perl.man
# won't work with csh
	export PATH || exit 1
	- mv $(bin)/perl $(bin)/perl.old
	- if test `pwd` != $(bin); then cp $(public) $(bin); fi
	cd $(bin); \
for pub in $(public); do \
chmod 755 `basename $$pub`; \
done
	- test $(bin) = /bin || rm -f /bin/perl
	- test $(bin) = /bin || ln -s $(bin)/perl /bin || cp $(bin)/perl /bin
#	chmod 755 makedir
#	- makedir `filexp $(lib)`
#	- \
#if test `pwd` != `filexp $(lib)`; then \
#cp $(private) `filexp $(lib)`; \
#fi
#	cd `filexp $(lib)`; \
#for priv in $(private); do \
#chmod 755 `basename $$priv`; \
#done
	- if test `pwd` != $(mansrc); then \
for page in $(manpages); do \
cp $$page $(mansrc)/`basename $$page .man`.$(manext); \
done; \
fi

clean:
	rm -f *.o

realclean:
	rm -f perl *.orig */*.orig *.o core $(addedbyconf)

# The following lint has practically everything turned on.  Unfortunately,
# you have to wade through a lot of mumbo jumbo that can't be suppressed.
# If the source file has a /*NOSTRICT*/ somewhere, ignore the lint message
# for that spot.

lint:
	lint $(lintflags) $(defs) $(c) > perl.fuzz

depend: makedepend
	./makedepend

test: perl
	chmod 755 t/TEST t/base.* t/comp.* t/cmd.* t/io.* t/op.*
	cd t && (rm -f perl; $(SLN) ../perl .) && ./perl TEST

clist:
	echo $(c) | tr ' ' '\012' >.clist

hlist:
	echo $(h) | tr ' ' '\012' >.hlist

shlist:
	echo $(sh) | tr ' ' '\012' >.shlist

# AUTOMATICALLY GENERATED MAKE DEPENDENCIES--PUT NOTHING BELOW THIS LINE
$(obj):
	@ echo "You haven't done a "'"make depend" yet!'; exit 1
makedepend: makedepend.SH
	/bin/sh makedepend.SH
!NO!SUBS!
$eunicefix Makefile
case `pwd` in
*SH)
    $rm -f ../Makefile
    ln Makefile ../Makefile
    ;;
esac
