#!perl -w
use strict;
use ExtUtils::MakeMaker;

# Some MVS tools get confused by mro.o and ext/mro/mro.o, so we dance round
# their daftness by using a different leafname.

my $leaf = 'mro-xs';

WriteMakefile(
              NAME         => 'mro',
              VERSION_FROM => 'mro.pm',
              XS     => {'mro.xs' => "$leaf.c"},
              OBJECT => "$leaf\$(OBJ_EXT)",
             );

# Probably we need to disable this, else the default contradicts the rule below:
sub MY::xs_o {
    return '';
}

# MM_VMS writes direct the generated C file direct.
# Everything else uses MM_Unix, which writes a temporary file and then moves it
sub MY::xs_c {
    my $mv_clause = $^O eq 'VMS' ? '' : "$leaf.xsc && \$(MV) $leaf.xsc ";
    return "
$leaf.c : mro.xs
	\$(XSUBPPRUN) \$(XSPROTOARG) \$(XSUBPPARGS) \$(XSUBPP_EXTRA_ARGS) mro.xs > $mv_clause $leaf.c
"
}

# Need to stop the default processing of mro.xs, else we get duplicate rules:
sub MY::libscan {
    return grep {/mro\.pm/} $_[1];
}
