#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

$|  = 1;
use warnings;
$Is_VMS = $^O eq 'VMS';

plan tests => 106;

my $Perl = which_perl();

{
    unlink("afile") if -f "afile";

    $! = 0;  # the -f above will set $! if 'afile' doesn't exist.
    ok( open(my $f,"+>afile"),  'open(my $f, "+>...")' );

    binmode $f;
    ok( -f "afile",             '       its a file');
    ok( (print $f "SomeData\n"),  '       we can print to it');
    is( tell($f), 9,            '       tell()' );
    ok( seek($f,0,0),           '       seek set' );

    $b = <$f>;
    is( $b, "SomeData\n",       '       readline' );
    ok( -f $f,                  '       still a file' );

    eval  { die "Message" };
    like( $@, qr/<\$f> line 1/, '       die message correct' );
    
    ok( close($f),              '       close()' );
    ok( unlink("afile"),        '       unlink()' );
}

{
    ok( open(my $f,'>', 'afile'),       "open(my \$f, '>', 'afile')" );
    ok( (print $f "a row\n"),           '       print');
    ok( close($f),                      '       close' );
    ok( -s 'afile' < 10,                '       -s' );
}

{
    ok( open(my $f,'>>', 'afile'),      "open(my \$f, '>>', 'afile')" );
    ok( (print $f "a row\n"),           '       print' );
    ok( close($f),                      '       close' );
    ok( -s 'afile' > 10,                '       -s'    );
}

{
    ok( open(my $f, '<', 'afile'),      "open(my \$f, '<', 'afile')" );
    my @rows = <$f>;
    is( scalar @rows, 2,                '       readline, list context' );
    is( $rows[0], "a row\n",            '       first line read' );
    is( $rows[1], "a row\n",            '       second line' );
    ok( close($f),                      '       close' );
}

{
    ok( -s 'afile' < 20,                '-s' );

    ok( open(my $f, '+<', 'afile'),     'open +<' );
    my @rows = <$f>;
    is( scalar @rows, 2,                '       readline, list context' );
    ok( seek($f, 0, 1),                 '       seek cur' );
    ok( (print $f "yet another row\n"), '       print' );
    ok( close($f),                      '       close' );
    ok( -s 'afile' > 20,                '       -s' );

    unlink("afile");
}

SKIP: {
    skip "open -| busted and noisy on VMS", 3 if $Is_VMS;

    ok( open(my $f, '-|', <<EOC),     'open -|' );
    $Perl -e "print qq(a row\n); print qq(another row\n)"
EOC

    my @rows = <$f>;
    is( scalar @rows, 2,                '       readline, list context' );
    ok( close($f),                      '       close' );
}

{
    ok( open(my $f, '|-', <<EOC),     'open |-' );
    $Perl -pe "s/^not //"
EOC

    my @rows = <$f>;
    my $test = curr_test;
    print $f "not ok $test - piped in\n";
    next_test;

    $test = curr_test;
    print $f "not ok $test - piped in\n";
    next_test;
    ok( close($f),                      '       close' );
    sleep 1;
    pass('flushing');
}


ok( !eval { open my $f, '<&', 'afile'; 1; },    '<& on a non-filehandle' );
like( $@, qr/Bad filehandle:\s+afile/,          '       right error' );


# local $file tests
{
    unlink("afile") if -f "afile";

    ok( open(local $f,"+>afile"),       'open local $f, "+>", ...' );
    binmode $f;

    ok( -f "afile",                     '       -f' );
    ok( (print $f "SomeData\n"),        '       print' );
    is( tell($f), 9,                    '       tell' );
    ok( seek($f,0,0),                   '       seek set' );

    $b = <$f>;
    is( $b, "SomeData\n",               '       readline' );
    ok( -f $f,                          '       still a file' );

    eval  { die "Message" };
    like( $@, qr/<\$f> line 1/,         '       proper die message' );
    ok( close($f),                      '       close' );

    unlink("afile");
}

{
    ok( open(local $f,'>', 'afile'),    'open local $f, ">", ...' );
    ok( (print $f "a row\n"),           '       print');
    ok( close($f),                      '       close');
    ok( -s 'afile' < 10,                '       -s' );
}

{
    ok( open(local $f,'>>', 'afile'),   'open local $f, ">>", ...' );
    ok( (print $f "a row\n"),           '       print');
    ok( close($f),                      '       close');
    ok( -s 'afile' > 10,                '       -s' );
}

{
    ok( open(local $f, '<', 'afile'),   'open local $f, "<", ...' );
    my @rows = <$f>;
    is( scalar @rows, 2,                '       readline list context' );
    ok( close($f),                      '       close' );
}

ok( -s 'afile' < 20,                '       -s' );

{
    ok( open(local $f, '+<', 'afile'),  'open local $f, "+<", ...' );
    my @rows = <$f>;
    is( scalar @rows, 2,                '       readline list context' );
    ok( seek($f, 0, 1),                 '       seek cur' );
    ok( (print $f "yet another row\n"), '       print' );
    ok( close($f),                      '       close' );
    ok( -s 'afile' > 20,                '       -s' );

    unlink("afile");
}

SKIP: {
    skip "open -| busted and noisy on VMS", 3 if $Is_VMS;

    ok( open(local $f, '-|', <<EOC),  'open local $f, "-|", ...' );
    $Perl -e "print qq(a row\n); print qq(another row\n)"
EOC
    my @rows = <$f>;

    is( scalar @rows, 2,                '       readline list context' );
    ok( close($f),                      '       close' );
}

{
    ok( open(local $f, '|-', <<EOC),  'open local $f, "|-", ...' );
    $Perl -pe "s/^not //"
EOC

    my @rows = <$f>;
    my $test = curr_test;
    print $f "not ok $test - piping\n";
    next_test;

    $test = curr_test;
    print $f "not ok $test - piping\n";
    next_test;
    ok( close($f),                      '       close' );
    sleep 1;
    pass("Flush");
}


ok( !eval { open local $f, '<&', 'afile'; 1 },  'local <& on non-filehandle');
like( $@, qr/Bad filehandle:\s+afile/,          '       right error' );

{
    local *F;
    for (1..2) {
        ok( open(F, qq{$Perl -le "print 'ok'"|}), 'open to pipe' );
	is(scalar <F>, "ok\n",  '       readline');
        ok( close F,            '       close' );
    }

    for (1..2) {
        ok( open(F, "-|", qq{$Perl -le "print 'ok'"}), 'open -|');
        is( scalar <F>, "ok\n", '       readline');
	ok( close F,            '       close' );
    }
}


# other dupping techniques
{
    ok( open(my $stdout, ">&", \*STDOUT), 'dup \*STDOUT into lexical fh');
    ok( open(STDOUT,     ">&", $stdout),  'restore dupped STDOUT from lexical fh');
}

# magic temporary file via 3 arg open with undef
{
    ok( open(my $x,"+<",undef), 'magic temp file via 3 arg open with undef');
    ok( defined fileno($x),     '       fileno' );

    select $x;
    ok( (print "ok\n"),         '       print' );

    select STDOUT;
    ok( seek($x,0,0),           '       seek' );
    is( scalar <$x>, "ok\n",    '       readline' );
    ok( tell($x) >= 3,          '       tell' );

    # test magic temp file over STDOUT
    open OLDOUT, ">&STDOUT" or die "cannot dup STDOUT: $!";
    my $status = open(STDOUT,"+<",undef);
    open STDOUT,  ">&OLDOUT" or die "cannot dup OLDOUT: $!";
    # report after STDOUT is restored
    ok($status, '       re-open STDOUT');
}

# in-memory open
{
    my $var;
    ok( open(my $x,"+<",\$var), 'magic in-memory file via 3 arg open with \\$var');
    ok( defined fileno($x),     '       fileno' );

    select $x;
    ok( (print "ok\n"),         '       print' );

    select STDOUT;
    ok( seek($x,0,0),           '       seek' );
    is( scalar <$x>, "ok\n",    '       readline' );
    ok( tell($x) >= 3,          '       tell' );

    SKIP: {
	local $TODO = "in-memory stdhandles not implemented yet";

	# test in-memory open over STDOUT
	open OLDOUT, ">&STDOUT" or die "cannot dup STDOUT: $!";
	#close STDOUT;
	my $status = open(STDOUT,">",\$var);
	my $error = "$!" unless $status; # remember the error
	open STDOUT,  ">&OLDOUT" or die "cannot dup OLDOUT: $!";
	print "# $error\n" unless $status;
	
	# report after STDOUT is restored
	ok($status, '       open STDOUT into in-memory var');
	
	# test in-memory open over STDERR
	open OLDERR, ">&STDERR" or die "cannot dup STDERR: $!";
	#close STDERR;
	ok( open(STDERR,">",\$var), '       open STDERR into in-memory var');
	open STDERR,  ">&OLDERR" or die "cannot dup OLDERR: $!";
    }
}
