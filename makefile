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

CC = cc
YACC = /bin/yacc
bin = /usr/local/bin
scriptdir = /usr/local/bin
privlib = /usr/local/lib/perl
mansrc = /usr/man/manl
manext = l
LDFLAGS = 
CLDFLAGS = 
SMALL = 
LARGE =  
mallocsrc = malloc.c
mallocobj = malloc.o
SLN = ln -s
RMS = rm -f

libs = -ldbm -lm -lposix 

public = perl

shellflags = 

# To use an alternate make, set  in config.sh.
MAKE = make


CCCMD = `sh $(shellflags) cflags $@`

private = 

scripts = h2ph

manpages = perl.man h2ph.man

util =

sh = Makefile.SH makedepend.SH h2ph.SH

h1 = EXTERN.h INTERN.h av.h cop.h config.h embed.h form.h handy.h
h2 = hv.h op.h opcode.h perl.h regcomp.h regexp.h gv.h sv.h util.h

h = $(h1) $(h2)

c1 = av.c cop.c cons.c consop.c doop.c doio.c dolist.c
c2 = eval.c hv.c main.c $(mallocsrc) perl.c pp.c regcomp.c regexec.c
c3 = gv.c sv.c toke.c util.c usersub.c

c = $(c1) $(c2) $(c3)

s1 = av.c cop.c cons.c consop.c doop.c doio.c dolist.c
s2 = eval.c hv.c main.c perl.c pp.c regcomp.c regexec.c
s3 = gv.c sv.c toke.c util.c usersub.c perly.c

saber = $(s1) $(s2) $(s3)

obj1 = av.o scope.o op.o doop.o doio.o dolist.o dump.o
obj2 = $(mallocobj) mg.o pp.o regcomp.o regexec.o
obj3 = gv.o sv.o toke.o util.o deb.o run.o

obj = $(obj1) $(obj2) $(obj3)

tobj1 = tav.o tcop.o tcons.o tconsop.o tdoop.o tdoio.o tdolist.o tdump.o
tobj2 = teval.o thv.o $(mallocobj) tpp.o tregcomp.o tregexec.o
tobj3 = tgv.o tsv.o ttoke.o tutil.o

tobj = $(tobj1) $(tobj2) $(tobj3)

lintflags = -hbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.c.o:
	$(CCCMD) $*.c


all: perl

#all: $(public) $(private) $(util) uperl.o $(scripts)
#	cd x2p; $(MAKE) all
#	touch all

# This is the standard version that contains no "taint" checks and is
# used for all scripts that aren't set-id or running under something set-id.
# The $& notation is tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.

perl: $& main.o perly.o perl.o $(obj) hv.o usersub.o
	$(CC) -Bstatic $(LARGE) $(CLDFLAGS) main.o perly.o perl.o $(obj) hv.o usersub.o $(libs) -o perl
	echo ""

libperl.rlb: libperl.a
	ranlib libperl.a
	touch libperl.rlb

libperl.a: $& perly.o perl.o $(obj) hv.o usersub.o
	ar rcuv libperl.a $(obj) hv.o perly.o usersub.o

# This version, if specified in Configure, does ONLY those scripts which need
# set-id emulation.  Suidperl must be setuid root.  It contains the "taint"
# checks as well as the special code to validate that the script in question
# has been invoked correctly.

suidperl: $& sperl.o tmain.o libtperl.rlb
	$(CC) $(LARGE) $(CLDFLAGS) sperl.o tmain.o libtperl.a $(libs) -o suidperl

# This version interprets scripts that are already set-id either via a wrapper
# or through the kernel allowing set-id scripts (bad idea).  Taintperl must
# NOT be setuid to root or anything else.  The only difference between it
# and normal perl is the presence of the "taint" checks.

taintperl: $& tmain.o libtperl.rlb
	$(CC) $(LARGE) $(CLDFLAGS) tmain.o libtperl.a $(libs) -o taintperl

libtperl.rlb: libtperl.a
	ranlib libtperl.a
	touch libtperl.rlb

libtperl.a: $& tperly.o tperl.o $(tobj) thv.o usersub.o
	ar rcuv libtperl.a $(tobj) thv.o tperly.o usersub.o tperl.o

# This command assumes that /usr/include/dbz.h and /usr/lib/dbz.o exist.

dbzperl: $& main.o zhv.o libperl.rlb
	$(CC) $(LARGE) $(CLDFLAGS) main.o zhv.o /usr/lib/dbz.o libperl.a $(libs) -o dbzperl

zhv.o: hv.c $(h)
	$(RMS) zhv.c
	$(SLN) hv.c zhv.c
	$(CCCMD) -DWANT_DBZ zhv.c
	$(RMS) zhv.c

uperl.o: $& $(obj) main.o hv.o perly.o
	-ld $(LARGE) $(LDFLAGS) -r $(obj) main.o hv.o perly.o -o uperl.o

saber: $(saber)
	# load $(saber)
	# load /lib/libm.a

# Replicating all this junk is yucky, but I don't see a portable way to fix it.

tperly.o: perly.c perly.h $(h)
	$(RMS) tperly.c
	$(SLN) perly.c tperly.c
	$(CCCMD) -DTAINT tperly.c
	$(RMS) tperly.c

tperl.o: perl.c perly.h patchlevel.h perl.h $(h)
	$(RMS) tperl.c
	$(SLN) perl.c tperl.c
	$(CCCMD) -DTAINT tperl.c
	$(RMS) tperl.c

sperl.o: perl.c perly.h patchlevel.h $(h)
	$(RMS) sperl.c
	$(SLN) perl.c sperl.c
	$(CCCMD) -DTAINT -DIAMSUID sperl.c
	$(RMS) sperl.c

tav.o: av.c $(h)
	$(RMS) tav.c
	$(SLN) av.c tav.c
	$(CCCMD) -DTAINT tav.c
	$(RMS) tav.c

tcop.o: cop.c $(h)
	$(RMS) tcop.c
	$(SLN) cop.c tcop.c
	$(CCCMD) -DTAINT tcop.c
	$(RMS) tcop.c

tcons.o: cons.c $(h) perly.h
	$(RMS) tcons.c
	$(SLN) cons.c tcons.c
	$(CCCMD) -DTAINT tcons.c
	$(RMS) tcons.c

tconsop.o: consop.c $(h)
	$(RMS) tconsop.c
	$(SLN) consop.c tconsop.c
	$(CCCMD) -DTAINT tconsop.c
	$(RMS) tconsop.c

tdoop.o: doop.c $(h)
	$(RMS) tdoop.c
	$(SLN) doop.c tdoop.c
	$(CCCMD) -DTAINT tdoop.c
	$(RMS) tdoop.c

tdoio.o: doio.c $(h)
	$(RMS) tdoio.c
	$(SLN) doio.c tdoio.c
	$(CCCMD) -DTAINT tdoio.c
	$(RMS) tdoio.c

tdolist.o: dolist.c $(h)
	$(RMS) tdolist.c
	$(SLN) dolist.c tdolist.c
	$(CCCMD) -DTAINT tdolist.c
	$(RMS) tdolist.c

tdump.o: dump.c $(h)
	$(RMS) tdump.c
	$(SLN) dump.c tdump.c
	$(CCCMD) -DTAINT tdump.c
	$(RMS) tdump.c

teval.o: eval.c $(h)
	$(RMS) teval.c
	$(SLN) eval.c teval.c
	$(CCCMD) -DTAINT teval.c
	$(RMS) teval.c

thv.o: hv.c $(h)
	$(RMS) thv.c
	$(SLN) hv.c thv.c
	$(CCCMD) -DTAINT thv.c
	$(RMS) thv.c

tmain.o: main.c $(h)
	$(RMS) tmain.c
	$(SLN) main.c tmain.c
	$(CCCMD) -DTAINT tmain.c
	$(RMS) tmain.c

tpp.o: pp.c $(h)
	$(RMS) tpp.c
	$(SLN) pp.c tpp.c
	$(CCCMD) -DTAINT tpp.c
	$(RMS) tpp.c

tregcomp.o: regcomp.c $(h)
	$(RMS) tregcomp.c
	$(SLN) regcomp.c tregcomp.c
	$(CCCMD) -DTAINT tregcomp.c
	$(RMS) tregcomp.c

tregexec.o: regexec.c $(h)
	$(RMS) tregexec.c
	$(SLN) regexec.c tregexec.c
	$(CCCMD) -DTAINT tregexec.c
	$(RMS) tregexec.c

tgv.o: gv.c $(h)
	$(RMS) tgv.c
	$(SLN) gv.c tgv.c
	$(CCCMD) -DTAINT tgv.c
	$(RMS) tgv.c

tsv.o: sv.c $(h) perly.h
	$(RMS) tsv.c
	$(SLN) sv.c tsv.c
	$(CCCMD) -DTAINT tsv.c
	$(RMS) tsv.c

ttoke.o: toke.c $(h) perly.h
	$(RMS) ttoke.c
	$(SLN) toke.c ttoke.c
	$(CCCMD) -DTAINT ttoke.c
	$(RMS) ttoke.c

tutil.o: util.c $(h)
	$(RMS) tutil.c
	$(SLN) util.c tutil.c
	$(CCCMD) -DTAINT tutil.c
	$(RMS) tutil.c

perly.h: perly.c
	@ echo Dummy dependency for dumb parallel make
	touch perly.h

embed.h: embed_h.SH global.var interp.var
	sh embed_h.SH

perly.c: perly.y perly.fixer
	@ \
case "$(YACC)" in \
    *bison*) echo 'Expect' 25 shift/reduce and 53 reduce/reduce conflicts;; \
    *) echo 'Expect' 27 shift/reduce and 51 reduce/reduce conflicts;; \
esac
	$(YACC) -d perly.y
	sh $(shellflags) ./perly.fixer y.tab.c perly.c
	mv y.tab.h perly.h
	echo 'extern YYSTYPE yylval;' >>perly.h

perly.o: perly.c perly.h $(h)
	$(CCCMD) perly.c

install: all
	./perl installperl

clean:
	rm -f *.o all perl taintperl suidperl perly.c
	cd x2p; $(MAKE) clean

realclean: clean
	cd x2p; $(MAKE) realclean
	rm -f *.orig */*.orig *~ */*~ core $(addedbyconf) h2ph h2ph.man
	rm -f perly.c perly.h t/perl Makefile config.h makedepend makedir
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
av.o: 
av.o: /usr/ucbinclude/ctype.h
av.o: /usr/ucbinclude/dirent.h
av.o: /usr/ucbinclude/errno.h
av.o: /usr/ucbinclude/machine/param.h
av.o: /usr/ucbinclude/machine/setjmp.h
av.o: /usr/ucbinclude/ndbm.h
av.o: /usr/ucbinclude/netinet/in.h
av.o: /usr/ucbinclude/setjmp.h
av.o: /usr/ucbinclude/stdio.h
av.o: /usr/ucbinclude/sys/dirent.h
av.o: /usr/ucbinclude/sys/errno.h
av.o: /usr/ucbinclude/sys/filio.h
av.o: /usr/ucbinclude/sys/ioccom.h
av.o: /usr/ucbinclude/sys/ioctl.h
av.o: /usr/ucbinclude/sys/param.h
av.o: /usr/ucbinclude/sys/signal.h
av.o: /usr/ucbinclude/sys/sockio.h
av.o: /usr/ucbinclude/sys/stat.h
av.o: /usr/ucbinclude/sys/stdtypes.h
av.o: /usr/ucbinclude/sys/sysmacros.h
av.o: /usr/ucbinclude/sys/time.h
av.o: /usr/ucbinclude/sys/times.h
av.o: /usr/ucbinclude/sys/ttold.h
av.o: /usr/ucbinclude/sys/ttychars.h
av.o: /usr/ucbinclude/sys/ttycom.h
av.o: /usr/ucbinclude/sys/ttydev.h
av.o: /usr/ucbinclude/sys/types.h
av.o: /usr/ucbinclude/time.h
av.o: /usr/ucbinclude/vm/faultcode.h
av.o: EXTERN.h
av.o: av.c
av.o: av.h
av.o: config.h
av.o: cop.h
av.o: embed.h
av.o: form.h
av.o: gv.h
av.o: handy.h
av.o: hv.h
av.o: op.h
av.o: opcode.h
av.o: perl.h
av.o: pp.h
av.o: proto.h
av.o: regexp.h
av.o: sv.h
av.o: unixish.h
av.o: util.h
cop.o: 
cop.o: /usr/ucbinclude/ctype.h
cop.o: /usr/ucbinclude/dirent.h
cop.o: /usr/ucbinclude/errno.h
cop.o: /usr/ucbinclude/machine/param.h
cop.o: /usr/ucbinclude/machine/setjmp.h
cop.o: /usr/ucbinclude/ndbm.h
cop.o: /usr/ucbinclude/netinet/in.h
cop.o: /usr/ucbinclude/setjmp.h
cop.o: /usr/ucbinclude/stdio.h
cop.o: /usr/ucbinclude/sys/dirent.h
cop.o: /usr/ucbinclude/sys/errno.h
cop.o: /usr/ucbinclude/sys/filio.h
cop.o: /usr/ucbinclude/sys/ioccom.h
cop.o: /usr/ucbinclude/sys/ioctl.h
cop.o: /usr/ucbinclude/sys/param.h
cop.o: /usr/ucbinclude/sys/signal.h
cop.o: /usr/ucbinclude/sys/sockio.h
cop.o: /usr/ucbinclude/sys/stat.h
cop.o: /usr/ucbinclude/sys/stdtypes.h
cop.o: /usr/ucbinclude/sys/sysmacros.h
cop.o: /usr/ucbinclude/sys/time.h
cop.o: /usr/ucbinclude/sys/times.h
cop.o: /usr/ucbinclude/sys/ttold.h
cop.o: /usr/ucbinclude/sys/ttychars.h
cop.o: /usr/ucbinclude/sys/ttycom.h
cop.o: /usr/ucbinclude/sys/ttydev.h
cop.o: /usr/ucbinclude/sys/types.h
cop.o: /usr/ucbinclude/time.h
cop.o: /usr/ucbinclude/varargs.h
cop.o: /usr/ucbinclude/vm/faultcode.h
cop.o: EXTERN.h
cop.o: av.h
cop.o: config.h
cop.o: cop.c
cop.o: cop.h
cop.o: embed.h
cop.o: form.h
cop.o: gv.h
cop.o: handy.h
cop.o: hv.h
cop.o: op.h
cop.o: opcode.h
cop.o: perl.h
cop.o: pp.h
cop.o: proto.h
cop.o: regexp.h
cop.o: sv.h
cop.o: unixish.h
cop.o: util.h
cons.o: 
cons.o: /usr/ucbinclude/ctype.h
cons.o: /usr/ucbinclude/dirent.h
cons.o: /usr/ucbinclude/errno.h
cons.o: /usr/ucbinclude/machine/param.h
cons.o: /usr/ucbinclude/machine/setjmp.h
cons.o: /usr/ucbinclude/ndbm.h
cons.o: /usr/ucbinclude/netinet/in.h
cons.o: /usr/ucbinclude/setjmp.h
cons.o: /usr/ucbinclude/stdio.h
cons.o: /usr/ucbinclude/sys/dirent.h
cons.o: /usr/ucbinclude/sys/errno.h
cons.o: /usr/ucbinclude/sys/filio.h
cons.o: /usr/ucbinclude/sys/ioccom.h
cons.o: /usr/ucbinclude/sys/ioctl.h
cons.o: /usr/ucbinclude/sys/param.h
cons.o: /usr/ucbinclude/sys/signal.h
cons.o: /usr/ucbinclude/sys/sockio.h
cons.o: /usr/ucbinclude/sys/stat.h
cons.o: /usr/ucbinclude/sys/stdtypes.h
cons.o: /usr/ucbinclude/sys/sysmacros.h
cons.o: /usr/ucbinclude/sys/time.h
cons.o: /usr/ucbinclude/sys/times.h
cons.o: /usr/ucbinclude/sys/ttold.h
cons.o: /usr/ucbinclude/sys/ttychars.h
cons.o: /usr/ucbinclude/sys/ttycom.h
cons.o: /usr/ucbinclude/sys/ttydev.h
cons.o: /usr/ucbinclude/sys/types.h
cons.o: /usr/ucbinclude/time.h
cons.o: /usr/ucbinclude/vm/faultcode.h
cons.o: EXTERN.h
cons.o: av.h
cons.o: config.h
cons.o: cons.c
cons.o: cop.h
cons.o: embed.h
cons.o: form.h
cons.o: gv.h
cons.o: handy.h
cons.o: hv.h
cons.o: op.h
cons.o: opcode.h
cons.o: perl.h
cons.o: perly.h
cons.o: pp.h
cons.o: proto.h
cons.o: regexp.h
cons.o: sv.h
cons.o: unixish.h
cons.o: util.h
consop.o: 
consop.o: /usr/ucbinclude/ctype.h
consop.o: /usr/ucbinclude/dirent.h
consop.o: /usr/ucbinclude/errno.h
consop.o: /usr/ucbinclude/machine/param.h
consop.o: /usr/ucbinclude/machine/setjmp.h
consop.o: /usr/ucbinclude/ndbm.h
consop.o: /usr/ucbinclude/netinet/in.h
consop.o: /usr/ucbinclude/setjmp.h
consop.o: /usr/ucbinclude/stdio.h
consop.o: /usr/ucbinclude/sys/dirent.h
consop.o: /usr/ucbinclude/sys/errno.h
consop.o: /usr/ucbinclude/sys/filio.h
consop.o: /usr/ucbinclude/sys/ioccom.h
consop.o: /usr/ucbinclude/sys/ioctl.h
consop.o: /usr/ucbinclude/sys/param.h
consop.o: /usr/ucbinclude/sys/signal.h
consop.o: /usr/ucbinclude/sys/sockio.h
consop.o: /usr/ucbinclude/sys/stat.h
consop.o: /usr/ucbinclude/sys/stdtypes.h
consop.o: /usr/ucbinclude/sys/sysmacros.h
consop.o: /usr/ucbinclude/sys/time.h
consop.o: /usr/ucbinclude/sys/times.h
consop.o: /usr/ucbinclude/sys/ttold.h
consop.o: /usr/ucbinclude/sys/ttychars.h
consop.o: /usr/ucbinclude/sys/ttycom.h
consop.o: /usr/ucbinclude/sys/ttydev.h
consop.o: /usr/ucbinclude/sys/types.h
consop.o: /usr/ucbinclude/time.h
consop.o: /usr/ucbinclude/vm/faultcode.h
consop.o: EXTERN.h
consop.o: av.h
consop.o: config.h
consop.o: consop.c
consop.o: cop.h
consop.o: embed.h
consop.o: form.h
consop.o: gv.h
consop.o: handy.h
consop.o: hv.h
consop.o: op.h
consop.o: opcode.h
consop.o: perl.h
consop.o: pp.h
consop.o: proto.h
consop.o: regexp.h
consop.o: sv.h
consop.o: unixish.h
consop.o: util.h
scope.o: EXTERN.h
scope.o: av.h
scope.o: config.h
scope.o: cop.h
scope.o: doop.c
scope.o: embed.h
scope.o: form.h
scope.o: gv.h
scope.o: handy.h
scope.o: hv.h
scope.o: op.h
scope.o: opcode.h
scope.o: perl.h
scope.o: pp.h
scope.o: proto.h
scope.o: regexp.h
scope.o: sv.h
scope.o: unixish.h
scope.o: util.h
op.o: EXTERN.h
op.o: av.h
op.o: config.h
op.o: cop.h
op.o: doop.c
op.o: embed.h
op.o: form.h
op.o: gv.h
op.o: handy.h
op.o: hv.h
op.o: op.h
op.o: opcode.h
op.o: perl.h
op.o: pp.h
op.o: proto.h
op.o: regexp.h
op.o: sv.h
op.o: unixish.h
op.o: util.h
run.o: EXTERN.h
run.o: av.h
run.o: config.h
run.o: cop.h
run.o: doop.c
run.o: embed.h
run.o: form.h
run.o: gv.h
run.o: handy.h
run.o: hv.h
run.o: op.h
run.o: opcode.h
run.o: perl.h
run.o: pp.h
run.o: proto.h
run.o: regexp.h
run.o: sv.h
run.o: unixish.h
run.o: util.h
deb.o: EXTERN.h
deb.o: av.h
deb.o: config.h
deb.o: cop.h
deb.o: doop.c
deb.o: embed.h
deb.o: form.h
deb.o: gv.h
deb.o: handy.h
deb.o: hv.h
deb.o: op.h
deb.o: opcode.h
deb.o: perl.h
deb.o: pp.h
deb.o: proto.h
deb.o: regexp.h
deb.o: sv.h
deb.o: unixish.h
deb.o: util.h
doop.o: 
doop.o: /usr/ucbinclude/ctype.h
doop.o: /usr/ucbinclude/dirent.h
doop.o: /usr/ucbinclude/errno.h
doop.o: /usr/ucbinclude/machine/param.h
doop.o: /usr/ucbinclude/machine/setjmp.h
doop.o: /usr/ucbinclude/ndbm.h
doop.o: /usr/ucbinclude/netinet/in.h
doop.o: /usr/ucbinclude/setjmp.h
doop.o: /usr/ucbinclude/stdio.h
doop.o: /usr/ucbinclude/sys/dirent.h
doop.o: /usr/ucbinclude/sys/errno.h
doop.o: /usr/ucbinclude/sys/filio.h
doop.o: /usr/ucbinclude/sys/ioccom.h
doop.o: /usr/ucbinclude/sys/ioctl.h
doop.o: /usr/ucbinclude/sys/param.h
doop.o: /usr/ucbinclude/sys/signal.h
doop.o: /usr/ucbinclude/sys/sockio.h
doop.o: /usr/ucbinclude/sys/stat.h
doop.o: /usr/ucbinclude/sys/stdtypes.h
doop.o: /usr/ucbinclude/sys/sysmacros.h
doop.o: /usr/ucbinclude/sys/time.h
doop.o: /usr/ucbinclude/sys/times.h
doop.o: /usr/ucbinclude/sys/ttold.h
doop.o: /usr/ucbinclude/sys/ttychars.h
doop.o: /usr/ucbinclude/sys/ttycom.h
doop.o: /usr/ucbinclude/sys/ttydev.h
doop.o: /usr/ucbinclude/sys/types.h
doop.o: /usr/ucbinclude/time.h
doop.o: /usr/ucbinclude/vm/faultcode.h
doop.o: EXTERN.h
doop.o: av.h
doop.o: config.h
doop.o: cop.h
doop.o: doop.c
doop.o: embed.h
doop.o: form.h
doop.o: gv.h
doop.o: handy.h
doop.o: hv.h
doop.o: op.h
doop.o: opcode.h
doop.o: perl.h
doop.o: pp.h
doop.o: proto.h
doop.o: regexp.h
doop.o: sv.h
doop.o: unixish.h
doop.o: util.h
doio.o: 
doio.o: /usr/ucbinclude/ctype.h
doio.o: /usr/ucbinclude/debug/debug.h
doio.o: /usr/ucbinclude/dirent.h
doio.o: /usr/ucbinclude/errno.h
doio.o: /usr/ucbinclude/machine/mmu.h
doio.o: /usr/ucbinclude/machine/param.h
doio.o: /usr/ucbinclude/machine/setjmp.h
doio.o: /usr/ucbinclude/mon/obpdefs.h
doio.o: /usr/ucbinclude/mon/openprom.h
doio.o: /usr/ucbinclude/mon/sunromvec.h
doio.o: /usr/ucbinclude/ndbm.h
doio.o: /usr/ucbinclude/netinet/in.h
doio.o: /usr/ucbinclude/setjmp.h
doio.o: /usr/ucbinclude/stdio.h
doio.o: /usr/ucbinclude/sys/dirent.h
doio.o: /usr/ucbinclude/sys/errno.h
doio.o: /usr/ucbinclude/sys/fcntlcom.h
doio.o: /usr/ucbinclude/sys/file.h
doio.o: /usr/ucbinclude/sys/filio.h
doio.o: /usr/ucbinclude/sys/ioccom.h
doio.o: /usr/ucbinclude/sys/ioctl.h
doio.o: /usr/ucbinclude/sys/ipc.h
doio.o: /usr/ucbinclude/sys/msg.h
doio.o: /usr/ucbinclude/sys/param.h
doio.o: /usr/ucbinclude/sys/sem.h
doio.o: /usr/ucbinclude/sys/shm.h
doio.o: /usr/ucbinclude/sys/signal.h
doio.o: /usr/ucbinclude/sys/sockio.h
doio.o: /usr/ucbinclude/sys/stat.h
doio.o: /usr/ucbinclude/sys/stdtypes.h
doio.o: /usr/ucbinclude/sys/sysmacros.h
doio.o: /usr/ucbinclude/sys/time.h
doio.o: /usr/ucbinclude/sys/times.h
doio.o: /usr/ucbinclude/sys/ttold.h
doio.o: /usr/ucbinclude/sys/ttychars.h
doio.o: /usr/ucbinclude/sys/ttycom.h
doio.o: /usr/ucbinclude/sys/ttydev.h
doio.o: /usr/ucbinclude/sys/types.h
doio.o: /usr/ucbinclude/time.h
doio.o: /usr/ucbinclude/utime.h
doio.o: /usr/ucbinclude/vm/faultcode.h
doio.o: EXTERN.h
doio.o: av.h
doio.o: config.h
doio.o: cop.h
doio.o: doio.c
doio.o: embed.h
doio.o: form.h
doio.o: gv.h
doio.o: handy.h
doio.o: hv.h
doio.o: op.h
doio.o: opcode.h
doio.o: perl.h
doio.o: pp.h
doio.o: proto.h
doio.o: regexp.h
doio.o: sv.h
doio.o: unixish.h
doio.o: util.h
dolist.o: 
dolist.o: /usr/ucbinclude/ctype.h
dolist.o: /usr/ucbinclude/dirent.h
dolist.o: /usr/ucbinclude/errno.h
dolist.o: /usr/ucbinclude/machine/param.h
dolist.o: /usr/ucbinclude/machine/setjmp.h
dolist.o: /usr/ucbinclude/ndbm.h
dolist.o: /usr/ucbinclude/netinet/in.h
dolist.o: /usr/ucbinclude/setjmp.h
dolist.o: /usr/ucbinclude/stdio.h
dolist.o: /usr/ucbinclude/sys/dirent.h
dolist.o: /usr/ucbinclude/sys/errno.h
dolist.o: /usr/ucbinclude/sys/filio.h
dolist.o: /usr/ucbinclude/sys/ioccom.h
dolist.o: /usr/ucbinclude/sys/ioctl.h
dolist.o: /usr/ucbinclude/sys/param.h
dolist.o: /usr/ucbinclude/sys/signal.h
dolist.o: /usr/ucbinclude/sys/sockio.h
dolist.o: /usr/ucbinclude/sys/stat.h
dolist.o: /usr/ucbinclude/sys/stdtypes.h
dolist.o: /usr/ucbinclude/sys/sysmacros.h
dolist.o: /usr/ucbinclude/sys/time.h
dolist.o: /usr/ucbinclude/sys/times.h
dolist.o: /usr/ucbinclude/sys/ttold.h
dolist.o: /usr/ucbinclude/sys/ttychars.h
dolist.o: /usr/ucbinclude/sys/ttycom.h
dolist.o: /usr/ucbinclude/sys/ttydev.h
dolist.o: /usr/ucbinclude/sys/types.h
dolist.o: /usr/ucbinclude/time.h
dolist.o: /usr/ucbinclude/vm/faultcode.h
dolist.o: EXTERN.h
dolist.o: av.h
dolist.o: config.h
dolist.o: cop.h
dolist.o: dolist.c
dolist.o: embed.h
dolist.o: form.h
dolist.o: gv.h
dolist.o: handy.h
dolist.o: hv.h
dolist.o: op.h
dolist.o: opcode.h
dolist.o: perl.h
dolist.o: pp.h
dolist.o: proto.h
dolist.o: regexp.h
dolist.o: sv.h
dolist.o: unixish.h
dolist.o: util.h
dump.o: 
dump.o: /usr/ucbinclude/ctype.h
dump.o: /usr/ucbinclude/dirent.h
dump.o: /usr/ucbinclude/errno.h
dump.o: /usr/ucbinclude/machine/param.h
dump.o: /usr/ucbinclude/machine/setjmp.h
dump.o: /usr/ucbinclude/ndbm.h
dump.o: /usr/ucbinclude/netinet/in.h
dump.o: /usr/ucbinclude/setjmp.h
dump.o: /usr/ucbinclude/stdio.h
dump.o: /usr/ucbinclude/sys/dirent.h
dump.o: /usr/ucbinclude/sys/errno.h
dump.o: /usr/ucbinclude/sys/filio.h
dump.o: /usr/ucbinclude/sys/ioccom.h
dump.o: /usr/ucbinclude/sys/ioctl.h
dump.o: /usr/ucbinclude/sys/param.h
dump.o: /usr/ucbinclude/sys/signal.h
dump.o: /usr/ucbinclude/sys/sockio.h
dump.o: /usr/ucbinclude/sys/stat.h
dump.o: /usr/ucbinclude/sys/stdtypes.h
dump.o: /usr/ucbinclude/sys/sysmacros.h
dump.o: /usr/ucbinclude/sys/time.h
dump.o: /usr/ucbinclude/sys/times.h
dump.o: /usr/ucbinclude/sys/ttold.h
dump.o: /usr/ucbinclude/sys/ttychars.h
dump.o: /usr/ucbinclude/sys/ttycom.h
dump.o: /usr/ucbinclude/sys/ttydev.h
dump.o: /usr/ucbinclude/sys/types.h
dump.o: /usr/ucbinclude/time.h
dump.o: /usr/ucbinclude/vm/faultcode.h
dump.o: EXTERN.h
dump.o: av.h
dump.o: config.h
dump.o: cop.h
dump.o: dump.c
dump.o: embed.h
dump.o: form.h
dump.o: gv.h
dump.o: handy.h
dump.o: hv.h
dump.o: op.h
dump.o: opcode.h
dump.o: perl.h
dump.o: pp.h
dump.o: proto.h
dump.o: regexp.h
dump.o: sv.h
dump.o: unixish.h
dump.o: util.h
eval.o: 
eval.o: /usr/ucbinclude/ctype.h
eval.o: /usr/ucbinclude/dirent.h
eval.o: /usr/ucbinclude/errno.h
eval.o: /usr/ucbinclude/machine/param.h
eval.o: /usr/ucbinclude/machine/setjmp.h
eval.o: /usr/ucbinclude/ndbm.h
eval.o: /usr/ucbinclude/netinet/in.h
eval.o: /usr/ucbinclude/setjmp.h
eval.o: /usr/ucbinclude/stdio.h
eval.o: /usr/ucbinclude/sys/dirent.h
eval.o: /usr/ucbinclude/sys/errno.h
eval.o: /usr/ucbinclude/sys/fcntlcom.h
eval.o: /usr/ucbinclude/sys/file.h
eval.o: /usr/ucbinclude/sys/filio.h
eval.o: /usr/ucbinclude/sys/ioccom.h
eval.o: /usr/ucbinclude/sys/ioctl.h
eval.o: /usr/ucbinclude/sys/param.h
eval.o: /usr/ucbinclude/sys/signal.h
eval.o: /usr/ucbinclude/sys/sockio.h
eval.o: /usr/ucbinclude/sys/stat.h
eval.o: /usr/ucbinclude/sys/stdtypes.h
eval.o: /usr/ucbinclude/sys/sysmacros.h
eval.o: /usr/ucbinclude/sys/time.h
eval.o: /usr/ucbinclude/sys/times.h
eval.o: /usr/ucbinclude/sys/ttold.h
eval.o: /usr/ucbinclude/sys/ttychars.h
eval.o: /usr/ucbinclude/sys/ttycom.h
eval.o: /usr/ucbinclude/sys/ttydev.h
eval.o: /usr/ucbinclude/sys/types.h
eval.o: /usr/ucbinclude/time.h
eval.o: /usr/ucbinclude/vfork.h
eval.o: /usr/ucbinclude/vm/faultcode.h
eval.o: EXTERN.h
eval.o: av.h
eval.o: config.h
eval.o: cop.h
eval.o: embed.h
eval.o: eval.c
eval.o: form.h
eval.o: gv.h
eval.o: handy.h
eval.o: hv.h
eval.o: op.h
eval.o: opcode.h
eval.o: perl.h
eval.o: pp.h
eval.o: proto.h
eval.o: regexp.h
eval.o: sv.h
eval.o: unixish.h
eval.o: util.h
hv.o: 
hv.o: /usr/ucbinclude/ctype.h
hv.o: /usr/ucbinclude/dirent.h
hv.o: /usr/ucbinclude/errno.h
hv.o: /usr/ucbinclude/machine/param.h
hv.o: /usr/ucbinclude/machine/setjmp.h
hv.o: /usr/ucbinclude/ndbm.h
hv.o: /usr/ucbinclude/netinet/in.h
hv.o: /usr/ucbinclude/setjmp.h
hv.o: /usr/ucbinclude/stdio.h
hv.o: /usr/ucbinclude/sys/dirent.h
hv.o: /usr/ucbinclude/sys/errno.h
hv.o: /usr/ucbinclude/sys/fcntlcom.h
hv.o: /usr/ucbinclude/sys/file.h
hv.o: /usr/ucbinclude/sys/filio.h
hv.o: /usr/ucbinclude/sys/ioccom.h
hv.o: /usr/ucbinclude/sys/ioctl.h
hv.o: /usr/ucbinclude/sys/param.h
hv.o: /usr/ucbinclude/sys/signal.h
hv.o: /usr/ucbinclude/sys/sockio.h
hv.o: /usr/ucbinclude/sys/stat.h
hv.o: /usr/ucbinclude/sys/stdtypes.h
hv.o: /usr/ucbinclude/sys/sysmacros.h
hv.o: /usr/ucbinclude/sys/time.h
hv.o: /usr/ucbinclude/sys/times.h
hv.o: /usr/ucbinclude/sys/ttold.h
hv.o: /usr/ucbinclude/sys/ttychars.h
hv.o: /usr/ucbinclude/sys/ttycom.h
hv.o: /usr/ucbinclude/sys/ttydev.h
hv.o: /usr/ucbinclude/sys/types.h
hv.o: /usr/ucbinclude/time.h
hv.o: /usr/ucbinclude/vm/faultcode.h
hv.o: EXTERN.h
hv.o: av.h
hv.o: config.h
hv.o: cop.h
hv.o: embed.h
hv.o: form.h
hv.o: gv.h
hv.o: handy.h
hv.o: hv.c
hv.o: hv.h
hv.o: op.h
hv.o: opcode.h
hv.o: perl.h
hv.o: pp.h
hv.o: proto.h
hv.o: regexp.h
hv.o: sv.h
hv.o: unixish.h
hv.o: util.h
main.o: 
main.o: /usr/ucbinclude/ctype.h
main.o: /usr/ucbinclude/dirent.h
main.o: /usr/ucbinclude/errno.h
main.o: /usr/ucbinclude/machine/param.h
main.o: /usr/ucbinclude/machine/setjmp.h
main.o: /usr/ucbinclude/ndbm.h
main.o: /usr/ucbinclude/netinet/in.h
main.o: /usr/ucbinclude/setjmp.h
main.o: /usr/ucbinclude/stdio.h
main.o: /usr/ucbinclude/sys/dirent.h
main.o: /usr/ucbinclude/sys/errno.h
main.o: /usr/ucbinclude/sys/filio.h
main.o: /usr/ucbinclude/sys/ioccom.h
main.o: /usr/ucbinclude/sys/ioctl.h
main.o: /usr/ucbinclude/sys/param.h
main.o: /usr/ucbinclude/sys/signal.h
main.o: /usr/ucbinclude/sys/sockio.h
main.o: /usr/ucbinclude/sys/stat.h
main.o: /usr/ucbinclude/sys/stdtypes.h
main.o: /usr/ucbinclude/sys/sysmacros.h
main.o: /usr/ucbinclude/sys/time.h
main.o: /usr/ucbinclude/sys/times.h
main.o: /usr/ucbinclude/sys/ttold.h
main.o: /usr/ucbinclude/sys/ttychars.h
main.o: /usr/ucbinclude/sys/ttycom.h
main.o: /usr/ucbinclude/sys/ttydev.h
main.o: /usr/ucbinclude/sys/types.h
main.o: /usr/ucbinclude/time.h
main.o: /usr/ucbinclude/vm/faultcode.h
main.o: INTERN.h
main.o: av.h
main.o: config.h
main.o: cop.h
main.o: embed.h
main.o: form.h
main.o: gv.h
main.o: handy.h
main.o: hv.h
main.o: main.c
main.o: op.h
main.o: opcode.h
main.o: perl.h
main.o: pp.h
main.o: proto.h
main.o: regexp.h
main.o: sv.h
main.o: unixish.h
main.o: util.h
malloc.o: 
malloc.o: /usr/ucbinclude/ctype.h
malloc.o: /usr/ucbinclude/dirent.h
malloc.o: /usr/ucbinclude/errno.h
malloc.o: /usr/ucbinclude/machine/param.h
malloc.o: /usr/ucbinclude/machine/setjmp.h
malloc.o: /usr/ucbinclude/ndbm.h
malloc.o: /usr/ucbinclude/netinet/in.h
malloc.o: /usr/ucbinclude/setjmp.h
malloc.o: /usr/ucbinclude/stdio.h
malloc.o: /usr/ucbinclude/sys/dirent.h
malloc.o: /usr/ucbinclude/sys/errno.h
malloc.o: /usr/ucbinclude/sys/filio.h
malloc.o: /usr/ucbinclude/sys/ioccom.h
malloc.o: /usr/ucbinclude/sys/ioctl.h
malloc.o: /usr/ucbinclude/sys/param.h
malloc.o: /usr/ucbinclude/sys/signal.h
malloc.o: /usr/ucbinclude/sys/sockio.h
malloc.o: /usr/ucbinclude/sys/stat.h
malloc.o: /usr/ucbinclude/sys/stdtypes.h
malloc.o: /usr/ucbinclude/sys/sysmacros.h
malloc.o: /usr/ucbinclude/sys/time.h
malloc.o: /usr/ucbinclude/sys/times.h
malloc.o: /usr/ucbinclude/sys/ttold.h
malloc.o: /usr/ucbinclude/sys/ttychars.h
malloc.o: /usr/ucbinclude/sys/ttycom.h
malloc.o: /usr/ucbinclude/sys/ttydev.h
malloc.o: /usr/ucbinclude/sys/types.h
malloc.o: /usr/ucbinclude/time.h
malloc.o: /usr/ucbinclude/vm/faultcode.h
malloc.o: EXTERN.h
malloc.o: av.h
malloc.o: config.h
malloc.o: cop.h
malloc.o: embed.h
malloc.o: form.h
malloc.o: gv.h
malloc.o: handy.h
malloc.o: hv.h
malloc.o: malloc.c
malloc.o: op.h
malloc.o: opcode.h
malloc.o: perl.h
malloc.o: pp.h
malloc.o: proto.h
malloc.o: regexp.h
malloc.o: sv.h
malloc.o: unixish.h
malloc.o: util.h
perl.o: 
perl.o: /usr/ucbinclude/ctype.h
perl.o: /usr/ucbinclude/dirent.h
perl.o: /usr/ucbinclude/errno.h
perl.o: /usr/ucbinclude/machine/param.h
perl.o: /usr/ucbinclude/machine/setjmp.h
perl.o: /usr/ucbinclude/ndbm.h
perl.o: /usr/ucbinclude/netinet/in.h
perl.o: /usr/ucbinclude/setjmp.h
perl.o: /usr/ucbinclude/stdio.h
perl.o: /usr/ucbinclude/sys/dirent.h
perl.o: /usr/ucbinclude/sys/errno.h
perl.o: /usr/ucbinclude/sys/filio.h
perl.o: /usr/ucbinclude/sys/ioccom.h
perl.o: /usr/ucbinclude/sys/ioctl.h
perl.o: /usr/ucbinclude/sys/param.h
perl.o: /usr/ucbinclude/sys/signal.h
perl.o: /usr/ucbinclude/sys/sockio.h
perl.o: /usr/ucbinclude/sys/stat.h
perl.o: /usr/ucbinclude/sys/stdtypes.h
perl.o: /usr/ucbinclude/sys/sysmacros.h
perl.o: /usr/ucbinclude/sys/time.h
perl.o: /usr/ucbinclude/sys/times.h
perl.o: /usr/ucbinclude/sys/ttold.h
perl.o: /usr/ucbinclude/sys/ttychars.h
perl.o: /usr/ucbinclude/sys/ttycom.h
perl.o: /usr/ucbinclude/sys/ttydev.h
perl.o: /usr/ucbinclude/sys/types.h
perl.o: /usr/ucbinclude/time.h
perl.o: /usr/ucbinclude/vm/faultcode.h
perl.o: EXTERN.h
perl.o: av.h
perl.o: config.h
perl.o: cop.h
perl.o: embed.h
perl.o: form.h
perl.o: gv.h
perl.o: handy.h
perl.o: hv.h
perl.o: op.h
perl.o: opcode.h
perl.o: patchlevel.h
perl.o: perl.c
perl.o: perl.h
perl.o: perly.h
perl.o: pp.h
perl.o: proto.h
perl.o: regexp.h
perl.o: sv.h
perl.o: unixish.h
perl.o: util.h
pp.o: 
pp.o: /usr/ucbinclude/ctype.h
pp.o: /usr/ucbinclude/dirent.h
pp.o: /usr/ucbinclude/errno.h
pp.o: /usr/ucbinclude/grp.h
pp.o: /usr/ucbinclude/machine/param.h
pp.o: /usr/ucbinclude/machine/setjmp.h
pp.o: /usr/ucbinclude/ndbm.h
pp.o: /usr/ucbinclude/netdb.h
pp.o: /usr/ucbinclude/netinet/in.h
pp.o: /usr/ucbinclude/pwd.h
pp.o: /usr/ucbinclude/setjmp.h
pp.o: /usr/ucbinclude/stdio.h
pp.o: /usr/ucbinclude/sys/dirent.h
pp.o: /usr/ucbinclude/sys/errno.h
pp.o: /usr/ucbinclude/sys/fcntlcom.h
pp.o: /usr/ucbinclude/sys/file.h
pp.o: /usr/ucbinclude/sys/filio.h
pp.o: /usr/ucbinclude/sys/ioccom.h
pp.o: /usr/ucbinclude/sys/ioctl.h
pp.o: /usr/ucbinclude/sys/param.h
pp.o: /usr/ucbinclude/sys/signal.h
pp.o: /usr/ucbinclude/sys/socket.h
pp.o: /usr/ucbinclude/sys/sockio.h
pp.o: /usr/ucbinclude/sys/stat.h
pp.o: /usr/ucbinclude/sys/stdtypes.h
pp.o: /usr/ucbinclude/sys/sysmacros.h
pp.o: /usr/ucbinclude/sys/time.h
pp.o: /usr/ucbinclude/sys/times.h
pp.o: /usr/ucbinclude/sys/ttold.h
pp.o: /usr/ucbinclude/sys/ttychars.h
pp.o: /usr/ucbinclude/sys/ttycom.h
pp.o: /usr/ucbinclude/sys/ttydev.h
pp.o: /usr/ucbinclude/sys/types.h
pp.o: /usr/ucbinclude/time.h
pp.o: /usr/ucbinclude/utime.h
pp.o: /usr/ucbinclude/vm/faultcode.h
pp.o: EXTERN.h
pp.o: av.h
pp.o: config.h
pp.o: cop.h
pp.o: embed.h
pp.o: form.h
pp.o: gv.h
pp.o: handy.h
pp.o: hv.h
pp.o: op.h
pp.o: opcode.h
pp.o: perl.h
pp.o: pp.c
pp.o: pp.h
pp.o: proto.h
pp.o: regexp.h
pp.o: sv.h
pp.o: unixish.h
pp.o: util.h
regcomp.o: 
regcomp.o: /usr/ucbinclude/ctype.h
regcomp.o: /usr/ucbinclude/dirent.h
regcomp.o: /usr/ucbinclude/errno.h
regcomp.o: /usr/ucbinclude/machine/param.h
regcomp.o: /usr/ucbinclude/machine/setjmp.h
regcomp.o: /usr/ucbinclude/ndbm.h
regcomp.o: /usr/ucbinclude/netinet/in.h
regcomp.o: /usr/ucbinclude/setjmp.h
regcomp.o: /usr/ucbinclude/stdio.h
regcomp.o: /usr/ucbinclude/sys/dirent.h
regcomp.o: /usr/ucbinclude/sys/errno.h
regcomp.o: /usr/ucbinclude/sys/filio.h
regcomp.o: /usr/ucbinclude/sys/ioccom.h
regcomp.o: /usr/ucbinclude/sys/ioctl.h
regcomp.o: /usr/ucbinclude/sys/param.h
regcomp.o: /usr/ucbinclude/sys/signal.h
regcomp.o: /usr/ucbinclude/sys/sockio.h
regcomp.o: /usr/ucbinclude/sys/stat.h
regcomp.o: /usr/ucbinclude/sys/stdtypes.h
regcomp.o: /usr/ucbinclude/sys/sysmacros.h
regcomp.o: /usr/ucbinclude/sys/time.h
regcomp.o: /usr/ucbinclude/sys/times.h
regcomp.o: /usr/ucbinclude/sys/ttold.h
regcomp.o: /usr/ucbinclude/sys/ttychars.h
regcomp.o: /usr/ucbinclude/sys/ttycom.h
regcomp.o: /usr/ucbinclude/sys/ttydev.h
regcomp.o: /usr/ucbinclude/sys/types.h
regcomp.o: /usr/ucbinclude/time.h
regcomp.o: /usr/ucbinclude/vm/faultcode.h
regcomp.o: EXTERN.h
regcomp.o: INTERN.h
regcomp.o: av.h
regcomp.o: config.h
regcomp.o: cop.h
regcomp.o: embed.h
regcomp.o: form.h
regcomp.o: gv.h
regcomp.o: handy.h
regcomp.o: hv.h
regcomp.o: op.h
regcomp.o: opcode.h
regcomp.o: perl.h
regcomp.o: pp.h
regcomp.o: proto.h
regcomp.o: regcomp.c
regcomp.o: regcomp.h
regcomp.o: regexp.h
regcomp.o: sv.h
regcomp.o: unixish.h
regcomp.o: util.h
regexec.o: 
regexec.o: /usr/ucbinclude/ctype.h
regexec.o: /usr/ucbinclude/dirent.h
regexec.o: /usr/ucbinclude/errno.h
regexec.o: /usr/ucbinclude/machine/param.h
regexec.o: /usr/ucbinclude/machine/setjmp.h
regexec.o: /usr/ucbinclude/ndbm.h
regexec.o: /usr/ucbinclude/netinet/in.h
regexec.o: /usr/ucbinclude/setjmp.h
regexec.o: /usr/ucbinclude/stdio.h
regexec.o: /usr/ucbinclude/sys/dirent.h
regexec.o: /usr/ucbinclude/sys/errno.h
regexec.o: /usr/ucbinclude/sys/filio.h
regexec.o: /usr/ucbinclude/sys/ioccom.h
regexec.o: /usr/ucbinclude/sys/ioctl.h
regexec.o: /usr/ucbinclude/sys/param.h
regexec.o: /usr/ucbinclude/sys/signal.h
regexec.o: /usr/ucbinclude/sys/sockio.h
regexec.o: /usr/ucbinclude/sys/stat.h
regexec.o: /usr/ucbinclude/sys/stdtypes.h
regexec.o: /usr/ucbinclude/sys/sysmacros.h
regexec.o: /usr/ucbinclude/sys/time.h
regexec.o: /usr/ucbinclude/sys/times.h
regexec.o: /usr/ucbinclude/sys/ttold.h
regexec.o: /usr/ucbinclude/sys/ttychars.h
regexec.o: /usr/ucbinclude/sys/ttycom.h
regexec.o: /usr/ucbinclude/sys/ttydev.h
regexec.o: /usr/ucbinclude/sys/types.h
regexec.o: /usr/ucbinclude/time.h
regexec.o: /usr/ucbinclude/vm/faultcode.h
regexec.o: EXTERN.h
regexec.o: av.h
regexec.o: config.h
regexec.o: cop.h
regexec.o: embed.h
regexec.o: form.h
regexec.o: gv.h
regexec.o: handy.h
regexec.o: hv.h
regexec.o: op.h
regexec.o: opcode.h
regexec.o: perl.h
regexec.o: pp.h
regexec.o: proto.h
regexec.o: regcomp.h
regexec.o: regexec.c
regexec.o: regexp.h
regexec.o: sv.h
regexec.o: unixish.h
regexec.o: util.h
gv.o: 
gv.o: /usr/ucbinclude/ctype.h
gv.o: /usr/ucbinclude/dirent.h
gv.o: /usr/ucbinclude/errno.h
gv.o: /usr/ucbinclude/machine/param.h
gv.o: /usr/ucbinclude/machine/setjmp.h
gv.o: /usr/ucbinclude/ndbm.h
gv.o: /usr/ucbinclude/netinet/in.h
gv.o: /usr/ucbinclude/setjmp.h
gv.o: /usr/ucbinclude/stdio.h
gv.o: /usr/ucbinclude/sys/dirent.h
gv.o: /usr/ucbinclude/sys/errno.h
gv.o: /usr/ucbinclude/sys/filio.h
gv.o: /usr/ucbinclude/sys/ioccom.h
gv.o: /usr/ucbinclude/sys/ioctl.h
gv.o: /usr/ucbinclude/sys/param.h
gv.o: /usr/ucbinclude/sys/signal.h
gv.o: /usr/ucbinclude/sys/sockio.h
gv.o: /usr/ucbinclude/sys/stat.h
gv.o: /usr/ucbinclude/sys/stdtypes.h
gv.o: /usr/ucbinclude/sys/sysmacros.h
gv.o: /usr/ucbinclude/sys/time.h
gv.o: /usr/ucbinclude/sys/times.h
gv.o: /usr/ucbinclude/sys/ttold.h
gv.o: /usr/ucbinclude/sys/ttychars.h
gv.o: /usr/ucbinclude/sys/ttycom.h
gv.o: /usr/ucbinclude/sys/ttydev.h
gv.o: /usr/ucbinclude/sys/types.h
gv.o: /usr/ucbinclude/time.h
gv.o: /usr/ucbinclude/vm/faultcode.h
gv.o: EXTERN.h
gv.o: av.h
gv.o: config.h
gv.o: cop.h
gv.o: embed.h
gv.o: form.h
gv.o: gv.c
gv.o: gv.h
gv.o: handy.h
gv.o: hv.h
gv.o: op.h
gv.o: opcode.h
gv.o: perl.h
gv.o: pp.h
gv.o: proto.h
gv.o: regexp.h
gv.o: sv.h
gv.o: unixish.h
gv.o: util.h
sv.o: 
sv.o: /usr/ucbinclude/ctype.h
sv.o: /usr/ucbinclude/dirent.h
sv.o: /usr/ucbinclude/errno.h
sv.o: /usr/ucbinclude/machine/param.h
sv.o: /usr/ucbinclude/machine/setjmp.h
sv.o: /usr/ucbinclude/ndbm.h
sv.o: /usr/ucbinclude/netinet/in.h
sv.o: /usr/ucbinclude/setjmp.h
sv.o: /usr/ucbinclude/stdio.h
sv.o: /usr/ucbinclude/sys/dirent.h
sv.o: /usr/ucbinclude/sys/errno.h
sv.o: /usr/ucbinclude/sys/filio.h
sv.o: /usr/ucbinclude/sys/ioccom.h
sv.o: /usr/ucbinclude/sys/ioctl.h
sv.o: /usr/ucbinclude/sys/param.h
sv.o: /usr/ucbinclude/sys/signal.h
sv.o: /usr/ucbinclude/sys/sockio.h
sv.o: /usr/ucbinclude/sys/stat.h
sv.o: /usr/ucbinclude/sys/stdtypes.h
sv.o: /usr/ucbinclude/sys/sysmacros.h
sv.o: /usr/ucbinclude/sys/time.h
sv.o: /usr/ucbinclude/sys/times.h
sv.o: /usr/ucbinclude/sys/ttold.h
sv.o: /usr/ucbinclude/sys/ttychars.h
sv.o: /usr/ucbinclude/sys/ttycom.h
sv.o: /usr/ucbinclude/sys/ttydev.h
sv.o: /usr/ucbinclude/sys/types.h
sv.o: /usr/ucbinclude/time.h
sv.o: /usr/ucbinclude/vm/faultcode.h
sv.o: EXTERN.h
sv.o: av.h
sv.o: config.h
sv.o: cop.h
sv.o: embed.h
sv.o: form.h
sv.o: gv.h
sv.o: handy.h
sv.o: hv.h
sv.o: op.h
sv.o: opcode.h
sv.o: perl.h
sv.o: perly.h
sv.o: pp.h
sv.o: proto.h
sv.o: regexp.h
sv.o: sv.c
sv.o: sv.h
sv.o: unixish.h
sv.o: util.h
toke.o: 
toke.o: /usr/ucbinclude/ctype.h
toke.o: /usr/ucbinclude/dirent.h
toke.o: /usr/ucbinclude/errno.h
toke.o: /usr/ucbinclude/machine/param.h
toke.o: /usr/ucbinclude/machine/setjmp.h
toke.o: /usr/ucbinclude/ndbm.h
toke.o: /usr/ucbinclude/netinet/in.h
toke.o: /usr/ucbinclude/setjmp.h
toke.o: /usr/ucbinclude/stdio.h
toke.o: /usr/ucbinclude/sys/dirent.h
toke.o: /usr/ucbinclude/sys/errno.h
toke.o: /usr/ucbinclude/sys/fcntlcom.h
toke.o: /usr/ucbinclude/sys/file.h
toke.o: /usr/ucbinclude/sys/filio.h
toke.o: /usr/ucbinclude/sys/ioccom.h
toke.o: /usr/ucbinclude/sys/ioctl.h
toke.o: /usr/ucbinclude/sys/param.h
toke.o: /usr/ucbinclude/sys/signal.h
toke.o: /usr/ucbinclude/sys/sockio.h
toke.o: /usr/ucbinclude/sys/stat.h
toke.o: /usr/ucbinclude/sys/stdtypes.h
toke.o: /usr/ucbinclude/sys/sysmacros.h
toke.o: /usr/ucbinclude/sys/time.h
toke.o: /usr/ucbinclude/sys/times.h
toke.o: /usr/ucbinclude/sys/ttold.h
toke.o: /usr/ucbinclude/sys/ttychars.h
toke.o: /usr/ucbinclude/sys/ttycom.h
toke.o: /usr/ucbinclude/sys/ttydev.h
toke.o: /usr/ucbinclude/sys/types.h
toke.o: /usr/ucbinclude/time.h
toke.o: /usr/ucbinclude/vm/faultcode.h
toke.o: EXTERN.h
toke.o: av.h
toke.o: config.h
toke.o: cop.h
toke.o: embed.h
toke.o: form.h
toke.o: gv.h
toke.o: handy.h
toke.o: hv.h
toke.o: keywords.h
toke.o: op.h
toke.o: opcode.h
toke.o: perl.h
toke.o: perly.h
toke.o: pp.h
toke.o: proto.h
toke.o: regexp.h
toke.o: sv.h
toke.o: toke.c
toke.o: unixish.h
toke.o: util.h
util.o: 
util.o: /usr/ucbinclude/ctype.h
util.o: /usr/ucbinclude/dirent.h
util.o: /usr/ucbinclude/errno.h
util.o: /usr/ucbinclude/machine/param.h
util.o: /usr/ucbinclude/machine/setjmp.h
util.o: /usr/ucbinclude/ndbm.h
util.o: /usr/ucbinclude/netinet/in.h
util.o: /usr/ucbinclude/setjmp.h
util.o: /usr/ucbinclude/stdio.h
util.o: /usr/ucbinclude/sys/dirent.h
util.o: /usr/ucbinclude/sys/errno.h
util.o: /usr/ucbinclude/sys/fcntlcom.h
util.o: /usr/ucbinclude/sys/file.h
util.o: /usr/ucbinclude/sys/filio.h
util.o: /usr/ucbinclude/sys/ioccom.h
util.o: /usr/ucbinclude/sys/ioctl.h
util.o: /usr/ucbinclude/sys/param.h
util.o: /usr/ucbinclude/sys/signal.h
util.o: /usr/ucbinclude/sys/sockio.h
util.o: /usr/ucbinclude/sys/stat.h
util.o: /usr/ucbinclude/sys/stdtypes.h
util.o: /usr/ucbinclude/sys/sysmacros.h
util.o: /usr/ucbinclude/sys/time.h
util.o: /usr/ucbinclude/sys/times.h
util.o: /usr/ucbinclude/sys/ttold.h
util.o: /usr/ucbinclude/sys/ttychars.h
util.o: /usr/ucbinclude/sys/ttycom.h
util.o: /usr/ucbinclude/sys/ttydev.h
util.o: /usr/ucbinclude/sys/types.h
util.o: /usr/ucbinclude/time.h
util.o: /usr/ucbinclude/varargs.h
util.o: /usr/ucbinclude/vfork.h
util.o: /usr/ucbinclude/vm/faultcode.h
util.o: EXTERN.h
util.o: av.h
util.o: config.h
util.o: cop.h
util.o: embed.h
util.o: form.h
util.o: gv.h
util.o: handy.h
util.o: hv.h
util.o: op.h
util.o: opcode.h
util.o: perl.h
util.o: pp.h
util.o: proto.h
util.o: regexp.h
util.o: sv.h
util.o: unixish.h
util.o: util.c
util.o: util.h
usersub.o: 
usersub.o: /usr/ucbinclude/ctype.h
usersub.o: /usr/ucbinclude/dirent.h
usersub.o: /usr/ucbinclude/errno.h
usersub.o: /usr/ucbinclude/machine/param.h
usersub.o: /usr/ucbinclude/machine/setjmp.h
usersub.o: /usr/ucbinclude/ndbm.h
usersub.o: /usr/ucbinclude/netinet/in.h
usersub.o: /usr/ucbinclude/setjmp.h
usersub.o: /usr/ucbinclude/stdio.h
usersub.o: /usr/ucbinclude/sys/dirent.h
usersub.o: /usr/ucbinclude/sys/errno.h
usersub.o: /usr/ucbinclude/sys/filio.h
usersub.o: /usr/ucbinclude/sys/ioccom.h
usersub.o: /usr/ucbinclude/sys/ioctl.h
usersub.o: /usr/ucbinclude/sys/param.h
usersub.o: /usr/ucbinclude/sys/signal.h
usersub.o: /usr/ucbinclude/sys/sockio.h
usersub.o: /usr/ucbinclude/sys/stat.h
usersub.o: /usr/ucbinclude/sys/stdtypes.h
usersub.o: /usr/ucbinclude/sys/sysmacros.h
usersub.o: /usr/ucbinclude/sys/time.h
usersub.o: /usr/ucbinclude/sys/times.h
usersub.o: /usr/ucbinclude/sys/ttold.h
usersub.o: /usr/ucbinclude/sys/ttychars.h
usersub.o: /usr/ucbinclude/sys/ttycom.h
usersub.o: /usr/ucbinclude/sys/ttydev.h
usersub.o: /usr/ucbinclude/sys/types.h
usersub.o: /usr/ucbinclude/time.h
usersub.o: /usr/ucbinclude/vm/faultcode.h
usersub.o: EXTERN.h
usersub.o: av.h
usersub.o: config.h
usersub.o: cop.h
usersub.o: embed.h
usersub.o: form.h
usersub.o: gv.h
usersub.o: handy.h
usersub.o: hv.h
usersub.o: op.h
usersub.o: opcode.h
usersub.o: perl.h
usersub.o: pp.h
usersub.o: proto.h
usersub.o: regexp.h
usersub.o: sv.h
usersub.o: unixish.h
usersub.o: usersub.c
usersub.o: util.h
Makefile: Makefile.SH config.sh ; /bin/sh Makefile.SH
makedepend: makedepend.SH config.sh ; /bin/sh makedepend.SH
h2ph: h2ph.SH config.sh ; /bin/sh h2ph.SH
# WARNING: Put nothing here or make depend will gobble it up!
