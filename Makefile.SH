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

case "$d_symlink" in
*define*) sln='ln -s' ;;
*) sln='ln';;
esac

case "$d_dosuid" in
*define*) suidperl='suidperl' ;;
*) suidperl='';;
esac

echo "Extracting Makefile (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >Makefile <<!GROK!THIS!
# : Makefile.SH,v 15738Revision: 4.1 15738Date: 92/08/07 17:18:08 $
#
# $Log:	Makefile.SH,v $
# Revision 4.1  92/08/07  17:18:08  lwall
# Stage 6 Snapshot
# 
# Revision 4.0.1.4  92/06/08  11:40:43  lwall
# patch20: cray didn't give enough memory to /bin/sh
# patch20: various and sundry fixes
# 
# Revision 4.0.1.3  91/11/05  15:48:11  lwall
# patch11: saberized perl
# patch11: added support for dbz
# 
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

# I now supply perly.c with the kits, so don't remake perly.c without byacc
BYACC = $byacc
CC = $cc
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
dlsrc = $dlsrc
dlobj = $dlobj
SLN = $sln
RMS = rm -f

libs = $libs $cryptlib

public = perl $suidperl

shellflags = $shellflags

# To use an alternate make, set $altmake in config.sh.
MAKE = ${altmake-make}
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>Makefile <<'!NO!SUBS!'

CCCMD = `sh $(shellflags) cflags $@`

private = 

scripts = h2ph

manpages = perl.man h2ph.man

util =

sh = Makefile.SH makedepend.SH h2ph.SH

h1 = EXTERN.h INTERN.h av.h cop.h config.h embed.h form.h handy.h
h2 = hv.h op.h opcode.h perl.h regcomp.h regexp.h gv.h sv.h util.h

h1 = EXTERN.h INTERN.h XSUB.h av.h config.h cop.h cv.h dosish.h 
h2 = embed.h form.h gv.h handy.h hv.h hvdbm.h keywords.h mg.h op.h
h3 = opcode.h patchlevel.h perl.h perly.h pp.h proto.h regcomp.h
h4 = regexp.h scope.h sv.h unixish.h util.h
h = $(h1) $(h2) $(h3) $(h4)

c1 = av.c scope.c op.c doop.c doio.c dump.c hv.c
c2 = $(mallocsrc) mg.c perly.c pp.c regcomp.c regexec.c
c3 = gv.c sv.c taint.c toke.c util.c deb.c run.c

c = $(c1) $(c2) $(c3)

s1 = av.c scope.c op.c doop.c doio.c dump.c hv.c
s2 = $(mallocobj) mg.c perly.c pp.c regcomp.c regexec.c
s3 = gv.c sv.c taint.c toke.c util.c deb.c run.c perly.c

saber = $(s1) $(s2) $(s3)

obj1 = av.o scope.o op.o doop.o doio.o dump.o hv.o
obj2 = $(mallocobj) mg.o perly.o pp.o regcomp.o regexec.o
obj3 = gv.o sv.o taint.o toke.o util.o deb.o run.o

obj = $(obj1) $(obj2) $(obj3) $(dlobj)

lintflags = -hbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.SUFFIXES: .x

.c.o:
	$(CCCMD) $*.c

.x.c:
	sh writemain $*.x >$*.c

all: miniperl perl lib/Config.pm

#all: $(public) $(private) $(util) $(scripts)
#	cd x2p; $(MAKE) all
#	touch all
!NO!SUBS!
###
### Boilerplate for all the .xs files in the ext directory.  
### XXX FIXME:  At some point we also need to copy .pm files out of 
### XXX the ext directory into lib.
#  Configure sets extensions to a string like
# "ext/dbm/NDBM_File.xs ext/dbm/ODBM_File.xs ext/dbm/GDBM_File.xs \
#  ext/dbm/SDBM_File.xs ext/posix/POSIX.xs"
extobjs=" "
for f in $extensions
do
    base=`basename $f .xs`
    dir=`dirname $f`
    extobjs="$extobjs $f.o"
    $spitshell >>Makefile <<!GROK!THIS!

# $base extension
$base.c:	$f ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	ext/xsubpp $f >tmp
	mv tmp $base.c

$base.o: $base.c
!GROK!THIS!

    case $base in
    SDBM_File) $spitshell >>Makefile <<'!NO!SUBS!'

lib/auto/SDBM_File/SDBM_File.so: SDBM_File.o ext/dbm/sdbm/libsdbm.a
	@- mkdir lib/auto/SDBM_File 2>/dev/null
	ld -o lib/auto/SDBM_File/SDBM_File.so SDBM_File.o ext/dbm/sdbm/libsdbm.a

ext/dbm/sdbm/libsdbm.a: ext/dbm/sdbm/sdbm.c ext/dbm/sdbm/sdbm.h
	cd ext/dbm/sdbm; $(MAKE) sdbm
!NO!SUBS!
    ;;
    POSIX) $spitshell >>Makefile <<'!NO!SUBS!'
lib/auto/POSIX/POSIX.so: POSIX.o ext/dbm/sdbm/libsdbm.a
	@- mkdir lib/auto/POSIX 2>/dev/null
	ld -o lib/auto/POSIX/POSIX.so POSIX.o ext/dbm/sdbm/libsdbm.a
!NO!SUBS!
    ;;
    esac
done

echo "extobjs=$extobjs" >> Makefile

$spitshell >>Makefile <<'!NO!SUBS!'
# The $& notation tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.

miniperlmain.c: miniperlmain.x
miniperlmain.o: miniperlmain.c
miniperl: $& miniperlmain.o perl.o $(obj)
	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain.o perl.o $(obj) $(libs)

perlmain.c: perlmain.x
perlmain.o: perlmain.c
perl: $& perlmain.o perl.o $(obj) NDBM_File.o ODBM_File.o POSIX.o
	$(CC) $(LARGE) $(CLDFLAGS) -o perl perlmain.o perl.o $(obj) NDBM_File.o ODBM_File.o POSIX.o $(libs)

libperl.rlb: libperl.a
	ranlib libperl.a
	touch libperl.rlb

libperl.a: $& perl.o $(obj)
	ar rcuv libperl.a $(obj)

# This version, if specified in Configure, does ONLY those scripts which need
# set-id emulation.  Suidperl must be setuid root.  It contains the "taint"
# checks as well as the special code to validate that the script in question
# has been invoked correctly.

suidperl: $& sperl.o main.o libperl.rlb
	$(CC) $(LARGE) $(CLDFLAGS) sperl.o main.o libperl.a $(libs) -o suidperl

lib/Config.pm: config.sh
	./configpm

saber: $(saber)
	# load $(saber)
	# load /lib/libm.a

sperl.o: perl.c perly.h patchlevel.h $(h)
	$(RMS) sperl.c
	$(SLN) perl.c sperl.c
	$(CCCMD) -DIAMSUID sperl.c
	$(RMS) sperl.c

dl.o: ext/dl/dl.c
	cp ext/dl/dl.c dl.c
	$(CC) -c dl.c

!NO!SUBS!

### Now on to the rest of the Makefile.
$spitshell >>Makefile <<'!NO!SUBS!'
    
perly.h: perly.c
	@ echo Dummy dependency for dumb parallel make
	touch perly.h

opcode.h: opcode.pl
	- opcode.pl

embed.h: embed_h.SH global.sym interp.sym
	sh embed_h.SH

perly.c:
	@ echo 'Expect' 80 shift/reduce and 62 reduce/reduce conflicts
	$(BYACC) -d perly.y
	sh $(shellflags) ./perly.fixer y.tab.c perly.c
	mv y.tab.h perly.h
	echo 'extern YYSTYPE yylval;' >>perly.h

perly.o: perly.c perly.h $(h)
	$(CCCMD) perly.c

install: all
	./perl installperl

clean:
	rm -f *.o all perl taintperl suidperl miniperl
	cd x2p; $(MAKE) clean

realclean: clean
	cd x2p; $(MAKE) realclean
	rm -f *.orig */*.orig *~ */*~ core $(addedbyconf) h2ph h2ph.man
	rm -f perly.h t/perl Makefile config.h makedepend makedir
	rm -f makefile x2p/Makefile x2p/makefile cflags x2p/cflags
	rm -f c2ph pstruct

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
	- cd t && (rm -f perl; $(SLN) ../perl perl) && ./perl TEST </dev/tty

clist:
	echo $(c) | tr ' ' '\012' >.clist

hlist:
	echo $(h) | tr ' ' '\012' >.hlist

shlist:
	echo $(sh) | tr ' ' '\012' >.shlist

# AUTOMATICALLY GENERATED MAKE DEPENDENCIES--PUT NOTHING BELOW THIS LINE
# If this runs make out of memory, delete /usr/include lines.
!NO!SUBS!

$eunicefix Makefile4
case `pwd` in
*SH)
    $rm -f ../Makefile4
    ln Makefile4 ../Makefile4
    ;;
esac
rm -f makefile
