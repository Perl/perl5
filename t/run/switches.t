#!./perl -w

# Tests for the command-line switches

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

require "./test.pl";

plan(tests => 14);

my $r;
my @tmpfiles = ();
END { unlink @tmpfiles }

# Tests for -0

$r = runperl(
    switches	=> [ '-0', ],
    stdin	=> 'foo\0bar\0baz\0',
    prog	=> 'print qq(<$_>) while <>',
);
is( $r, "<foo\0><bar\0><baz\0>", "-0" );

$r = runperl(
    switches	=> [ '-l', '-0', '-p' ],
    stdin	=> 'foo\0bar\0baz\0',
    prog	=> '1',
);
is( $r, "foo\nbar\nbaz\n", "-0 after a -l" );

$r = runperl(
    switches	=> [ '-0', '-l', '-p' ],
    stdin	=> 'foo\0bar\0baz\0',
    prog	=> '1',
);
is( $r, "foo\0bar\0baz\0", "-0 before a -l" );

$r = runperl(
    switches	=> [ sprintf("-0%o", ord 'x') ],
    stdin	=> 'fooxbarxbazx',
    prog	=> 'print qq(<$_>) while <>',
);
is( $r, "<foox><barx><bazx>", "-0 with octal number" );

$r = runperl(
    switches	=> [ '-00', '-p' ],
    stdin	=> 'abc\ndef\n\nghi\njkl\nmno\n\npq\n',
    prog	=> 's/\n/-/g;$_.=q(/)',
);
is( $r, 'abc-def--/ghi-jkl-mno--/pq-/', '-00 (paragraph mode)' );

$r = runperl(
    switches	=> [ '-0777', '-p' ],
    stdin	=> 'abc\ndef\n\nghi\njkl\nmno\n\npq\n',
    prog	=> 's/\n/-/g;$_.=q(/)',
);
is( $r, 'abc-def--ghi-jkl-mno--pq-/', '-0777 (slurp mode)' );

# Tests for -c

my $filename = 'swctest.tmp';
SKIP: {
    open my $f, ">$filename" or skip( "Can't write temp file $filename: $!" );
    print $f <<'SWTEST';
BEGIN { print "block 1\n"; }
CHECK { print "block 2\n"; }
INIT  { print "block 3\n"; }
	print "block 4\n";
END   { print "block 5\n"; }
SWTEST
    close $f;
    $r = runperl(
	switches	=> [ '-c' ],
	progfile	=> $filename,
	stderr		=> 1,
    );
    # Because of the stderr redirection, we can't tell reliably the order
    # in which the output is given
    ok(
	$r =~ /$filename syntax OK/
	&& $r =~ /\bblock 1\b/
	&& $r =~ /\bblock 2\b/
	&& $r !~ /\bblock 3\b/
	&& $r !~ /\bblock 4\b/
	&& $r !~ /\bblock 5\b/,
	'-c'
    );
    push @tmpfiles, $filename;
}

# Tests for -l

$r = runperl(
    switches	=> [ sprintf("-l%o", ord 'x') ],
    prog	=> 'print for qw/foo bar/'
);
is( $r, 'fooxbarx', '-l with octal number' );

# Tests for -s

$r = runperl(
    switches	=> [ '-s' ],
    prog	=> 'for (qw/abc def ghi/) {print defined $$_ ? $$_ : q(-)}',
    args	=> [ '--', '-abc=2', '-def', ],
);
is( $r, '21-', '-s switch parsing' );

# Bug ID 20011106.084
$filename = 'swstest.tmp';
SKIP: {
    open my $f, ">$filename" or skip( "Can't write temp file $filename: $!" );
    print $f <<'SWTEST';
#!perl -s
print $x
SWTEST
    close $f;
    $r = runperl(
	switches    => [ '-s' ],
	progfile    => $filename,
	args	    => [ '-x=foo' ],
    );
    is( $r, 'foo', '-s on the #! line' );
    push @tmpfiles, $filename;
}

# Tests for -m and -M

$filename = 'swtest.pm';
SKIP: {
    open my $f, ">$filename" or skip( "Can't write temp file $filename: $!",4 );
    print $f <<'SWTESTPM';
package swtest;
sub import { print map "<$_>", @_ }
1;
SWTESTPM
    close $f;
    $r = runperl(
	switches    => [ '-Mswtest' ],
	prog	    => '1',
    );
    is( $r, '<swtest>', '-M' );
    $r = runperl(
	switches    => [ '-Mswtest=foo' ],
	prog	    => '1',
    );
    is( $r, '<swtest><foo>', '-M with import parameter' );
    $r = runperl(
	switches    => [ '-mswtest' ],
	prog	    => '1',
    );
    is( $r, '', '-m' );
    $r = runperl(
	switches    => [ '-mswtest=foo,bar' ],
	prog	    => '1',
    );
    is( $r, '<swtest><foo><bar>', '-m with import parameters' );
    push @tmpfiles, $filename;
}
