
# perl
# - location of uperl.o and include files
PERL = ../perl-lib
# - libraries required by perl - from config.sh
PERL_LIBS = -ldbm -lm -lposix

UPERL	= $(PERL)/uperl4.035.o
UPERL	= ../sybperl/uperl2.o

DP_C	= \
	dlperl.c \
	usersub.c

DP_H	=


CC	= gcc-2.2.2
CPPFLAGS= -I$(PERL)
#CFLAGS	= -g

ALL	= \
	dlperl


all: $(ALL) tags

dlperl: $(UPERL) $(DP_C:.c=.o)
	$(LINK.c) -o dlperl $(UPERL) $(DP_C:.c=.o) \
		$(PERL_LIBS) \
		-ldl -lc.1.6
	ld-rules -clobber dlperl

dlperl.s: dlperl.c
	$(COMPILE.c) -S $(OUTPUT_OPTION) dlperl.c

tags:	$(DP_C) $(DP_H)
	ctags $(DP_C) $(DP_H)

lint:
	$(LINT.c) $(DP_C) $(LINT_LN)

clean:
	rm -f core *.o

clobber:	clean
	rm -f $(ALL) tags

install:

.KEEP_STATE:
