case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi
    . ./config.sh
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
# $Header: Makefile.SH,v 2.0 88/06/05 00:07:54 root Exp $
#
# $Log:	Makefile.SH,v $
# Revision 2.0  88/06/05  00:07:54  root
# Baseline version 2.0.
# 
# 

CC = $cc
bin = $bin
lib = $privlib
mansrc = $mansrc
manext = $manext
CFLAGS = $ccflags -O
LDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split
mallocsrc = $mallocsrc
mallocobj = $mallocobj
SLN = $sln

libs = $libnm -lm
!GROK!THIS!

cat >>Makefile <<'!NO!SUBS!'

public = perl perldb

private = 

manpages = perl.man perldb.man

util =

sh = Makefile.SH makedepend.SH

h1 = EXTERN.h INTERN.h arg.h array.h cmd.h config.h form.h handy.h
h2 = hash.h perl.h regexp.h spat.h stab.h str.h util.h

h = $(h1) $(h2)

c1 = arg.c array.c cmd.c dump.c eval.c form.c hash.c $(mallocsrc)
c2 = perly.c regexp.c stab.c str.c toke.c util.c version.c

c = $(c1) $(c2)

obj1 = arg.o array.o cmd.o dump.o eval.o form.o hash.o $(mallocobj)
obj2 = perly.o regexp.o stab.o str.o toke.o util.o version.o

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

perl.c perly.h: perl.y
	@ echo Expect 37 shift/reduce errors...
	yacc -d perl.y
	mv y.tab.c perl.c
	mv y.tab.h perly.h

perl.o: perl.c perly.h perl.h EXTERN.h regexp.h util.h INTERN.h handy.h config.h
	$(CC) -c $(CFLAGS) $(LARGE) perl.c

# if a .h file depends on another .h file...
$(h):
	touch $@

perl.man: perl.man.1 perl.man.2
	cat perl.man.1 perl.man.2 >perl.man

install: perl perl.man
# won't work with csh
	export PATH || exit 1
	- mv $(bin)/perl $(bin)/perl.old 2>/dev/null
	- if test `pwd` != $(bin); then cp $(public) $(bin); fi
	cd $(bin); \
for pub in $(public); do \
chmod +x `basename $$pub`; \
done
	- test $(bin) = /usr/bin || rm -f /usr/bin/perl
	- test $(bin) = /usr/bin || $(SLN) $(bin)/perl /usr/bin || cp $(bin)/perl /usr/bin
	chmod +x makedir
	- ./makedir $(lib)
	- \
if test `pwd` != $(lib); then \
cp $(private) lib/*.pl $(lib); \
fi
#	cd $(lib); \
#for priv in $(private); do \
#chmod +x `basename $$priv`; \
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

lint: perl.c $(c)
	lint $(lintflags) $(defs) perl.c $(c) > perl.fuzz

depend: makedepend
	- test -f perly.h || cp /dev/null perly.h
	./makedepend
	- test -s perly.h || /bin/rm -f perly.h

test: perl
	chmod +x t/TEST t/base.* t/comp.* t/cmd.* t/io.* t/op.*
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
