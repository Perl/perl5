package Checker;

@ISA = qw(Exporter);
@EXPORT = qw($CHECK okay_if note check filter_warnings);

$Checker::OUTPUT = 1;
$Checker::CHECK  = 0;

# Only lets through warnings that originate outside our toolkit:
sub filter_warnings {
    $SIG{'__WARN__'} = sub { 
	print STDERR $_[0] if ($_[0] !~ /^MIME:/);
    };
}

sub okay_if { 
    print( ($_[0] ? "ok\n" : "not ok\n")) 
}

sub note    { 
    print STDOUT "        ## ", @_, "\n" if $OUTPUT;
}

sub check   { 
    ++$CHECK;
    my ($ok, $note) = @_;
    $note = ($note ? ": $note" : '');
    my $stat = ($ok ? 'OK ' : 'ERR');
    printf STDOUT "        Test %2d$note\n", $CHECK  if $OUTPUT;
    print(($ok ? "ok $CHECK\n" : "not ok $CHECK\n"));
}
1;

