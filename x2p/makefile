# $RCSfile: Makefile.SH,v 28453Revision: 4.1 28453Date: 92/08/07 18:29:07 $
#
# $Log:	Makefile.SH,v $
# Revision 4.1  92/08/07  18:29:07  lwall
# 
# Revision 4.0.1.3  92/06/08  16:11:32  lwall
# patch20: SH files didn't work well with symbolic links
# patch20: cray didn't give enough memory to /bin/sh
# patch20: makefiles now display new shift/reduce expectations
# 
# Revision 4.0.1.2  91/11/05  19:19:04  lwall
# patch11: random cleanup
# 
# Revision 4.0.1.1  91/06/07  12:12:14  lwall
# patch4: cflags now emits entire cc command except for the filename
# 
# Revision 4.0  91/03/20  01:57:03  lwall
# 4.0 baseline.
# 
# 

CC = cc
YACC = yacc
bin = /usr/local/bin
lib = /usr/local/lib
mansrc = /usr/local/man/man1
manext = 1
LDFLAGS = 
SMALL = 
LARGE =  
mallocsrc = malloc.c
mallocobj = malloc.o
shellflags = 

libs = -ldl -lm -lposix

CCCMD = `sh $(shellflags) cflags $@`

public = a2p s2p find2perl

private = 

manpages = a2p.man s2p.man

util =

sh = Makefile.SH makedepend.SH

h = EXTERN.h INTERN.h ../config.h handy.h hash.h a2p.h str.h util.h

c = hash.c $(mallocsrc) str.c util.c walk.c

obj = hash.o $(mallocobj) str.o util.o walk.o

lintflags = -phbvxac

addedbyconf = Makefile.old bsd eunice filexp loc pdp11 usg v7

# grrr
SHELL = /bin/sh

.c.o:
	$(CCCMD) $*.c

all: $(public) $(private) $(util)
	touch all

a2p: $(obj) a2p.o
	$(CC) $(LDFLAGS) $(obj) a2p.o $(libs) -o a2p

a2p.c: a2p.y
	@ echo Expect 231 shift/reduce conflicts...
	$(YACC) a2p.y
	mv y.tab.c a2p.c

a2p.o: a2p.c a2py.c a2p.h EXTERN.h util.h INTERN.h handy.h ../config.h str.h hash.h
	$(CCCMD) $(LARGE) a2p.c

install: a2p s2p
# won't work with csh
	export PATH || exit 1
	- mv $(bin)/a2p $(bin)/a2p.old 2>/dev/null
	- mv $(bin)/s2p $(bin)/s2p.old 2>/dev/null
	- if test `pwd` != $(bin); then cp $(public) $(bin); fi
	cd $(bin); \
for pub in $(public); do \
chmod +x `basename $$pub`; \
done
	- if test `pwd` != $(mansrc); then \
for page in $(manpages); do \
cp $$page $(mansrc)/`basename $$page .man`.$(manext); \
done; \
fi

clean:
	rm -f a2p *.o a2p.c

realclean: clean
	rm -f *.orig */*.orig core $(addedbyconf) a2p.c s2p find2perl all cflags

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

config.sh: ../config.sh
	rm -f config.sh
	ln ../config.sh .

malloc.c: ../malloc.c
	sed <../malloc.c >malloc.c \
	    -e 's/"perl.h"/"..\/perl.h"/' \
	    -e 's/my_exit/exit/'

# AUTOMATICALLY GENERATED MAKE DEPENDENCIES--PUT NOTHING BELOW THIS LINE
# If this runs make out of memory, delete /usr/include lines.
hash.o: ../config.h
hash.o: /usr/include/ctype.h
hash.o: /usr/include/stdio.h
hash.o: EXTERN.h
hash.o: a2p.h
hash.o: handy.h
hash.o: hash.c
hash.o: hash.h
hash.o: str.h
hash.o: util.h
malloc.o: ../av.h
malloc.o: ../config.h
malloc.o: ../cop.h
malloc.o: ../cv.h
malloc.o: ../embed.h
malloc.o: ../form.h
malloc.o: ../gv.h
malloc.o: ../handy.h
malloc.o: ../hv.h
malloc.o: ../mg.h
malloc.o: ../op.h
malloc.o: ../opcode.h
malloc.o: ../perl.h
malloc.o: ../pp.h
malloc.o: ../proto.h
malloc.o: ../regexp.h
malloc.o: ../scope.h
malloc.o: ../sv.h
malloc.o: ../unixish.h
malloc.o: ../util.h
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
malloc.o: malloc.c
str.o: ../config.h
str.o: /usr/include/ctype.h
str.o: /usr/include/stdio.h
str.o: EXTERN.h
str.o: a2p.h
str.o: handy.h
str.o: hash.h
str.o: str.c
str.o: str.h
str.o: util.h
util.o: ../config.h
util.o: /usr/include/ctype.h
util.o: /usr/include/stdio.h
util.o: EXTERN.h
util.o: INTERN.h
util.o: a2p.h
util.o: handy.h
util.o: hash.h
util.o: str.h
util.o: util.c
util.o: util.h
walk.o: ../config.h
walk.o: /usr/include/ctype.h
walk.o: /usr/include/stdio.h
walk.o: EXTERN.h
walk.o: a2p.h
walk.o: handy.h
walk.o: hash.h
walk.o: str.h
walk.o: util.h
walk.o: walk.c
Makefile: Makefile.SH config.sh ; /bin/sh Makefile.SH
makedepend: makedepend.SH config.sh ; /bin/sh makedepend.SH
# WARNING: Put nothing here or make depend will gobble it up!
