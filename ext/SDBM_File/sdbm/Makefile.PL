use ExtUtils::MakeMaker;

my $define = '-DSDBM -DDUFF';
$define .= ' -DWIN32 -DPERL_STATIC_SYMS' if ($^O eq 'MSWin32');

if ($^O eq 'VMS') {  # Old VAXC compiler can't handle Duff's device
    require Config;
    $define =~ s/\s+-DDUFF// if $Config::Config{'vms_cc_type'} eq 'vaxc';
}

WriteMakefile(
    NAME      => 'sdbm', # (doesn't matter what the name is here) oh yes it does
#    LINKTYPE  => 'static',
    DEFINE    => $define,
    INC       => '-I$(PERL_INC)', # force PERL_INC dir ahead of system -I's
    SKIP      => [qw(dynamic dynamic_lib dlsyms)],
    OBJECT    => '$(O_FILES)',
    clean     => {'FILES' => 'dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag'},
    H         => [qw(tune.h sdbm.h pair.h $(PERL_INC)/config.h)],
    C         => [qw(sdbm.c pair.c hash.c)]
);


package MY;
sub constants {
    my $self = shift;

    $self->{INST_STATIC} = 'libsdbm$(LIB_EXT)';

    return $self->SUPER::constants();
}

sub top_targets {
    my $self = shift;
    my $r = '
all :: static
	$(NOECHO) $(NOOP)

lint:
	lint -abchx $(LIBSRCS)

';
    $r .= '
# This is a workaround, the problem is that our old GNU make exports
# variables into the environment so $(MYEXTLIB) is set in here to this
# value which can not be built.
sdbm/libsdbm.a:
	$(NOECHO) $(NOOP)
' unless $^O eq 'VMS';

    return $r . $self->SUPER::top_targets;
}
