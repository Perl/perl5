use ExtUtils::MakeMaker;
WriteMakefile(
    'LINKTYPE'  => 'static',
    'DEFINE'	=> '-DSDBM -DDUFF',
    'SKIP'	=> [qw(static static_lib dynamic dynamic_lib)],
    'clean'
	=> {'FILES' => 'dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag'}
);


sub MY::top_targets {
	'
LIBOBJS = sdbm.o pair.o hash.o
LIBSRCS = sdbm.c pair.c hash.c
HDRS = tune.h sdbm.h pair.h

all :: static

static ::	libsdbm.a

libsdbm.a: $(LIBOBJS)
	ar cr libsdbm.a $(LIBOBJS)
	$(RANLIB) libsdbm.a

$(LIBOBJS): $(HDRS) $(PERL_INC)/config.h

config ::

lint:
	lint -abchx $(LIBSRCS)
';
}


sub MY::realclean {
	'
realclean :: clean
	rm -f Makefile
';
}


sub MY::postamble {
	'
sdbm.o : sdbm.c $(PERL_INC)/config.h sdbm.h tune.h pair.h 
hash.o : hash.c $(PERL_INC)/config.h sdbm.h 
pair.o : pair.c $(PERL_INC)/config.h sdbm.h tune.h pair.h 
';
}
