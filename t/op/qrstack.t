#!./perl

my $test = 1;
sub ok {
    my($ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    printf "%s %d%s\n", $ok ? "ok" : "not ok",
                        $test,
                        defined $name ? " - $name" : '';

    printf "# Failed test at line %d\n", (caller)[2] unless $ok;

    $test++;
    return $ok;
}

print "1..1\n";

ok(defined [(1)x127,qr//,1]->[127], "qr// should extend the stack properly");

