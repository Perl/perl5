package Thread;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(sync fast yield cond_signal cond_broadcast cond_wait
	       async);

#
# Methods
#

#
# Exported functions
#
sub async (&) {
    return new Thread $_[0];
}

bootstrap Thread;

my $cv;
foreach $cv (\&yield, \&sync, \&join, \&fast, \&DESTROY,
	    \&cond_wait, \&cond_signal, \&cond_broadcast) {
    fast($cv);
}

sync(\&new);	# not sure if this needs to be sync'd

1;
