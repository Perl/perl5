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
av.o: /usr/include/ctype.h
av.o: /usr/include/dirent.h
av.o: /usr/include/errno.h
av.o: /usr/include/machine/param.h
av.o: /usr/include/machine/setjmp.h
av.o: /usr/include/netinet/in.h
av.o: /usr/include/setjmp.h
av.o: /usr/include/stdio.h
av.o: /usr/include/sys/dirent.h
av.o: /usr/include/sys/errno.h
av.o: /usr/include/sys/filio.h
av.o: /usr/include/sys/ioccom.h
av.o: /usr/include/sys/ioctl.h
av.o: /usr/include/sys/param.h
av.o: /usr/include/sys/signal.h
av.o: /usr/include/sys/sockio.h
av.o: /usr/include/sys/stat.h
av.o: /usr/include/sys/stdtypes.h
av.o: /usr/include/sys/sysmacros.h
av.o: /usr/include/sys/time.h
av.o: /usr/include/sys/times.h
av.o: /usr/include/sys/ttold.h
av.o: /usr/include/sys/ttychars.h
av.o: /usr/include/sys/ttycom.h
av.o: /usr/include/sys/ttydev.h
av.o: /usr/include/sys/types.h
av.o: /usr/include/time.h
av.o: /usr/include/varargs.h
av.o: /usr/include/vm/faultcode.h
av.o: EXTERN.h
av.o: av.c
av.o: av.h
av.o: config.h
av.o: cop.h
av.o: cv.h
av.o: embed.h
av.o: form.h
av.o: gv.h
av.o: handy.h
av.o: hv.h
av.o: mg.h
av.o: op.h
av.o: opcode.h
av.o: perl.h
av.o: pp.h
av.o: proto.h
av.o: regexp.h
av.o: scope.h
av.o: sv.h
av.o: unixish.h
av.o: util.h
scope.o: /usr/include/ctype.h
scope.o: /usr/include/dirent.h
scope.o: /usr/include/errno.h
scope.o: /usr/include/machine/param.h
scope.o: /usr/include/machine/setjmp.h
scope.o: /usr/include/netinet/in.h
scope.o: /usr/include/setjmp.h
scope.o: /usr/include/stdio.h
scope.o: /usr/include/sys/dirent.h
scope.o: /usr/include/sys/errno.h
scope.o: /usr/include/sys/filio.h
scope.o: /usr/include/sys/ioccom.h
scope.o: /usr/include/sys/ioctl.h
scope.o: /usr/include/sys/param.h
scope.o: /usr/include/sys/signal.h
scope.o: /usr/include/sys/sockio.h
scope.o: /usr/include/sys/stat.h
scope.o: /usr/include/sys/stdtypes.h
scope.o: /usr/include/sys/sysmacros.h
scope.o: /usr/include/sys/time.h
scope.o: /usr/include/sys/times.h
scope.o: /usr/include/sys/ttold.h
scope.o: /usr/include/sys/ttychars.h
scope.o: /usr/include/sys/ttycom.h
scope.o: /usr/include/sys/ttydev.h
scope.o: /usr/include/sys/types.h
scope.o: /usr/include/time.h
scope.o: /usr/include/varargs.h
scope.o: /usr/include/vm/faultcode.h
scope.o: EXTERN.h
scope.o: av.h
scope.o: config.h
scope.o: cop.h
scope.o: cv.h
scope.o: embed.h
scope.o: form.h
scope.o: gv.h
scope.o: handy.h
scope.o: hv.h
scope.o: mg.h
scope.o: op.h
scope.o: opcode.h
scope.o: perl.h
scope.o: pp.h
scope.o: proto.h
scope.o: regexp.h
scope.o: scope.c
scope.o: scope.h
scope.o: sv.h
scope.o: unixish.h
scope.o: util.h
op.o: /usr/include/ctype.h
op.o: /usr/include/dirent.h
op.o: /usr/include/errno.h
op.o: /usr/include/machine/param.h
op.o: /usr/include/machine/setjmp.h
op.o: /usr/include/netinet/in.h
op.o: /usr/include/setjmp.h
op.o: /usr/include/stdio.h
op.o: /usr/include/sys/dirent.h
op.o: /usr/include/sys/errno.h
op.o: /usr/include/sys/filio.h
op.o: /usr/include/sys/ioccom.h
op.o: /usr/include/sys/ioctl.h
op.o: /usr/include/sys/param.h
op.o: /usr/include/sys/signal.h
op.o: /usr/include/sys/sockio.h
op.o: /usr/include/sys/stat.h
op.o: /usr/include/sys/stdtypes.h
op.o: /usr/include/sys/sysmacros.h
op.o: /usr/include/sys/time.h
op.o: /usr/include/sys/times.h
op.o: /usr/include/sys/ttold.h
op.o: /usr/include/sys/ttychars.h
op.o: /usr/include/sys/ttycom.h
op.o: /usr/include/sys/ttydev.h
op.o: /usr/include/sys/types.h
op.o: /usr/include/time.h
op.o: /usr/include/varargs.h
op.o: /usr/include/vm/faultcode.h
op.o: EXTERN.h
op.o: av.h
op.o: config.h
op.o: cop.h
op.o: cv.h
op.o: embed.h
op.o: form.h
op.o: gv.h
op.o: handy.h
op.o: hv.h
op.o: mg.h
op.o: op.c
op.o: op.h
op.o: opcode.h
op.o: perl.h
op.o: pp.h
op.o: proto.h
op.o: regexp.h
op.o: scope.h
op.o: sv.h
op.o: unixish.h
op.o: util.h
doop.o: /usr/include/ctype.h
doop.o: /usr/include/dirent.h
doop.o: /usr/include/errno.h
doop.o: /usr/include/machine/param.h
doop.o: /usr/include/machine/setjmp.h
doop.o: /usr/include/netinet/in.h
doop.o: /usr/include/setjmp.h
doop.o: /usr/include/stdio.h
doop.o: /usr/include/sys/dirent.h
doop.o: /usr/include/sys/errno.h
doop.o: /usr/include/sys/filio.h
doop.o: /usr/include/sys/ioccom.h
doop.o: /usr/include/sys/ioctl.h
doop.o: /usr/include/sys/param.h
doop.o: /usr/include/sys/signal.h
doop.o: /usr/include/sys/sockio.h
doop.o: /usr/include/sys/stat.h
doop.o: /usr/include/sys/stdtypes.h
doop.o: /usr/include/sys/sysmacros.h
doop.o: /usr/include/sys/time.h
doop.o: /usr/include/sys/times.h
doop.o: /usr/include/sys/ttold.h
doop.o: /usr/include/sys/ttychars.h
doop.o: /usr/include/sys/ttycom.h
doop.o: /usr/include/sys/ttydev.h
doop.o: /usr/include/sys/types.h
doop.o: /usr/include/time.h
doop.o: /usr/include/varargs.h
doop.o: /usr/include/vm/faultcode.h
doop.o: EXTERN.h
doop.o: av.h
doop.o: config.h
doop.o: cop.h
doop.o: cv.h
doop.o: doop.c
doop.o: embed.h
doop.o: form.h
doop.o: gv.h
doop.o: handy.h
doop.o: hv.h
doop.o: mg.h
doop.o: op.h
doop.o: opcode.h
doop.o: perl.h
doop.o: pp.h
doop.o: proto.h
doop.o: regexp.h
doop.o: scope.h
doop.o: sv.h
doop.o: unixish.h
doop.o: util.h
doio.o: /usr/include/ctype.h
doio.o: /usr/include/debug/debug.h
doio.o: /usr/include/dirent.h
doio.o: /usr/include/errno.h
doio.o: /usr/include/machine/mmu.h
doio.o: /usr/include/machine/param.h
doio.o: /usr/include/machine/setjmp.h
doio.o: /usr/include/mon/obpdefs.h
doio.o: /usr/include/mon/openprom.h
doio.o: /usr/include/mon/sunromvec.h
doio.o: /usr/include/netinet/in.h
doio.o: /usr/include/setjmp.h
doio.o: /usr/include/stdio.h
doio.o: /usr/include/sys/dirent.h
doio.o: /usr/include/sys/errno.h
doio.o: /usr/include/sys/fcntlcom.h
doio.o: /usr/include/sys/file.h
doio.o: /usr/include/sys/filio.h
doio.o: /usr/include/sys/ioccom.h
doio.o: /usr/include/sys/ioctl.h
doio.o: /usr/include/sys/ipc.h
doio.o: /usr/include/sys/msg.h
doio.o: /usr/include/sys/param.h
doio.o: /usr/include/sys/sem.h
doio.o: /usr/include/sys/shm.h
doio.o: /usr/include/sys/signal.h
doio.o: /usr/include/sys/sockio.h
doio.o: /usr/include/sys/stat.h
doio.o: /usr/include/sys/stdtypes.h
doio.o: /usr/include/sys/sysmacros.h
doio.o: /usr/include/sys/time.h
doio.o: /usr/include/sys/times.h
doio.o: /usr/include/sys/ttold.h
doio.o: /usr/include/sys/ttychars.h
doio.o: /usr/include/sys/ttycom.h
doio.o: /usr/include/sys/ttydev.h
doio.o: /usr/include/sys/types.h
doio.o: /usr/include/time.h
doio.o: /usr/include/utime.h
doio.o: /usr/include/varargs.h
doio.o: /usr/include/vm/faultcode.h
doio.o: EXTERN.h
doio.o: av.h
doio.o: config.h
doio.o: cop.h
doio.o: cv.h
doio.o: doio.c
doio.o: embed.h
doio.o: form.h
doio.o: gv.h
doio.o: handy.h
doio.o: hv.h
doio.o: mg.h
doio.o: op.h
doio.o: opcode.h
doio.o: perl.h
doio.o: pp.h
doio.o: proto.h
doio.o: regexp.h
doio.o: scope.h
doio.o: sv.h
doio.o: unixish.h
doio.o: util.h
dump.o: /usr/include/ctype.h
dump.o: /usr/include/dirent.h
dump.o: /usr/include/errno.h
dump.o: /usr/include/machine/param.h
dump.o: /usr/include/machine/setjmp.h
dump.o: /usr/include/netinet/in.h
dump.o: /usr/include/setjmp.h
dump.o: /usr/include/stdio.h
dump.o: /usr/include/sys/dirent.h
dump.o: /usr/include/sys/errno.h
dump.o: /usr/include/sys/filio.h
dump.o: /usr/include/sys/ioccom.h
dump.o: /usr/include/sys/ioctl.h
dump.o: /usr/include/sys/param.h
dump.o: /usr/include/sys/signal.h
dump.o: /usr/include/sys/sockio.h
dump.o: /usr/include/sys/stat.h
dump.o: /usr/include/sys/stdtypes.h
dump.o: /usr/include/sys/sysmacros.h
dump.o: /usr/include/sys/time.h
dump.o: /usr/include/sys/times.h
dump.o: /usr/include/sys/ttold.h
dump.o: /usr/include/sys/ttychars.h
dump.o: /usr/include/sys/ttycom.h
dump.o: /usr/include/sys/ttydev.h
dump.o: /usr/include/sys/types.h
dump.o: /usr/include/time.h
dump.o: /usr/include/varargs.h
dump.o: /usr/include/vm/faultcode.h
dump.o: EXTERN.h
dump.o: av.h
dump.o: config.h
dump.o: cop.h
dump.o: cv.h
dump.o: dump.c
dump.o: embed.h
dump.o: form.h
dump.o: gv.h
dump.o: handy.h
dump.o: hv.h
dump.o: mg.h
dump.o: op.h
dump.o: opcode.h
dump.o: perl.h
dump.o: pp.h
dump.o: proto.h
dump.o: regexp.h
dump.o: scope.h
dump.o: sv.h
dump.o: unixish.h
dump.o: util.h
hv.o: /usr/include/ctype.h
hv.o: /usr/include/dirent.h
hv.o: /usr/include/errno.h
hv.o: /usr/include/machine/param.h
hv.o: /usr/include/machine/setjmp.h
hv.o: /usr/include/netinet/in.h
hv.o: /usr/include/setjmp.h
hv.o: /usr/include/stdio.h
hv.o: /usr/include/sys/dirent.h
hv.o: /usr/include/sys/errno.h
hv.o: /usr/include/sys/filio.h
hv.o: /usr/include/sys/ioccom.h
hv.o: /usr/include/sys/ioctl.h
hv.o: /usr/include/sys/param.h
hv.o: /usr/include/sys/signal.h
hv.o: /usr/include/sys/sockio.h
hv.o: /usr/include/sys/stat.h
hv.o: /usr/include/sys/stdtypes.h
hv.o: /usr/include/sys/sysmacros.h
hv.o: /usr/include/sys/time.h
hv.o: /usr/include/sys/times.h
hv.o: /usr/include/sys/ttold.h
hv.o: /usr/include/sys/ttychars.h
hv.o: /usr/include/sys/ttycom.h
hv.o: /usr/include/sys/ttydev.h
hv.o: /usr/include/sys/types.h
hv.o: /usr/include/time.h
hv.o: /usr/include/varargs.h
hv.o: /usr/include/vm/faultcode.h
hv.o: EXTERN.h
hv.o: av.h
hv.o: config.h
hv.o: cop.h
hv.o: cv.h
hv.o: embed.h
hv.o: form.h
hv.o: gv.h
hv.o: handy.h
hv.o: hv.c
hv.o: hv.h
hv.o: mg.h
hv.o: op.h
hv.o: opcode.h
hv.o: perl.h
hv.o: pp.h
hv.o: proto.h
hv.o: regexp.h
hv.o: scope.h
hv.o: sv.h
hv.o: unixish.h
hv.o: util.h
malloc.o: /usr/include/ctype.h
malloc.o: /usr/include/dirent.h
malloc.o: /usr/include/errno.h
malloc.o: /usr/include/machine/param.h
malloc.o: /usr/include/machine/setjmp.h
malloc.o: /usr/include/netinet/in.h
malloc.o: /usr/include/setjmp.h
malloc.o: /usr/include/stdio.h
malloc.o: /usr/include/sys/dirent.h
malloc.o: /usr/include/sys/errno.h
malloc.o: /usr/include/sys/filio.h
malloc.o: /usr/include/sys/ioccom.h
malloc.o: /usr/include/sys/ioctl.h
malloc.o: /usr/include/sys/param.h
malloc.o: /usr/include/sys/signal.h
malloc.o: /usr/include/sys/sockio.h
malloc.o: /usr/include/sys/stat.h
malloc.o: /usr/include/sys/stdtypes.h
malloc.o: /usr/include/sys/sysmacros.h
malloc.o: /usr/include/sys/time.h
malloc.o: /usr/include/sys/times.h
malloc.o: /usr/include/sys/ttold.h
malloc.o: /usr/include/sys/ttychars.h
malloc.o: /usr/include/sys/ttycom.h
malloc.o: /usr/include/sys/ttydev.h
malloc.o: /usr/include/sys/types.h
malloc.o: /usr/include/time.h
malloc.o: /usr/include/varargs.h
malloc.o: /usr/include/vm/faultcode.h
malloc.o: EXTERN.h
malloc.o: av.h
malloc.o: config.h
malloc.o: cop.h
malloc.o: cv.h
malloc.o: embed.h
malloc.o: form.h
malloc.o: gv.h
malloc.o: handy.h
malloc.o: hv.h
malloc.o: malloc.c
malloc.o: mg.h
malloc.o: op.h
malloc.o: opcode.h
malloc.o: perl.h
malloc.o: pp.h
malloc.o: proto.h
malloc.o: regexp.h
malloc.o: scope.h
malloc.o: sv.h
malloc.o: unixish.h
malloc.o: util.h
mg.o: /usr/include/ctype.h
mg.o: /usr/include/dirent.h
mg.o: /usr/include/errno.h
mg.o: /usr/include/machine/param.h
mg.o: /usr/include/machine/setjmp.h
mg.o: /usr/include/netinet/in.h
mg.o: /usr/include/setjmp.h
mg.o: /usr/include/stdio.h
mg.o: /usr/include/sys/dirent.h
mg.o: /usr/include/sys/errno.h
mg.o: /usr/include/sys/filio.h
mg.o: /usr/include/sys/ioccom.h
mg.o: /usr/include/sys/ioctl.h
mg.o: /usr/include/sys/param.h
mg.o: /usr/include/sys/signal.h
mg.o: /usr/include/sys/sockio.h
mg.o: /usr/include/sys/stat.h
mg.o: /usr/include/sys/stdtypes.h
mg.o: /usr/include/sys/sysmacros.h
mg.o: /usr/include/sys/time.h
mg.o: /usr/include/sys/times.h
mg.o: /usr/include/sys/ttold.h
mg.o: /usr/include/sys/ttychars.h
mg.o: /usr/include/sys/ttycom.h
mg.o: /usr/include/sys/ttydev.h
mg.o: /usr/include/sys/types.h
mg.o: /usr/include/time.h
mg.o: /usr/include/varargs.h
mg.o: /usr/include/vm/faultcode.h
mg.o: EXTERN.h
mg.o: av.h
mg.o: config.h
mg.o: cop.h
mg.o: cv.h
mg.o: embed.h
mg.o: form.h
mg.o: gv.h
mg.o: handy.h
mg.o: hv.h
mg.o: mg.c
mg.o: mg.h
mg.o: op.h
mg.o: opcode.h
mg.o: perl.h
mg.o: pp.h
mg.o: proto.h
mg.o: regexp.h
mg.o: scope.h
mg.o: sv.h
mg.o: unixish.h
mg.o: util.h
perly.o: /usr/include/ctype.h
perly.o: /usr/include/dirent.h
perly.o: /usr/include/errno.h
perly.o: /usr/include/machine/param.h
perly.o: /usr/include/machine/setjmp.h
perly.o: /usr/include/netinet/in.h
perly.o: /usr/include/setjmp.h
perly.o: /usr/include/stdio.h
perly.o: /usr/include/sys/dirent.h
perly.o: /usr/include/sys/errno.h
perly.o: /usr/include/sys/filio.h
perly.o: /usr/include/sys/ioccom.h
perly.o: /usr/include/sys/ioctl.h
perly.o: /usr/include/sys/param.h
perly.o: /usr/include/sys/signal.h
perly.o: /usr/include/sys/sockio.h
perly.o: /usr/include/sys/stat.h
perly.o: /usr/include/sys/stdtypes.h
perly.o: /usr/include/sys/sysmacros.h
perly.o: /usr/include/sys/time.h
perly.o: /usr/include/sys/times.h
perly.o: /usr/include/sys/ttold.h
perly.o: /usr/include/sys/ttychars.h
perly.o: /usr/include/sys/ttycom.h
perly.o: /usr/include/sys/ttydev.h
perly.o: /usr/include/sys/types.h
perly.o: /usr/include/time.h
perly.o: /usr/include/varargs.h
perly.o: /usr/include/vm/faultcode.h
perly.o: EXTERN.h
perly.o: av.h
perly.o: config.h
perly.o: cop.h
perly.o: cv.h
perly.o: embed.h
perly.o: form.h
perly.o: gv.h
perly.o: handy.h
perly.o: hv.h
perly.o: mg.h
perly.o: op.h
perly.o: opcode.h
perly.o: perl.h
perly.o: perly.c
perly.o: pp.h
perly.o: proto.h
perly.o: regexp.h
perly.o: scope.h
perly.o: sv.h
perly.o: unixish.h
perly.o: util.h
pp.o: /usr/include/ctype.h
pp.o: /usr/include/dirent.h
pp.o: /usr/include/errno.h
pp.o: /usr/include/grp.h
pp.o: /usr/include/machine/param.h
pp.o: /usr/include/machine/setjmp.h
pp.o: /usr/include/netdb.h
pp.o: /usr/include/netinet/in.h
pp.o: /usr/include/pwd.h
pp.o: /usr/include/setjmp.h
pp.o: /usr/include/stdio.h
pp.o: /usr/include/sys/dirent.h
pp.o: /usr/include/sys/errno.h
pp.o: /usr/include/sys/fcntlcom.h
pp.o: /usr/include/sys/file.h
pp.o: /usr/include/sys/filio.h
pp.o: /usr/include/sys/ioccom.h
pp.o: /usr/include/sys/ioctl.h
pp.o: /usr/include/sys/param.h
pp.o: /usr/include/sys/signal.h
pp.o: /usr/include/sys/socket.h
pp.o: /usr/include/sys/sockio.h
pp.o: /usr/include/sys/stat.h
pp.o: /usr/include/sys/stdtypes.h
pp.o: /usr/include/sys/sysmacros.h
pp.o: /usr/include/sys/time.h
pp.o: /usr/include/sys/times.h
pp.o: /usr/include/sys/ttold.h
pp.o: /usr/include/sys/ttychars.h
pp.o: /usr/include/sys/ttycom.h
pp.o: /usr/include/sys/ttydev.h
pp.o: /usr/include/sys/types.h
pp.o: /usr/include/time.h
pp.o: /usr/include/utime.h
pp.o: /usr/include/varargs.h
pp.o: /usr/include/vm/faultcode.h
pp.o: EXTERN.h
pp.o: av.h
pp.o: config.h
pp.o: cop.h
pp.o: cv.h
pp.o: embed.h
pp.o: form.h
pp.o: gv.h
pp.o: handy.h
pp.o: hv.h
pp.o: mg.h
pp.o: op.h
pp.o: opcode.h
pp.o: perl.h
pp.o: pp.c
pp.o: pp.h
pp.o: proto.h
pp.o: regexp.h
pp.o: scope.h
pp.o: sv.h
pp.o: unixish.h
pp.o: util.h
regcomp.o: /usr/include/ctype.h
regcomp.o: /usr/include/dirent.h
regcomp.o: /usr/include/errno.h
regcomp.o: /usr/include/machine/param.h
regcomp.o: /usr/include/machine/setjmp.h
regcomp.o: /usr/include/netinet/in.h
regcomp.o: /usr/include/setjmp.h
regcomp.o: /usr/include/stdio.h
regcomp.o: /usr/include/sys/dirent.h
regcomp.o: /usr/include/sys/errno.h
regcomp.o: /usr/include/sys/filio.h
regcomp.o: /usr/include/sys/ioccom.h
regcomp.o: /usr/include/sys/ioctl.h
regcomp.o: /usr/include/sys/param.h
regcomp.o: /usr/include/sys/signal.h
regcomp.o: /usr/include/sys/sockio.h
regcomp.o: /usr/include/sys/stat.h
regcomp.o: /usr/include/sys/stdtypes.h
regcomp.o: /usr/include/sys/sysmacros.h
regcomp.o: /usr/include/sys/time.h
regcomp.o: /usr/include/sys/times.h
regcomp.o: /usr/include/sys/ttold.h
regcomp.o: /usr/include/sys/ttychars.h
regcomp.o: /usr/include/sys/ttycom.h
regcomp.o: /usr/include/sys/ttydev.h
regcomp.o: /usr/include/sys/types.h
regcomp.o: /usr/include/time.h
regcomp.o: /usr/include/varargs.h
regcomp.o: /usr/include/vm/faultcode.h
regcomp.o: EXTERN.h
regcomp.o: INTERN.h
regcomp.o: av.h
regcomp.o: config.h
regcomp.o: cop.h
regcomp.o: cv.h
regcomp.o: embed.h
regcomp.o: form.h
regcomp.o: gv.h
regcomp.o: handy.h
regcomp.o: hv.h
regcomp.o: mg.h
regcomp.o: op.h
regcomp.o: opcode.h
regcomp.o: perl.h
regcomp.o: pp.h
regcomp.o: proto.h
regcomp.o: regcomp.c
regcomp.o: regcomp.h
regcomp.o: regexp.h
regcomp.o: scope.h
regcomp.o: sv.h
regcomp.o: unixish.h
regcomp.o: util.h
regexec.o: /usr/include/ctype.h
regexec.o: /usr/include/dirent.h
regexec.o: /usr/include/errno.h
regexec.o: /usr/include/machine/param.h
regexec.o: /usr/include/machine/setjmp.h
regexec.o: /usr/include/netinet/in.h
regexec.o: /usr/include/setjmp.h
regexec.o: /usr/include/stdio.h
regexec.o: /usr/include/sys/dirent.h
regexec.o: /usr/include/sys/errno.h
regexec.o: /usr/include/sys/filio.h
regexec.o: /usr/include/sys/ioccom.h
regexec.o: /usr/include/sys/ioctl.h
regexec.o: /usr/include/sys/param.h
regexec.o: /usr/include/sys/signal.h
regexec.o: /usr/include/sys/sockio.h
regexec.o: /usr/include/sys/stat.h
regexec.o: /usr/include/sys/stdtypes.h
regexec.o: /usr/include/sys/sysmacros.h
regexec.o: /usr/include/sys/time.h
regexec.o: /usr/include/sys/times.h
regexec.o: /usr/include/sys/ttold.h
regexec.o: /usr/include/sys/ttychars.h
regexec.o: /usr/include/sys/ttycom.h
regexec.o: /usr/include/sys/ttydev.h
regexec.o: /usr/include/sys/types.h
regexec.o: /usr/include/time.h
regexec.o: /usr/include/varargs.h
regexec.o: /usr/include/vm/faultcode.h
regexec.o: EXTERN.h
regexec.o: av.h
regexec.o: config.h
regexec.o: cop.h
regexec.o: cv.h
regexec.o: embed.h
regexec.o: form.h
regexec.o: gv.h
regexec.o: handy.h
regexec.o: hv.h
regexec.o: mg.h
regexec.o: op.h
regexec.o: opcode.h
regexec.o: perl.h
regexec.o: pp.h
regexec.o: proto.h
regexec.o: regcomp.h
regexec.o: regexec.c
regexec.o: regexp.h
regexec.o: scope.h
regexec.o: sv.h
regexec.o: unixish.h
regexec.o: util.h
gv.o: /usr/include/ctype.h
gv.o: /usr/include/dirent.h
gv.o: /usr/include/errno.h
gv.o: /usr/include/machine/param.h
gv.o: /usr/include/machine/setjmp.h
gv.o: /usr/include/netinet/in.h
gv.o: /usr/include/setjmp.h
gv.o: /usr/include/stdio.h
gv.o: /usr/include/sys/dirent.h
gv.o: /usr/include/sys/errno.h
gv.o: /usr/include/sys/filio.h
gv.o: /usr/include/sys/ioccom.h
gv.o: /usr/include/sys/ioctl.h
gv.o: /usr/include/sys/param.h
gv.o: /usr/include/sys/signal.h
gv.o: /usr/include/sys/sockio.h
gv.o: /usr/include/sys/stat.h
gv.o: /usr/include/sys/stdtypes.h
gv.o: /usr/include/sys/sysmacros.h
gv.o: /usr/include/sys/time.h
gv.o: /usr/include/sys/times.h
gv.o: /usr/include/sys/ttold.h
gv.o: /usr/include/sys/ttychars.h
gv.o: /usr/include/sys/ttycom.h
gv.o: /usr/include/sys/ttydev.h
gv.o: /usr/include/sys/types.h
gv.o: /usr/include/time.h
gv.o: /usr/include/varargs.h
gv.o: /usr/include/vm/faultcode.h
gv.o: EXTERN.h
gv.o: av.h
gv.o: config.h
gv.o: cop.h
gv.o: cv.h
gv.o: embed.h
gv.o: form.h
gv.o: gv.c
gv.o: gv.h
gv.o: handy.h
gv.o: hv.h
gv.o: mg.h
gv.o: op.h
gv.o: opcode.h
gv.o: perl.h
gv.o: pp.h
gv.o: proto.h
gv.o: regexp.h
gv.o: scope.h
gv.o: sv.h
gv.o: unixish.h
gv.o: util.h
sv.o: /usr/include/ctype.h
sv.o: /usr/include/dirent.h
sv.o: /usr/include/errno.h
sv.o: /usr/include/machine/param.h
sv.o: /usr/include/machine/setjmp.h
sv.o: /usr/include/netinet/in.h
sv.o: /usr/include/setjmp.h
sv.o: /usr/include/stdio.h
sv.o: /usr/include/sys/dirent.h
sv.o: /usr/include/sys/errno.h
sv.o: /usr/include/sys/filio.h
sv.o: /usr/include/sys/ioccom.h
sv.o: /usr/include/sys/ioctl.h
sv.o: /usr/include/sys/param.h
sv.o: /usr/include/sys/signal.h
sv.o: /usr/include/sys/sockio.h
sv.o: /usr/include/sys/stat.h
sv.o: /usr/include/sys/stdtypes.h
sv.o: /usr/include/sys/sysmacros.h
sv.o: /usr/include/sys/time.h
sv.o: /usr/include/sys/times.h
sv.o: /usr/include/sys/ttold.h
sv.o: /usr/include/sys/ttychars.h
sv.o: /usr/include/sys/ttycom.h
sv.o: /usr/include/sys/ttydev.h
sv.o: /usr/include/sys/types.h
sv.o: /usr/include/time.h
sv.o: /usr/include/varargs.h
sv.o: /usr/include/vm/faultcode.h
sv.o: EXTERN.h
sv.o: av.h
sv.o: config.h
sv.o: cop.h
sv.o: cv.h
sv.o: embed.h
sv.o: form.h
sv.o: gv.h
sv.o: handy.h
sv.o: hv.h
sv.o: mg.h
sv.o: op.h
sv.o: opcode.h
sv.o: perl.h
sv.o: perly.h
sv.o: pp.h
sv.o: proto.h
sv.o: regexp.h
sv.o: scope.h
sv.o: sv.c
sv.o: sv.h
sv.o: unixish.h
sv.o: util.h
taint.o: /usr/include/ctype.h
taint.o: /usr/include/dirent.h
taint.o: /usr/include/errno.h
taint.o: /usr/include/machine/param.h
taint.o: /usr/include/machine/setjmp.h
taint.o: /usr/include/netinet/in.h
taint.o: /usr/include/setjmp.h
taint.o: /usr/include/stdio.h
taint.o: /usr/include/sys/dirent.h
taint.o: /usr/include/sys/errno.h
taint.o: /usr/include/sys/filio.h
taint.o: /usr/include/sys/ioccom.h
taint.o: /usr/include/sys/ioctl.h
taint.o: /usr/include/sys/param.h
taint.o: /usr/include/sys/signal.h
taint.o: /usr/include/sys/sockio.h
taint.o: /usr/include/sys/stat.h
taint.o: /usr/include/sys/stdtypes.h
taint.o: /usr/include/sys/sysmacros.h
taint.o: /usr/include/sys/time.h
taint.o: /usr/include/sys/times.h
taint.o: /usr/include/sys/ttold.h
taint.o: /usr/include/sys/ttychars.h
taint.o: /usr/include/sys/ttycom.h
taint.o: /usr/include/sys/ttydev.h
taint.o: /usr/include/sys/types.h
taint.o: /usr/include/time.h
taint.o: /usr/include/varargs.h
taint.o: /usr/include/vm/faultcode.h
taint.o: EXTERN.h
taint.o: av.h
taint.o: config.h
taint.o: cop.h
taint.o: cv.h
taint.o: embed.h
taint.o: form.h
taint.o: gv.h
taint.o: handy.h
taint.o: hv.h
taint.o: mg.h
taint.o: op.h
taint.o: opcode.h
taint.o: perl.h
taint.o: pp.h
taint.o: proto.h
taint.o: regexp.h
taint.o: scope.h
taint.o: sv.h
taint.o: taint.c
taint.o: unixish.h
taint.o: util.h
toke.o: /usr/include/ctype.h
toke.o: /usr/include/dirent.h
toke.o: /usr/include/errno.h
toke.o: /usr/include/machine/param.h
toke.o: /usr/include/machine/setjmp.h
toke.o: /usr/include/netinet/in.h
toke.o: /usr/include/setjmp.h
toke.o: /usr/include/stdio.h
toke.o: /usr/include/sys/dirent.h
toke.o: /usr/include/sys/errno.h
toke.o: /usr/include/sys/fcntlcom.h
toke.o: /usr/include/sys/file.h
toke.o: /usr/include/sys/filio.h
toke.o: /usr/include/sys/ioccom.h
toke.o: /usr/include/sys/ioctl.h
toke.o: /usr/include/sys/param.h
toke.o: /usr/include/sys/signal.h
toke.o: /usr/include/sys/sockio.h
toke.o: /usr/include/sys/stat.h
toke.o: /usr/include/sys/stdtypes.h
toke.o: /usr/include/sys/sysmacros.h
toke.o: /usr/include/sys/time.h
toke.o: /usr/include/sys/times.h
toke.o: /usr/include/sys/ttold.h
toke.o: /usr/include/sys/ttychars.h
toke.o: /usr/include/sys/ttycom.h
toke.o: /usr/include/sys/ttydev.h
toke.o: /usr/include/sys/types.h
toke.o: /usr/include/time.h
toke.o: /usr/include/varargs.h
toke.o: /usr/include/vm/faultcode.h
toke.o: EXTERN.h
toke.o: av.h
toke.o: config.h
toke.o: cop.h
toke.o: cv.h
toke.o: embed.h
toke.o: form.h
toke.o: gv.h
toke.o: handy.h
toke.o: hv.h
toke.o: keywords.h
toke.o: mg.h
toke.o: op.h
toke.o: opcode.h
toke.o: perl.h
toke.o: perly.h
toke.o: pp.h
toke.o: proto.h
toke.o: regexp.h
toke.o: scope.h
toke.o: sv.h
toke.o: toke.c
toke.o: unixish.h
toke.o: util.h
util.o: /usr/include/ctype.h
util.o: /usr/include/dirent.h
util.o: /usr/include/errno.h
util.o: /usr/include/machine/param.h
util.o: /usr/include/machine/setjmp.h
util.o: /usr/include/netinet/in.h
util.o: /usr/include/setjmp.h
util.o: /usr/include/stdio.h
util.o: /usr/include/sys/dirent.h
util.o: /usr/include/sys/errno.h
util.o: /usr/include/sys/fcntlcom.h
util.o: /usr/include/sys/file.h
util.o: /usr/include/sys/filio.h
util.o: /usr/include/sys/ioccom.h
util.o: /usr/include/sys/ioctl.h
util.o: /usr/include/sys/param.h
util.o: /usr/include/sys/signal.h
util.o: /usr/include/sys/sockio.h
util.o: /usr/include/sys/stat.h
util.o: /usr/include/sys/stdtypes.h
util.o: /usr/include/sys/sysmacros.h
util.o: /usr/include/sys/time.h
util.o: /usr/include/sys/times.h
util.o: /usr/include/sys/ttold.h
util.o: /usr/include/sys/ttychars.h
util.o: /usr/include/sys/ttycom.h
util.o: /usr/include/sys/ttydev.h
util.o: /usr/include/sys/types.h
util.o: /usr/include/time.h
util.o: /usr/include/unistd.h
util.o: /usr/include/varargs.h
util.o: /usr/include/vm/faultcode.h
util.o: EXTERN.h
util.o: av.h
util.o: config.h
util.o: cop.h
util.o: cv.h
util.o: embed.h
util.o: form.h
util.o: gv.h
util.o: handy.h
util.o: hv.h
util.o: mg.h
util.o: op.h
util.o: opcode.h
util.o: perl.h
util.o: pp.h
util.o: proto.h
util.o: regexp.h
util.o: scope.h
util.o: sv.h
util.o: unixish.h
util.o: util.c
util.o: util.h
deb.o: /usr/include/ctype.h
deb.o: /usr/include/dirent.h
deb.o: /usr/include/errno.h
deb.o: /usr/include/machine/param.h
deb.o: /usr/include/machine/setjmp.h
deb.o: /usr/include/netinet/in.h
deb.o: /usr/include/setjmp.h
deb.o: /usr/include/stdio.h
deb.o: /usr/include/sys/dirent.h
deb.o: /usr/include/sys/errno.h
deb.o: /usr/include/sys/filio.h
deb.o: /usr/include/sys/ioccom.h
deb.o: /usr/include/sys/ioctl.h
deb.o: /usr/include/sys/param.h
deb.o: /usr/include/sys/signal.h
deb.o: /usr/include/sys/sockio.h
deb.o: /usr/include/sys/stat.h
deb.o: /usr/include/sys/stdtypes.h
deb.o: /usr/include/sys/sysmacros.h
deb.o: /usr/include/sys/time.h
deb.o: /usr/include/sys/times.h
deb.o: /usr/include/sys/ttold.h
deb.o: /usr/include/sys/ttychars.h
deb.o: /usr/include/sys/ttycom.h
deb.o: /usr/include/sys/ttydev.h
deb.o: /usr/include/sys/types.h
deb.o: /usr/include/time.h
deb.o: /usr/include/varargs.h
deb.o: /usr/include/vm/faultcode.h
deb.o: EXTERN.h
deb.o: av.h
deb.o: config.h
deb.o: cop.h
deb.o: cv.h
deb.o: deb.c
deb.o: embed.h
deb.o: form.h
deb.o: gv.h
deb.o: handy.h
deb.o: hv.h
deb.o: mg.h
deb.o: op.h
deb.o: opcode.h
deb.o: perl.h
deb.o: pp.h
deb.o: proto.h
deb.o: regexp.h
deb.o: scope.h
deb.o: sv.h
deb.o: unixish.h
deb.o: util.h
run.o: /usr/include/ctype.h
run.o: /usr/include/dirent.h
run.o: /usr/include/errno.h
run.o: /usr/include/machine/param.h
run.o: /usr/include/machine/setjmp.h
run.o: /usr/include/netinet/in.h
run.o: /usr/include/setjmp.h
run.o: /usr/include/stdio.h
run.o: /usr/include/sys/dirent.h
run.o: /usr/include/sys/errno.h
run.o: /usr/include/sys/filio.h
run.o: /usr/include/sys/ioccom.h
run.o: /usr/include/sys/ioctl.h
run.o: /usr/include/sys/param.h
run.o: /usr/include/sys/signal.h
run.o: /usr/include/sys/sockio.h
run.o: /usr/include/sys/stat.h
run.o: /usr/include/sys/stdtypes.h
run.o: /usr/include/sys/sysmacros.h
run.o: /usr/include/sys/time.h
run.o: /usr/include/sys/times.h
run.o: /usr/include/sys/ttold.h
run.o: /usr/include/sys/ttychars.h
run.o: /usr/include/sys/ttycom.h
run.o: /usr/include/sys/ttydev.h
run.o: /usr/include/sys/types.h
run.o: /usr/include/time.h
run.o: /usr/include/varargs.h
run.o: /usr/include/vm/faultcode.h
run.o: EXTERN.h
run.o: av.h
run.o: config.h
run.o: cop.h
run.o: cv.h
run.o: embed.h
run.o: form.h
run.o: gv.h
run.o: handy.h
run.o: hv.h
run.o: mg.h
run.o: op.h
run.o: opcode.h
run.o: perl.h
run.o: pp.h
run.o: proto.h
run.o: regexp.h
run.o: run.c
run.o: scope.h
run.o: sv.h
run.o: unixish.h
run.o: util.h
dl_sunos.o: /usr/include/ctype.h
dl_sunos.o: /usr/include/dirent.h
dl_sunos.o: /usr/include/dlfcn.h
dl_sunos.o: /usr/include/errno.h
dl_sunos.o: /usr/include/machine/param.h
dl_sunos.o: /usr/include/machine/setjmp.h
dl_sunos.o: /usr/include/netinet/in.h
dl_sunos.o: /usr/include/setjmp.h
dl_sunos.o: /usr/include/stdio.h
dl_sunos.o: /usr/include/sys/dirent.h
dl_sunos.o: /usr/include/sys/errno.h
dl_sunos.o: /usr/include/sys/filio.h
dl_sunos.o: /usr/include/sys/ioccom.h
dl_sunos.o: /usr/include/sys/ioctl.h
dl_sunos.o: /usr/include/sys/param.h
dl_sunos.o: /usr/include/sys/signal.h
dl_sunos.o: /usr/include/sys/sockio.h
dl_sunos.o: /usr/include/sys/stat.h
dl_sunos.o: /usr/include/sys/stdtypes.h
dl_sunos.o: /usr/include/sys/sysmacros.h
dl_sunos.o: /usr/include/sys/time.h
dl_sunos.o: /usr/include/sys/times.h
dl_sunos.o: /usr/include/sys/ttold.h
dl_sunos.o: /usr/include/sys/ttychars.h
dl_sunos.o: /usr/include/sys/ttycom.h
dl_sunos.o: /usr/include/sys/ttydev.h
dl_sunos.o: /usr/include/sys/types.h
dl_sunos.o: /usr/include/time.h
dl_sunos.o: /usr/include/varargs.h
dl_sunos.o: /usr/include/vm/faultcode.h
dl_sunos.o: EXTERN.h
dl_sunos.o: XSUB.h
dl_sunos.o: av.h
dl_sunos.o: config.h
dl_sunos.o: cop.h
dl_sunos.o: cv.h
dl_sunos.o: dl_sunos.c
dl_sunos.o: embed.h
dl_sunos.o: form.h
dl_sunos.o: gv.h
dl_sunos.o: handy.h
dl_sunos.o: hv.h
dl_sunos.o: mg.h
dl_sunos.o: op.h
dl_sunos.o: opcode.h
dl_sunos.o: perl.h
dl_sunos.o: pp.h
dl_sunos.o: proto.h
dl_sunos.o: regexp.h
dl_sunos.o: scope.h
dl_sunos.o: sv.h
dl_sunos.o: unixish.h
dl_sunos.o: util.h
miniperlmain.o: /usr/include/ctype.h
miniperlmain.o: /usr/include/dirent.h
miniperlmain.o: /usr/include/errno.h
miniperlmain.o: /usr/include/machine/param.h
miniperlmain.o: /usr/include/machine/setjmp.h
miniperlmain.o: /usr/include/netinet/in.h
miniperlmain.o: /usr/include/setjmp.h
miniperlmain.o: /usr/include/stdio.h
miniperlmain.o: /usr/include/sys/dirent.h
miniperlmain.o: /usr/include/sys/errno.h
miniperlmain.o: /usr/include/sys/filio.h
miniperlmain.o: /usr/include/sys/ioccom.h
miniperlmain.o: /usr/include/sys/ioctl.h
miniperlmain.o: /usr/include/sys/param.h
miniperlmain.o: /usr/include/sys/signal.h
miniperlmain.o: /usr/include/sys/sockio.h
miniperlmain.o: /usr/include/sys/stat.h
miniperlmain.o: /usr/include/sys/stdtypes.h
miniperlmain.o: /usr/include/sys/sysmacros.h
miniperlmain.o: /usr/include/sys/time.h
miniperlmain.o: /usr/include/sys/times.h
miniperlmain.o: /usr/include/sys/ttold.h
miniperlmain.o: /usr/include/sys/ttychars.h
miniperlmain.o: /usr/include/sys/ttycom.h
miniperlmain.o: /usr/include/sys/ttydev.h
miniperlmain.o: /usr/include/sys/types.h
miniperlmain.o: /usr/include/time.h
miniperlmain.o: /usr/include/varargs.h
miniperlmain.o: /usr/include/vm/faultcode.h
miniperlmain.o: INTERN.h
miniperlmain.o: av.h
miniperlmain.o: config.h
miniperlmain.o: cop.h
miniperlmain.o: cv.h
miniperlmain.o: embed.h
miniperlmain.o: form.h
miniperlmain.o: gv.h
miniperlmain.o: handy.h
miniperlmain.o: hv.h
miniperlmain.o: mg.h
miniperlmain.o: miniperlmain.c
miniperlmain.o: op.h
miniperlmain.o: opcode.h
miniperlmain.o: perl.h
miniperlmain.o: pp.h
miniperlmain.o: proto.h
miniperlmain.o: regexp.h
miniperlmain.o: scope.h
miniperlmain.o: sv.h
miniperlmain.o: unixish.h
miniperlmain.o: util.h
perlmain.o: /usr/include/ctype.h
perlmain.o: /usr/include/dirent.h
perlmain.o: /usr/include/errno.h
perlmain.o: /usr/include/machine/param.h
perlmain.o: /usr/include/machine/setjmp.h
perlmain.o: /usr/include/netinet/in.h
perlmain.o: /usr/include/setjmp.h
perlmain.o: /usr/include/stdio.h
perlmain.o: /usr/include/sys/dirent.h
perlmain.o: /usr/include/sys/errno.h
perlmain.o: /usr/include/sys/filio.h
perlmain.o: /usr/include/sys/ioccom.h
perlmain.o: /usr/include/sys/ioctl.h
perlmain.o: /usr/include/sys/param.h
perlmain.o: /usr/include/sys/signal.h
perlmain.o: /usr/include/sys/sockio.h
perlmain.o: /usr/include/sys/stat.h
perlmain.o: /usr/include/sys/stdtypes.h
perlmain.o: /usr/include/sys/sysmacros.h
perlmain.o: /usr/include/sys/time.h
perlmain.o: /usr/include/sys/times.h
perlmain.o: /usr/include/sys/ttold.h
perlmain.o: /usr/include/sys/ttychars.h
perlmain.o: /usr/include/sys/ttycom.h
perlmain.o: /usr/include/sys/ttydev.h
perlmain.o: /usr/include/sys/types.h
perlmain.o: /usr/include/time.h
perlmain.o: /usr/include/varargs.h
perlmain.o: /usr/include/vm/faultcode.h
perlmain.o: INTERN.h
perlmain.o: av.h
perlmain.o: config.h
perlmain.o: cop.h
perlmain.o: cv.h
perlmain.o: embed.h
perlmain.o: form.h
perlmain.o: gv.h
perlmain.o: handy.h
perlmain.o: hv.h
perlmain.o: mg.h
perlmain.o: op.h
perlmain.o: opcode.h
perlmain.o: perl.h
perlmain.o: perlmain.c
perlmain.o: pp.h
perlmain.o: proto.h
perlmain.o: regexp.h
perlmain.o: scope.h
perlmain.o: sv.h
perlmain.o: unixish.h
perlmain.o: util.h
Makefile: Makefile.SH config.sh ; /bin/sh Makefile.SH
cflags: cflags.SH config.sh ; /bin/sh cflags.SH
embed_h: embed_h.SH config.sh ; /bin/sh embed_h.SH
makedepend: makedepend.SH config.sh ; /bin/sh makedepend.SH
makedir: makedir.SH config.sh ; /bin/sh makedir.SH
writemain: writemain.SH config.sh ; /bin/sh writemain.SH
# WARNING: Put nothing here or make depend will gobble it up!
