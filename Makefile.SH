case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi 2>/dev/null
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

case "$d_dosuid" in
*define*) suidperl='suidperl' ;;
*) suidperl='';;
esac

echo "Extracting Makefile (with variable substitutions)"
cat >Makefile <<!GROK!THIS!
# $RCSfile: Makefile.SH,v $$Revision: 4.0.1.2 $$Date: 91/06/07 10:14:43 $
#
# $Log:	Makefile.SH,v $
# Revision 4.0.1.2  91/06/07  10:14:43  lwall
# patch4: cflags now emits entire cc command except for the filename
# patch4: alternate make programs are now semi-supported
# patch4: uperl.o no longer tries to link in libraries prematurely
# patch4: installperl now installs x2p stuff too
# 
# Revision 4.0.1.1  91/04/11  17:30:39  lwall
# patch1: C flags are now settable on a per-file basis
# 
# Revision 4.0  91/03/20  00:58:54  lwall
# 4.0 baseline.
# 
# 

CC = $cc
YACC = $yacc
bin = $installbin
scriptdir = $scriptdir
privlib = $installprivlib
mansrc = $mansrc
manext = $manext
LDFLAGS = $ldflags
CLDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split
mallocsrc = $mallocsrc
mallocobj = $mallocobj
SLN = $sln

libs = $libs $cryptlib

public = perl taintperl $suidperl

# To use an alternate make, set $altmake in config.sh.
MAKE = ${altmake-make}

!GROK!THIS!

cat >>Makefile <<'!NO!SUBS!'

CCCMD = `sh cflags $@`

private = 

scripts = h2ph

manpages = perl.man h2ph.man

util =

sh = Makefile.SH makedepend.SH h2ph.SH

h1 = EXTERN.h INTERN.h arg.h array.h cmd.h config.h form.h handy.h
h2 = hash.h perl.h regcomp.h regexp.h spat.h stab.h str.h util.h

h = $(h1) $(h2)

c1 = array.c cmd.c cons.c consarg.c doarg.c doio.c dolist.c dump.c
c2 = eval.c form.c hash.c $(mallocsrc) perl.c regcomp.c regexec.c
c3 = stab.c str.c toke.c util.c usersub.c

c = $(c1) $(c2) $(c3)

obj1 = array.o cmd.o cons.o consarg.o doarg.o doio.o dolist.o dump.o
obj2 = eval.o form.o hash.o $(mallocobj) perl.o regcomp.o regexec.o
obj3 = stab.o str.o toke.o util.o

obj = $(obj1) $(obj2) $(obj3)

tobj1 = tarray.o tcmd.o tcons.o tconsarg.o tdoarg.o tdoio.o tdolist.o tdump.o
tobj2 = teval.o tform.o thash.o $(mallocobj) tregcomp.o tregexec.o
tobj3 = tstab.o tstr.o ttoke.o tutil.o

tobj = $(tobj1) $(tobj2) $(tobj3)

lintflags = -hbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.c.o:
	$(CCCMD) $*.c

all: $(public) $(private) $(util) uperl.o $(scripts)
	cd x2p; $(MAKE) all
	touch all

# This is the standard version that contains no "taint" checks and is
# used for all scripts that aren't set-id or running under something set-id.
# The $& notation is tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.

perl: $& perly.o $(obj) usersub.o
	$(CC) $(LARGE) $(CLDFLAGS) $(obj) perly.o usersub.o $(libs) -o perl

uperl.o: $& perly.o $(obj)
	-ld $(LARGE) $(LDFLAGS) -r $(obj) perly.o -o uperl.o

saber: perly.c
	# load $(c) perly.c

# This version, if specified in Configure, does ONLY those scripts which need
# set-id emulation.  Suidperl must be setuid root.  It contains the "taint"
# checks as well as the special code to validate that the script in question
# has been invoked correctly.

suidperl: $& tperly.o sperl.o $(tobj) usersub.o
	$(CC) $(LARGE) $(CLDFLAGS) sperl.o $(tobj) tperly.o usersub.o $(libs) \
	    -o suidperl

# This version interprets scripts that are already set-id either via a wrapper
# or through the kernel allowing set-id scripts (bad idea).  Taintperl must
# NOT be setuid to root or anything else.  The only difference between it
# and normal perl is the presence of the "taint" checks.

taintperl: $& tperly.o tperl.o $(tobj) usersub.o
	$(CC) $(LARGE) $(CLDFLAGS) tperl.o $(tobj) tperly.o usersub.o $(libs) \
	    -o taintperl

# Replicating all this junk is yucky, but I don't see a portable way to fix it.

tperly.o: perly.c perly.h $(h)
	/bin/rm -f tperly.c
	$(SLN) perly.c tperly.c
	$(CCCMD) -DTAINT tperly.c
	/bin/rm -f tperly.c

tperl.o: perl.c perly.h patchlevel.h perl.h $(h)
	/bin/rm -f tperl.c
	$(SLN) perl.c tperl.c
	$(CCCMD) -DTAINT tperl.c
	/bin/rm -f tperl.c

sperl.o: perl.c perly.h patchlevel.h $(h)
	/bin/rm -f sperl.c
	$(SLN) perl.c sperl.c
	$(CCCMD) -DTAINT -DIAMSUID sperl.c
	/bin/rm -f sperl.c

tarray.o: array.c $(h)
	/bin/rm -f tarray.c
	$(SLN) array.c tarray.c
	$(CCCMD) -DTAINT tarray.c
	/bin/rm -f tarray.c

tcmd.o: cmd.c $(h)
	/bin/rm -f tcmd.c
	$(SLN) cmd.c tcmd.c
	$(CCCMD) -DTAINT tcmd.c
	/bin/rm -f tcmd.c

tcons.o: cons.c $(h) perly.h
	/bin/rm -f tcons.c
	$(SLN) cons.c tcons.c
	$(CCCMD) -DTAINT tcons.c
	/bin/rm -f tcons.c

tconsarg.o: consarg.c $(h)
	/bin/rm -f tconsarg.c
	$(SLN) consarg.c tconsarg.c
	$(CCCMD) -DTAINT tconsarg.c
	/bin/rm -f tconsarg.c

tdoarg.o: doarg.c $(h)
	/bin/rm -f tdoarg.c
	$(SLN) doarg.c tdoarg.c
	$(CCCMD) -DTAINT tdoarg.c
	/bin/rm -f tdoarg.c

tdoio.o: doio.c $(h)
	/bin/rm -f tdoio.c
	$(SLN) doio.c tdoio.c
	$(CCCMD) -DTAINT tdoio.c
	/bin/rm -f tdoio.c

tdolist.o: dolist.c $(h)
	/bin/rm -f tdolist.c
	$(SLN) dolist.c tdolist.c
	$(CCCMD) -DTAINT tdolist.c
	/bin/rm -f tdolist.c

tdump.o: dump.c $(h)
	/bin/rm -f tdump.c
	$(SLN) dump.c tdump.c
	$(CCCMD) -DTAINT tdump.c
	/bin/rm -f tdump.c

teval.o: eval.c $(h)
	/bin/rm -f teval.c
	$(SLN) eval.c teval.c
	$(CCCMD) -DTAINT teval.c
	/bin/rm -f teval.c

tform.o: form.c $(h)
	/bin/rm -f tform.c
	$(SLN) form.c tform.c
	$(CCCMD) -DTAINT tform.c
	/bin/rm -f tform.c

thash.o: hash.c $(h)
	/bin/rm -f thash.c
	$(SLN) hash.c thash.c
	$(CCCMD) -DTAINT thash.c
	/bin/rm -f thash.c

tregcomp.o: regcomp.c $(h)
	/bin/rm -f tregcomp.c
	$(SLN) regcomp.c tregcomp.c
	$(CCCMD) -DTAINT tregcomp.c
	/bin/rm -f tregcomp.c

tregexec.o: regexec.c $(h)
	/bin/rm -f tregexec.c
	$(SLN) regexec.c tregexec.c
	$(CCCMD) -DTAINT tregexec.c
	/bin/rm -f tregexec.c

tstab.o: stab.c $(h)
	/bin/rm -f tstab.c
	$(SLN) stab.c tstab.c
	$(CCCMD) -DTAINT tstab.c
	/bin/rm -f tstab.c

tstr.o: str.c $(h) perly.h
	/bin/rm -f tstr.c
	$(SLN) str.c tstr.c
	$(CCCMD) -DTAINT tstr.c
	/bin/rm -f tstr.c

ttoke.o: toke.c $(h) perly.h
	/bin/rm -f ttoke.c
	$(SLN) toke.c ttoke.c
	$(CCCMD) -DTAINT ttoke.c
	/bin/rm -f ttoke.c

tutil.o: util.c $(h)
	/bin/rm -f tutil.c
	$(SLN) util.c tutil.c
	$(CCCMD) -DTAINT tutil.c
	/bin/rm -f tutil.c

perly.h: perly.c
	@ echo Dummy dependency for dumb parallel make
	touch perly.h

perly.c: perly.y perly.fixer
	@ echo 'Expect either' 29 shift/reduce and 59 reduce/reduce conflicts...
	@ echo '           or' 27 shift/reduce and 61 reduce/reduce conflicts...
	$(YACC) -d perly.y
	sh ./perly.fixer y.tab.c perly.c
	mv y.tab.h perly.h
	echo 'extern YYSTYPE yylval;' >>perly.h

perly.o: perly.c perly.h $(h)
	$(CCCMD) perly.c

install: all
	./perl installperl

clean:
	rm -f *.o all perl taintperl suidperl
	cd x2p; $(MAKE) clean

realclean: clean
	cd x2p; $(MAKE) realclean
	rm -f *.orig */*.orig *~ */*~ core $(addedbyconf) h2ph h2ph.man
	rm -f perly.c perly.h t/perl Makefile config.h makedepend makedir
	rm -f makefile x2p/Makefile x2p/makefile cflags x2p/cflags

# The following lint has practically everything turned on.  Unfortunately,
# you have to wade through a lot of mumbo jumbo that can't be suppressed.
# If the source file has a /*NOSTRICT*/ somewhere, ignore the lint message
# for that spot.

lint: perly.c $(c)
	lint $(lintflags) $(defs) perly.c $(c) > perl.fuzz

depend: makedepend
	- test -f perly.h || cp /dev/null perly.h
	./makedepend
	- test -s perly.h || /bin/rm -f perly.h
	cd x2p; $(MAKE) depend

test: perl
	- cd t && chmod +x TEST */*.t
	- cd t && (rm -f perl; $(SLN) ../perl .) && ./perl TEST </dev/tty

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
