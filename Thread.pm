package Thread;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(sync fast yield);

warn "about to bootstrap Thread\n";
bootstrap Thread;

my $cv;
foreach $cv (\&yield, \&sync, \&join, \&fast,
	    \&waituntil, \&signal, \&broadcast) {
    warn "Thread.pm: calling fast($cv)\n";
    fast($cv);
}

sync(\&new);	# not sure if this needs to be sync'd
sync(\&Thread::Cond::new);	# this needs syncing because of condpair_table

1;
