package sigtrap;

require Carp;

sub import {
    my $pack = shift;
    my @sigs = @_;
    @sigs or @sigs = qw(QUIT ILL TRAP ABRT EMT FPE BUS SEGV SYS PIPE TERM);
    foreach $sig (@sigs) {
	$SIG{$sig} = 'sigtrap::trap';
    }
}

sub trap {
    package DB;		# To get subroutine args.
    $SIG{'ABRT'} = DEFAULT;
    kill 'ABRT', $$ if $panic++;
    syswrite(STDERR, 'Caught a SIG', 12);
    syswrite(STDERR, $_[0], length($_[0]));
    syswrite(STDERR, ' at ', 4);
    ($pack,$file,$line) = caller;
    syswrite(STDERR, $file, length($file));
    syswrite(STDERR, ' line ', 6);
    syswrite(STDERR, $line, length($line));
    syswrite(STDERR, "\n", 1);

    # Now go for broke.
    for ($i = 1; ($p,$f,$l,$s,$h,$w) = caller($i); $i++) {
	@a = ();
	for $arg (@args) {
	    $_ = "$arg";
	    s/'/\\'/g;
	    s/([^\0]*)/'$1'/
		unless /^(?: -?[\d.]+ | \*[\w:]* )$/x;
	    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
	    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
	    push(@a, $_);
	}
	$w = $w ? '@ = ' : '$ = ';
	$a = $h ? '(' . join(', ', @a) . ')' : '';
	$mess = "$w$s$a called from $f line $l\n";
	syswrite(STDERR, $mess, length($mess));
    }
    kill 'ABRT', $$;
}

1;
