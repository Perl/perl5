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

CC = cc
bin = /usr/local/perl1.0.15/bin
lib = /usr/local/perl1.0.15/lib
mansrc = /usr/local/perl1.0.15/man/man1
manext = 1
CFLAGS = -I/usr/local/include -O
LDFLAGS =  -L/usr/local/lib
SMALL = 
LARGE =  
mallocsrc = 
mallocobj = 
SLN = ln -s

libs =   /usr/lib/libcrypt.a  -lm

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
# If this runs make out of memory, delete /usr/include lines.
arg.o: /usr/include/_G_config.h
arg.o: /usr/include/asm/ptrace.h
arg.o: /usr/include/asm/sigcontext.h
arg.o: /usr/include/bits/endian.h
arg.o: /usr/include/bits/pthreadtypes.h
arg.o: /usr/include/bits/sched.h
arg.o: /usr/include/bits/select.h
arg.o: /usr/include/bits/setjmp.h
arg.o: /usr/include/bits/sigaction.h
arg.o: /usr/include/bits/sigcontext.h
arg.o: /usr/include/bits/siginfo.h
arg.o: /usr/include/bits/signum.h
arg.o: /usr/include/bits/sigset.h
arg.o: /usr/include/bits/sigstack.h
arg.o: /usr/include/bits/sigthread.h
arg.o: /usr/include/bits/stat.h
arg.o: /usr/include/bits/stdio_lim.h
arg.o: /usr/include/bits/sys_errlist.h
arg.o: /usr/include/bits/time.h
arg.o: /usr/include/bits/types.h
arg.o: /usr/include/bits/wchar.h
arg.o: /usr/include/bits/wordsize.h
arg.o: /usr/include/ctype.h
arg.o: /usr/include/endian.h
arg.o: /usr/include/features.h
arg.o: /usr/include/gconv.h
arg.o: /usr/include/gnu/stubs.h
arg.o: /usr/include/libio.h
arg.o: /usr/include/setjmp.h
arg.o: /usr/include/signal.h
arg.o: /usr/include/stdio.h
arg.o: /usr/include/sys/cdefs.h
arg.o: /usr/include/sys/select.h
arg.o: /usr/include/sys/stat.h
arg.o: /usr/include/sys/sysmacros.h
arg.o: /usr/include/sys/times.h
arg.o: /usr/include/sys/types.h
arg.o: /usr/include/time.h
arg.o: /usr/include/wchar.h
arg.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
arg.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
arg.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
arg.o: EXTERN.h
arg.o: arg.c
arg.o: arg.h
arg.o: array.h
arg.o: cmd.h
arg.o: config.h
arg.o: form.h
arg.o: handy.h
arg.o: hash.h
arg.o: perl.h
arg.o: search.h
arg.o: spat.h
arg.o: stab.h
arg.o: str.h
arg.o: util.h
array.o: /usr/include/_G_config.h
array.o: /usr/include/bits/endian.h
array.o: /usr/include/bits/pthreadtypes.h
array.o: /usr/include/bits/sched.h
array.o: /usr/include/bits/select.h
array.o: /usr/include/bits/setjmp.h
array.o: /usr/include/bits/sigset.h
array.o: /usr/include/bits/stat.h
array.o: /usr/include/bits/stdio_lim.h
array.o: /usr/include/bits/sys_errlist.h
array.o: /usr/include/bits/time.h
array.o: /usr/include/bits/types.h
array.o: /usr/include/bits/wchar.h
array.o: /usr/include/ctype.h
array.o: /usr/include/endian.h
array.o: /usr/include/features.h
array.o: /usr/include/gconv.h
array.o: /usr/include/gnu/stubs.h
array.o: /usr/include/libio.h
array.o: /usr/include/setjmp.h
array.o: /usr/include/stdio.h
array.o: /usr/include/sys/cdefs.h
array.o: /usr/include/sys/select.h
array.o: /usr/include/sys/stat.h
array.o: /usr/include/sys/sysmacros.h
array.o: /usr/include/sys/times.h
array.o: /usr/include/sys/types.h
array.o: /usr/include/time.h
array.o: /usr/include/wchar.h
array.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
array.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
array.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
array.o: EXTERN.h
array.o: arg.h
array.o: array.c
array.o: array.h
array.o: cmd.h
array.o: config.h
array.o: form.h
array.o: handy.h
array.o: hash.h
array.o: perl.h
array.o: search.h
array.o: spat.h
array.o: stab.h
array.o: str.h
array.o: util.h
cmd.o: /usr/include/_G_config.h
cmd.o: /usr/include/bits/endian.h
cmd.o: /usr/include/bits/pthreadtypes.h
cmd.o: /usr/include/bits/sched.h
cmd.o: /usr/include/bits/select.h
cmd.o: /usr/include/bits/setjmp.h
cmd.o: /usr/include/bits/sigset.h
cmd.o: /usr/include/bits/stat.h
cmd.o: /usr/include/bits/stdio_lim.h
cmd.o: /usr/include/bits/sys_errlist.h
cmd.o: /usr/include/bits/time.h
cmd.o: /usr/include/bits/types.h
cmd.o: /usr/include/bits/wchar.h
cmd.o: /usr/include/ctype.h
cmd.o: /usr/include/endian.h
cmd.o: /usr/include/features.h
cmd.o: /usr/include/gconv.h
cmd.o: /usr/include/gnu/stubs.h
cmd.o: /usr/include/libio.h
cmd.o: /usr/include/setjmp.h
cmd.o: /usr/include/stdio.h
cmd.o: /usr/include/sys/cdefs.h
cmd.o: /usr/include/sys/select.h
cmd.o: /usr/include/sys/stat.h
cmd.o: /usr/include/sys/sysmacros.h
cmd.o: /usr/include/sys/times.h
cmd.o: /usr/include/sys/types.h
cmd.o: /usr/include/time.h
cmd.o: /usr/include/wchar.h
cmd.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
cmd.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
cmd.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
cmd.o: EXTERN.h
cmd.o: arg.h
cmd.o: array.h
cmd.o: cmd.c
cmd.o: cmd.h
cmd.o: config.h
cmd.o: form.h
cmd.o: handy.h
cmd.o: hash.h
cmd.o: perl.h
cmd.o: search.h
cmd.o: spat.h
cmd.o: stab.h
cmd.o: str.h
cmd.o: util.h
dump.o: /usr/include/_G_config.h
dump.o: /usr/include/bits/endian.h
dump.o: /usr/include/bits/pthreadtypes.h
dump.o: /usr/include/bits/sched.h
dump.o: /usr/include/bits/select.h
dump.o: /usr/include/bits/setjmp.h
dump.o: /usr/include/bits/sigset.h
dump.o: /usr/include/bits/stat.h
dump.o: /usr/include/bits/stdio_lim.h
dump.o: /usr/include/bits/sys_errlist.h
dump.o: /usr/include/bits/time.h
dump.o: /usr/include/bits/types.h
dump.o: /usr/include/bits/wchar.h
dump.o: /usr/include/ctype.h
dump.o: /usr/include/endian.h
dump.o: /usr/include/features.h
dump.o: /usr/include/gconv.h
dump.o: /usr/include/gnu/stubs.h
dump.o: /usr/include/libio.h
dump.o: /usr/include/setjmp.h
dump.o: /usr/include/stdio.h
dump.o: /usr/include/sys/cdefs.h
dump.o: /usr/include/sys/select.h
dump.o: /usr/include/sys/stat.h
dump.o: /usr/include/sys/sysmacros.h
dump.o: /usr/include/sys/times.h
dump.o: /usr/include/sys/types.h
dump.o: /usr/include/time.h
dump.o: /usr/include/wchar.h
dump.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
dump.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
dump.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
dump.o: EXTERN.h
dump.o: arg.h
dump.o: array.h
dump.o: cmd.h
dump.o: config.h
dump.o: dump.c
dump.o: form.h
dump.o: handy.h
dump.o: hash.h
dump.o: perl.h
dump.o: search.h
dump.o: spat.h
dump.o: stab.h
dump.o: str.h
dump.o: util.h
form.o: /usr/include/_G_config.h
form.o: /usr/include/bits/endian.h
form.o: /usr/include/bits/pthreadtypes.h
form.o: /usr/include/bits/sched.h
form.o: /usr/include/bits/select.h
form.o: /usr/include/bits/setjmp.h
form.o: /usr/include/bits/sigset.h
form.o: /usr/include/bits/stat.h
form.o: /usr/include/bits/stdio_lim.h
form.o: /usr/include/bits/sys_errlist.h
form.o: /usr/include/bits/time.h
form.o: /usr/include/bits/types.h
form.o: /usr/include/bits/wchar.h
form.o: /usr/include/ctype.h
form.o: /usr/include/endian.h
form.o: /usr/include/features.h
form.o: /usr/include/gconv.h
form.o: /usr/include/gnu/stubs.h
form.o: /usr/include/libio.h
form.o: /usr/include/setjmp.h
form.o: /usr/include/stdio.h
form.o: /usr/include/sys/cdefs.h
form.o: /usr/include/sys/select.h
form.o: /usr/include/sys/stat.h
form.o: /usr/include/sys/sysmacros.h
form.o: /usr/include/sys/times.h
form.o: /usr/include/sys/types.h
form.o: /usr/include/time.h
form.o: /usr/include/wchar.h
form.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
form.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
form.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
form.o: EXTERN.h
form.o: arg.h
form.o: array.h
form.o: cmd.h
form.o: config.h
form.o: form.c
form.o: form.h
form.o: handy.h
form.o: hash.h
form.o: perl.h
form.o: search.h
form.o: spat.h
form.o: stab.h
form.o: str.h
form.o: util.h
hash.o: /usr/include/_G_config.h
hash.o: /usr/include/bits/endian.h
hash.o: /usr/include/bits/pthreadtypes.h
hash.o: /usr/include/bits/sched.h
hash.o: /usr/include/bits/select.h
hash.o: /usr/include/bits/setjmp.h
hash.o: /usr/include/bits/sigset.h
hash.o: /usr/include/bits/stat.h
hash.o: /usr/include/bits/stdio_lim.h
hash.o: /usr/include/bits/sys_errlist.h
hash.o: /usr/include/bits/time.h
hash.o: /usr/include/bits/types.h
hash.o: /usr/include/bits/wchar.h
hash.o: /usr/include/ctype.h
hash.o: /usr/include/endian.h
hash.o: /usr/include/features.h
hash.o: /usr/include/gconv.h
hash.o: /usr/include/gnu/stubs.h
hash.o: /usr/include/libio.h
hash.o: /usr/include/setjmp.h
hash.o: /usr/include/stdio.h
hash.o: /usr/include/sys/cdefs.h
hash.o: /usr/include/sys/select.h
hash.o: /usr/include/sys/stat.h
hash.o: /usr/include/sys/sysmacros.h
hash.o: /usr/include/sys/times.h
hash.o: /usr/include/sys/types.h
hash.o: /usr/include/time.h
hash.o: /usr/include/wchar.h
hash.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
hash.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
hash.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
hash.o: EXTERN.h
hash.o: arg.h
hash.o: array.h
hash.o: cmd.h
hash.o: config.h
hash.o: form.h
hash.o: handy.h
hash.o: hash.c
hash.o: hash.h
hash.o: perl.h
hash.o: search.h
hash.o: spat.h
hash.o: stab.h
hash.o: str.h
hash.o: util.h
search.o: /usr/include/_G_config.h
search.o: /usr/include/bits/endian.h
search.o: /usr/include/bits/pthreadtypes.h
search.o: /usr/include/bits/sched.h
search.o: /usr/include/bits/select.h
search.o: /usr/include/bits/setjmp.h
search.o: /usr/include/bits/sigset.h
search.o: /usr/include/bits/stat.h
search.o: /usr/include/bits/stdio_lim.h
search.o: /usr/include/bits/sys_errlist.h
search.o: /usr/include/bits/time.h
search.o: /usr/include/bits/types.h
search.o: /usr/include/bits/wchar.h
search.o: /usr/include/ctype.h
search.o: /usr/include/endian.h
search.o: /usr/include/features.h
search.o: /usr/include/gconv.h
search.o: /usr/include/gnu/stubs.h
search.o: /usr/include/libio.h
search.o: /usr/include/setjmp.h
search.o: /usr/include/stdio.h
search.o: /usr/include/sys/cdefs.h
search.o: /usr/include/sys/select.h
search.o: /usr/include/sys/stat.h
search.o: /usr/include/sys/sysmacros.h
search.o: /usr/include/sys/times.h
search.o: /usr/include/sys/types.h
search.o: /usr/include/time.h
search.o: /usr/include/wchar.h
search.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
search.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
search.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
search.o: EXTERN.h
search.o: INTERN.h
search.o: arg.h
search.o: array.h
search.o: cmd.h
search.o: config.h
search.o: form.h
search.o: handy.h
search.o: hash.h
search.o: perl.h
search.o: search.c
search.o: search.h
search.o: spat.h
search.o: stab.h
search.o: str.h
search.o: util.h
stab.o: /usr/include/_G_config.h
stab.o: /usr/include/asm/ptrace.h
stab.o: /usr/include/asm/sigcontext.h
stab.o: /usr/include/bits/endian.h
stab.o: /usr/include/bits/pthreadtypes.h
stab.o: /usr/include/bits/sched.h
stab.o: /usr/include/bits/select.h
stab.o: /usr/include/bits/setjmp.h
stab.o: /usr/include/bits/sigaction.h
stab.o: /usr/include/bits/sigcontext.h
stab.o: /usr/include/bits/siginfo.h
stab.o: /usr/include/bits/signum.h
stab.o: /usr/include/bits/sigset.h
stab.o: /usr/include/bits/sigstack.h
stab.o: /usr/include/bits/sigthread.h
stab.o: /usr/include/bits/stat.h
stab.o: /usr/include/bits/stdio_lim.h
stab.o: /usr/include/bits/sys_errlist.h
stab.o: /usr/include/bits/time.h
stab.o: /usr/include/bits/types.h
stab.o: /usr/include/bits/wchar.h
stab.o: /usr/include/bits/wordsize.h
stab.o: /usr/include/ctype.h
stab.o: /usr/include/endian.h
stab.o: /usr/include/features.h
stab.o: /usr/include/gconv.h
stab.o: /usr/include/gnu/stubs.h
stab.o: /usr/include/libio.h
stab.o: /usr/include/setjmp.h
stab.o: /usr/include/signal.h
stab.o: /usr/include/stdio.h
stab.o: /usr/include/sys/cdefs.h
stab.o: /usr/include/sys/select.h
stab.o: /usr/include/sys/stat.h
stab.o: /usr/include/sys/sysmacros.h
stab.o: /usr/include/sys/times.h
stab.o: /usr/include/sys/types.h
stab.o: /usr/include/time.h
stab.o: /usr/include/wchar.h
stab.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
stab.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
stab.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
stab.o: EXTERN.h
stab.o: arg.h
stab.o: array.h
stab.o: cmd.h
stab.o: config.h
stab.o: form.h
stab.o: handy.h
stab.o: hash.h
stab.o: perl.h
stab.o: search.h
stab.o: spat.h
stab.o: stab.c
stab.o: stab.h
stab.o: str.h
stab.o: util.h
str.o: /usr/include/_G_config.h
str.o: /usr/include/bits/endian.h
str.o: /usr/include/bits/pthreadtypes.h
str.o: /usr/include/bits/sched.h
str.o: /usr/include/bits/select.h
str.o: /usr/include/bits/setjmp.h
str.o: /usr/include/bits/sigset.h
str.o: /usr/include/bits/stat.h
str.o: /usr/include/bits/stdio_lim.h
str.o: /usr/include/bits/sys_errlist.h
str.o: /usr/include/bits/time.h
str.o: /usr/include/bits/types.h
str.o: /usr/include/bits/wchar.h
str.o: /usr/include/ctype.h
str.o: /usr/include/endian.h
str.o: /usr/include/features.h
str.o: /usr/include/gconv.h
str.o: /usr/include/gnu/stubs.h
str.o: /usr/include/libio.h
str.o: /usr/include/setjmp.h
str.o: /usr/include/stdio.h
str.o: /usr/include/sys/cdefs.h
str.o: /usr/include/sys/select.h
str.o: /usr/include/sys/stat.h
str.o: /usr/include/sys/sysmacros.h
str.o: /usr/include/sys/times.h
str.o: /usr/include/sys/types.h
str.o: /usr/include/time.h
str.o: /usr/include/wchar.h
str.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
str.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
str.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
str.o: EXTERN.h
str.o: arg.h
str.o: array.h
str.o: cmd.h
str.o: config.h
str.o: form.h
str.o: handy.h
str.o: hash.h
str.o: perl.h
str.o: search.h
str.o: spat.h
str.o: stab.h
str.o: str.c
str.o: str.h
str.o: util.h
util.o: /usr/include/_G_config.h
util.o: /usr/include/bits/endian.h
util.o: /usr/include/bits/pthreadtypes.h
util.o: /usr/include/bits/sched.h
util.o: /usr/include/bits/select.h
util.o: /usr/include/bits/setjmp.h
util.o: /usr/include/bits/sigset.h
util.o: /usr/include/bits/stat.h
util.o: /usr/include/bits/stdio_lim.h
util.o: /usr/include/bits/sys_errlist.h
util.o: /usr/include/bits/time.h
util.o: /usr/include/bits/types.h
util.o: /usr/include/bits/wchar.h
util.o: /usr/include/ctype.h
util.o: /usr/include/endian.h
util.o: /usr/include/features.h
util.o: /usr/include/gconv.h
util.o: /usr/include/gnu/stubs.h
util.o: /usr/include/libio.h
util.o: /usr/include/setjmp.h
util.o: /usr/include/stdio.h
util.o: /usr/include/sys/cdefs.h
util.o: /usr/include/sys/select.h
util.o: /usr/include/sys/stat.h
util.o: /usr/include/sys/sysmacros.h
util.o: /usr/include/sys/times.h
util.o: /usr/include/sys/types.h
util.o: /usr/include/time.h
util.o: /usr/include/wchar.h
util.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stdarg.h
util.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/stddef.h
util.o: /usr/lib/gcc-lib/powerpc-linux/2.95.4/include/va-ppc.h
util.o: EXTERN.h
util.o: INTERN.h
util.o: arg.h
util.o: array.h
util.o: cmd.h
util.o: config.h
util.o: form.h
util.o: handy.h
util.o: hash.h
util.o: perl.h
util.o: search.h
util.o: spat.h
util.o: stab.h
util.o: str.h
util.o: util.c
util.o: util.h
version.o: patchlevel.h
version.o: version.c
Makefile: Makefile.SH config.sh ; /bin/sh Makefile.SH
makedepend: makedepend.SH config.sh ; /bin/sh makedepend.SH
# WARNING: Put nothing here or make depend will gobble it up!
