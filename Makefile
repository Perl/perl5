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
$(obj) hv.o:
	@ echo "You haven't done a "'"make depend" yet!'; exit 1
makedepend: makedepend.SH
	/bin/sh $(shellflags) makedepend.SH

