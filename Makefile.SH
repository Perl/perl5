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

case "$d_dosuid" in
*define*) suidperl='suidperl' ;;
*) suidperl='';;
esac

: Certain parts of Makefile need to be commented out if dynamic
: loading is not used.
case "$usedl" in
define) comment='' ;;
*)	comment='#' ;;
esac

echo "Extracting Makefile (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >Makefile <<!GROK!THIS!
# $Makefile.SH,v $Revision: 4.1 $Date: 92/08/07 17:18:08 $
# This file is derived from Makefile.SH.  Any changes made here will
# be lost the next time you run Configure.
#  Makefile is used to generate makefile.  The only difference
#  is that makefile has the dependencies filled in at the end.
#
# \$Log:	Makefile.SH,v \$
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
dldir = $dldir
LNS = $lns
RMS = rm -f
ranlib = $ranlib

# The following are used to build and install shared libraries for
# dynamic loading.
LDDLFLAGS = $lddlflags
CCDLFLAGS = $ccdlflags
CCCDLFLAGS = $cccdlflags
SHLIBSUFFIX = $shlibsuffix

libs = $libs $cryptlib

public = perl $suidperl

shellflags = $shellflags

## To use an alternate make, set $altmake in config.sh.
MAKE = ${altmake-make}
!GROK!THIS!

## In the following dollars and backticks do not need the extra backslash.
$spitshell >>Makefile <<'!NO!SUBS!'

CCCMD = `sh $(shellflags) cflags $@`

private = 

scripts = h2ph

manpages = perl.man h2ph.man

util =

sh = Makefile.SH cflags.SH embed_h.SH makedepend.SH makedir.SH writemain.SH

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

c = $(c1) $(c2) $(c3) $(dlsrc) miniperlmain.c perlmain.c

s1 = av.c scope.c op.c doop.c doio.c dump.c hv.c
s2 = $(mallocsrc) mg.c perly.c pp.c regcomp.c regexec.c
s3 = gv.c sv.c taint.c toke.c util.c deb.c run.c perly.c

saber = $(s1) $(s2) $(s3) $(dlsrc)

obj1 = av.o scope.o op.o doop.o doio.o dump.o hv.o
obj2 = $(mallocobj) mg.o perly.o pp.o regcomp.o regexec.o
obj3 = gv.o sv.o taint.o toke.o util.o deb.o run.o

obj = $(obj1) $(obj2) $(obj3)

lintflags = -hbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.c.o:
	$(CCCMD) $*.c

all: miniperl perl lib/Config.pm

#all: $(public) $(private) $(util) $(scripts)
#	cd x2p; $(MAKE) all
#	touch all

# Phony target to force checking subdirectories.
FORCE:

!NO!SUBS!

### Some makes have problems with the following dependency
### if $(dlsrc) or $(dlobj) is empty.
### Therefore, comment it out if dlsrc is null.
### 
$spitshell >>Makefile <<!GROK!THIS!
${comment}
${comment}\$(dlsrc): \$(dldir)/\$(dlsrc)
${comment}	cp \$(dldir)/\$(dlsrc) \$(dlsrc)

${comment}\$(dlobj): \$(dlsrc)
${comment}	\$(CCCMD) \$(dlsrc)

!GROK!THIS!

###
### Boilerplate for all the .xs files in the ext directory.  
### XXX FIXME:  At some point we also need to copy .pm files out of 
### XXX the ext directory into lib.
### XXX FIXME:  At some point we need to run autosplit on the .pm
### XXX files.
### Configure sets extensions to a string like
### "ext/dbm/NDBM_File.xs ext/dbm/ODBM_File.xs ext/dbm/GDBM_File.xs \
###  ext/dbm/SDBM_File.xs ext/posix/POSIX.xs"
ext=" "
extdep=" "
extobj=" "
extsrc=" "
# extradep gives any extra dependencies of this extension.
# extraobj gives any extra thinks to link with this extension.
for f in $extensions
do
    base=`echo $f | $sed -e 's@.*/\(.*\).xs@\1@'`
    ext="$ext $base"
    extsrc="$extsrc $base.c"
    case $base in
        SDBM_File) extradep="ext/dbm/sdbm/libsdbm.a"
                   extraobj="ext/dbm/sdbm/libsdbm.a" ;;
        POSIX) extradep=""   
	       extraobj="-lm" ;;
        *) extradep=""
	   extraobj="" ;;
    esac
    case "$usedl" in
	define) extdep="$extdep lib/auto/$base/${base}\$(SHLIBSUFFIX)"
                ;;
	*)	extdep="$extdep $base.o $extradep"
      		extobj="$extobj $base.o $extraobj" ;; 
    esac
    
    $spitshell >>Makefile <<!GROK!THIS!

# $base extension
$base.o: $base.c
	\$(CCCMD) \$(CCCDLFLAGS) \$*.c

$base.c:	$f ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	./miniperl ext/xsubpp $f >tmp
	mv tmp $base.c

${comment}lib/auto/$base/$base\$(SHLIBSUFFIX): $base.o $extradep
${comment}	test -d lib/auto/$base || mkdir lib/auto/$base
${comment}	ld \$(LDDLFLAGS) -o \$@ $base.o $extraobj
!GROK!THIS!

done

$spitshell >>Makefile <<!GROK!THIS!

# List of extensions (used by writemain) to generate perlmain.c
ext=$ext
extsrc=$extsrc
# Extension dependencies.
extdep=$extdep
# How to include extensions in linking command
extobj=$extobj

ext/dbm/sdbm/libsdbm.a: ext/dbm/sdbm/sdbm.h ext/dbm/sdbm/sdbm.c
	cd ext/dbm/sdbm; \$(MAKE) -f Makefile libsdbm.a

!GROK!THIS!

### Now on to the rest of the Makefile.
$spitshell >>Makefile <<'!NO!SUBS!'
# The $& notation tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.

miniperl: $& miniperlmain.o perl.o $(obj)
	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain.o perl.o $(obj) $(libs)

perlmain.c: miniperlmain.c
	sh writemain $(ext) > perlmain.c

perlmain.o: perlmain.c

perl: $& perlmain.o perl.o $(obj) $(dlobj) $(extdep)
	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain.o perl.o $(obj) $(dlobj) $(extobj) $(libs)

pureperl: $& perlmain.o perl.o $(obj) $(dlobj) $(extdep)
	purify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o pureperl perlmain.o perl.o $(obj) $(dlobj) $(extobj) $(libs)

quantperl: $& perlmain.o perl.o $(obj) $(dlobj) $(extdep)
	quantify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o quantperl perlmain.o perl.o $(obj) $(dlobj) $(extobj) $(libs)

libperl.rlb: libperl.a
	$(ranlib) libperl.a
	touch libperl.rlb

libperl.a: $& perl.o $(obj)
	ar rcuv libperl.a $(obj)

# This version, if specified in Configure, does ONLY those scripts which need
# set-id emulation.  Suidperl must be setuid root.  It contains the "taint"
# checks as well as the special code to validate that the script in question
# has been invoked correctly.

suidperl: $& sperl.o perlmain.o libperl.rlb
	$(CC) $(LARGE) $(CLDFLAGS) sperl.o perlmain.o libperl.a $(libs) -o suidperl

lib/Config.pm: config.sh miniperl
	./miniperl configpm

saber: $(saber)
	# load $(saber)
	# load /lib/libm.a

sperl.o: perl.c perly.h patchlevel.h $(h)
	$(RMS) sperl.c
	$(LNS) perl.c sperl.c
	$(CCCMD) -DIAMSUID sperl.c
	$(RMS) sperl.c

perly.h: perly.c
	@ echo Dummy dependency for dumb parallel make
	touch perly.h

opcode.h: opcode.pl
	- perl opcode.pl

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
	rm -f *.o all perl miniperl
	rm -f POSIX.c ?DBM_File.c perlmain.c
	rm -f ext/dbm/sdbm/libsdbm.a
	cd ext/dbm/sdbm; $(MAKE) -f Makefile clean
	cd x2p; $(MAKE) clean

realclean: clean
	cd x2p; $(MAKE) realclean
	cd ext/dbm/sdbm; $(MAKE) -f Makefile realclean
	rm -f *.orig */*.orig *~ */*~ core $(addedbyconf) h2ph h2ph.man
	rm -f Makefile cflags embed_h makedepend makedir writemain
	rm -f config.h t/perl makefile makefile.old cflags 
	rm -rf lib/auto/?DBM_File lib/auto/POSIX
	rm -f x2p/Makefile x2p/makefile x2p/makefile.old x2p/cflags
	rm -f lib/Config.pm
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

test: perl lib/Config.pm
	- cd t && chmod +x TEST */*.t
	- cd t && (rm -f perl; $(LNS) ../perl perl) && ./perl TEST </dev/tty

clist:	$(c)
	echo $(c) | tr ' ' '\012' >.clist

hlist:  $(h)
	echo $(h) | tr ' ' '\012' >.hlist

shlist: $(sh)
	echo $(sh) | tr ' ' '\012' >.shlist

# AUTOMATICALLY GENERATED MAKE DEPENDENCIES--PUT NOTHING BELOW THIS LINE
# If this runs make out of memory, delete /usr/include lines.
!NO!SUBS!

$eunicefix Makefile
case `pwd` in
*SH)
    $rm -f ../Makefile
    ln Makefile ../Makefile
    ;;
esac
rm -f makefile
