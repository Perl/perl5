# .SH,v $Revision: 4.1 $Date: 92/08/07 17:18:08 $
# This file is derived from Makefile.SH.  Any changes made here will
# be lost the next time you run Configure.
#  Makefile is used to generate makefile.  The only difference
#  is that makefile has the dependencies filled in at the end.
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
BYACC = byacc
CC = cc
bin = /usr/local/bin
scriptdir = /usr/local/bin
privlib = /usr/local/lib/perl
mansrc = /usr/local/man/man1
manext = 1
LDFLAGS = 
CLDFLAGS = 

SMALL = 
LARGE =  
mallocsrc = malloc.c
mallocobj = malloc.o
dlsrc = dl_sunos.c
dlobj = dl_sunos.o
dldir = ext/dl
LNS = /bin/ln -s
RMS = rm -f
ranlib = /usr/bin/ranlib

# The following are used to build and install shared libraries for
# dynamic loading.
LDDLFLAGS = 
CCDLFLAGS = 
CCCDLFLAGS = 
SHLIBSUFFIX = .so

libs = -ldbm -ldl -lm -lposix 

public = perl 

shellflags = 

## To use an alternate make, set  in config.sh.
MAKE = make

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


$(dlsrc): $(dldir)/$(dlsrc)
	cp $(dldir)/$(dlsrc) $(dlsrc)

$(dlobj): $(dlsrc)
	$(CCCMD) $(dlsrc)


# NDBM_File extension
NDBM_File.o: NDBM_File.c
	$(CCCMD) $(CCCDLFLAGS) $*.c

NDBM_File.c:	ext/dbm/NDBM_File.xs ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	./miniperl ext/xsubpp ext/dbm/NDBM_File.xs >tmp
	mv tmp NDBM_File.c

lib/auto/NDBM_File/NDBM_File$(SHLIBSUFFIX): NDBM_File.o 
	test -d lib/auto/NDBM_File || mkdir lib/auto/NDBM_File
	ld $(LDDLFLAGS) -o $@ NDBM_File.o 

# ODBM_File extension
ODBM_File.o: ODBM_File.c
	$(CCCMD) $(CCCDLFLAGS) $*.c

ODBM_File.c:	ext/dbm/ODBM_File.xs ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	./miniperl ext/xsubpp ext/dbm/ODBM_File.xs >tmp
	mv tmp ODBM_File.c

lib/auto/ODBM_File/ODBM_File$(SHLIBSUFFIX): ODBM_File.o 
	test -d lib/auto/ODBM_File || mkdir lib/auto/ODBM_File
	ld $(LDDLFLAGS) -o $@ ODBM_File.o 

# SDBM_File extension
SDBM_File.o: SDBM_File.c
	$(CCCMD) $(CCCDLFLAGS) $*.c

SDBM_File.c:	ext/dbm/SDBM_File.xs ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	./miniperl ext/xsubpp ext/dbm/SDBM_File.xs >tmp
	mv tmp SDBM_File.c

lib/auto/SDBM_File/SDBM_File$(SHLIBSUFFIX): SDBM_File.o ext/dbm/sdbm/libsdbm.a
	test -d lib/auto/SDBM_File || mkdir lib/auto/SDBM_File
	ld $(LDDLFLAGS) -o $@ SDBM_File.o ext/dbm/sdbm/libsdbm.a

# POSIX extension
POSIX.o: POSIX.c
	$(CCCMD) $(CCCDLFLAGS) $*.c

POSIX.c:	ext/posix/POSIX.xs ext/xsubpp ext/typemap
	test -f miniperl || make miniperl
	./miniperl ext/xsubpp ext/posix/POSIX.xs >tmp
	mv tmp POSIX.c

lib/auto/POSIX/POSIX$(SHLIBSUFFIX): POSIX.o 
	test -d lib/auto/POSIX || mkdir lib/auto/POSIX
	ld $(LDDLFLAGS) -o $@ POSIX.o -lm

# List of extensions (used by writemain) to generate perlmain.c
ext=  NDBM_File ODBM_File SDBM_File POSIX
extsrc=  NDBM_File.c ODBM_File.c SDBM_File.c POSIX.c
# Extension dependencies.
extdep=  lib/auto/NDBM_File/NDBM_File$(SHLIBSUFFIX) lib/auto/ODBM_File/ODBM_File$(SHLIBSUFFIX) lib/auto/SDBM_File/SDBM_File$(SHLIBSUFFIX) lib/auto/POSIX/POSIX$(SHLIBSUFFIX)
# How to include extensions in linking command
extobj= 

ext/dbm/sdbm/libsdbm.a: ext/dbm/sdbm/sdbm.h ext/dbm/sdbm/sdbm.c
	cd ext/dbm/sdbm; $(MAKE) -f Makefile libsdbm.a

# The $& notation tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.

miniperl: $& miniperlmain.o perl.o $(obj)
	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain.o perl.o $(obj) $(libs)

perlmain.c: miniperlmain.c
	sh writemain $(ext) > perlmain.c

perlmain.o: perlmain.c

perl: $& perlmain.o perl.o $(obj) $(dlobj) $(extdep)
	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain.o perl.o $(obj) $(dlobj) $(extobj) $(libs)

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
