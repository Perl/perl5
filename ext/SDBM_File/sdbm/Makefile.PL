use ExtUtils::MakeMaker;
WriteMakefile(
    'LINKTYPE'  => 'static',
    'DEFINE'	=> '-DSDBM -DDUFF',
    'SKIP'	=> [qw(static static_lib dynamic dynamic_lib)],
    'clean'
	=> {'FILES' => 'dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag'},
    'H' => [qw(tune.h sdbm.h pair.h $(PERL_INC)/config.h)],
    'C' => [qw(sdbm.c pair.c hash.c)]
);


sub MY::top_targets {
	'
all :: static

static ::	libsdbm.a

config ::

libsdbm.a: $(O_FILES)
	ar cr libsdbm.a $(O_FILES)
	$(RANLIB) libsdbm.a

lint:
	lint -abchx $(LIBSRCS)
';
}
