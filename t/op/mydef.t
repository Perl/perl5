#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..48\n";

my $test = 0;
sub ok ($$) {
    my ($ok, $name) = @_;
    ++$test;
    print $ok ? "ok $test - $name\n" : "not ok $test - $name\n";
}

$_ = 'global';
ok( $_ eq 'global', '$_ initial value' );
s/oba/abo/;
ok( $_ eq 'glabol', 's/// on global $_' );

{
    my $_ = 'local';
    ok( $_ eq 'local', 'my $_ initial value' );
    s/oca/aco/;
    ok( $_ eq 'lacol', 's/// on my $_' );
    /(..)/;
    ok( $1 eq 'la', '// on my $_' );
    ok( tr/c/d/ == 1, 'tr/// on my $_ counts correctly' );
    ok( $_ eq 'ladol', 'tr/// on my $_' );
    {
	my $_ = 'nested';
	ok( $_ eq 'nested', 'my $_ nested' );
	chop;
	ok( $_ eq 'neste', 'chop on my $_' );
    }
    {
	our $_;
	ok( $_ eq 'glabol', 'gains access to our global $_' );
    }
    ok( $_ eq 'ladol', 'my $_ restored' );
}
ok( $_ eq 'glabol', 'global $_ restored' );
s/abo/oba/;
ok( $_ eq 'global', 's/// on global $_ again' );
{
    my $_ = 11;
    our $_ = 22;
    ok( $_ eq 22, 'our $_ is seen explicitly' );
    chop;
    ok( $_ eq 2, '...default chop chops our $_' );
    /(.)/;
    ok( $1 eq 2, '...default match sees our $_' );
}

$_ = "global";
{
    for my $_ ("foo") {
	ok( $_ eq "foo", 'for my $_' );
	/(.)/;
	ok( $1 eq "f", '...m// in for my $_' );
	ok( our $_ eq 'global', '...our $_ inside for my $_' );
    }
    ok( $_ eq 'global', '...$_ restored outside for my $_' );
}
{
    for our $_ ("bar") {
	ok( $_ eq "bar", 'for our $_' );
	/(.)/;
	ok( $1 eq "b", '...m// in for our $_' );
    }
    ok( $_ eq 'global', '...our $_ restored outside for our $_' );
}

{
    my $buf = '';
    sub tmap1 { /(.)/; $buf .= $1 } # uses our $_
    my $_ = 'x';
    sub tmap2 { /(.)/; $buf .= $1 } # uses my $_
    map {
	tmap1();
	tmap2();
	ok( /^[67]\z/, 'local lexical $_ is seen in map' );
	{ ok( our $_ eq 'global', 'our $_ still visible' ); }
	ok( $_ == 6 || $_ == 7, 'local lexical $_ is still seen in map' );
    } 6, 7;
    ok( $buf eq 'gxgx', q/...map doesn't modify outer lexical $_/ );
    ok( $_ eq 'x', '...my $_ restored outside map' );
    ok( our $_ eq 'global', '...our $_ restored outside map' );
}
{
    my $buf = '';
    sub tgrep1 { /(.)/; $buf .= $1 }
    my $_ = 'y';
    sub tgrep2 { /(.)/; $buf .= $1 }
    grep {
	tgrep1();
	tgrep2();
	ok( /^[89]\z/, 'local lexical $_ is seen in grep' );
	{ ok( our $_ eq 'global', 'our $_ still visible' ); }
	ok( $_ == 8 || $_ == 9, 'local lexical $_ is still seen in grep' );
    } 8, 9;
    ok( $buf eq 'gygy', q/...grep doesn't modify outer lexical $_/ );
    ok( $_ eq 'y', '...my $_ restored outside grep' );
    ok( our $_ eq 'global', '...our $_ restored outside grep' );
}
{
    my $s = "toto";
    my $_ = "titi";
    $s =~ /to(?{ ok( $_ eq 'toto', 'my $_ in code-match # TODO' ) })to/
	or ok( 0, "\$s=$s should match!" );
    ok( our $_ eq 'global', '...our $_ restored outside code-match' );
}

{
    my $_ = "abc";
    my $x = reverse;
    ok( $x eq "cba", 'reverse without arguments picks up $_ # TODO' );
}

{
    package notmain;
    our $_ = 'notmain';
    ::ok( $::_ eq 'notmain', 'our $_ forced into main::' );
    /(.*)/;
    ::ok( $1 eq 'notmain', '...m// defaults to our $_ in main::' );
}

my $file = 'dolbar1.tmp';
END { unlink $file; }
{
    open my $_, '>', $file or die "Can't open $file: $!";
    print $_ "hello\n";
    close $_;
    ok( -s $file, 'writing to filehandle $_ works' );
}
{
    open my $_, $file or die "Can't open $file: $!";
    my $x = <$_>;
    ok( $x eq "hello\n", 'reading from <$_> works' );
    close $_;
}
