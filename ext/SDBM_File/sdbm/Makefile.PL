use ExtUtils::MakeMaker;

$define = '-DSDBM -DDUFF';
$define .= ' -DWIN32' if ($^O eq 'MSWin32');

if ($^O eq 'VMS') {  # Old VAXC compiler can't handle Duff's device
    require Config;
    $define =~ s/\s+-DDUFF// if $Config::Config{'vms_cc_type'} eq 'vaxc';
}

WriteMakefile(
    NAME      => 'sdbm', # (doesn't matter what the name is here) oh yes it does
#    LINKTYPE  => 'static',
    DEFINE    => $define,
    INC       => '-I$(PERL_INC)', # force PERL_INC dir ahead of system -I's
    INST_ARCHLIB => '.',
    SKIP      => [qw(dynamic dynamic_lib dlsyms)],
    OBJECT    => '$(O_FILES)',
    clean     => {'FILES' => 'dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag'},
    H         => [qw(tune.h sdbm.h pair.h $(PERL_INC)/config.h)],
    C         => [qw(sdbm.c pair.c hash.c)]
);

sub MY::post_constants {
'
INST_STATIC = libsdbm$(LIB_EXT)
'
}

sub MY::top_targets {
	'
all :: static
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)

lint:
	lint -abchx $(LIBSRCS)
';
}
