#!./perl

BEGIN: {
    chdir 't' if -d 't';
    @INC = ('../lib');
}

# supress VMS whinging about bad execs.
use vmsish qw(hushed);

$| = 1;				# flush stdout

$ENV{LC_ALL}   = 'C';		# Forge English error messages.
$ENV{LANGUAGE} = 'C';		# Ditto in GNU.

require './test.pl';
plan(tests => 12);

my $exit;
SKIP: {
    skip("bug/feature of pdksh", 2) if $^O eq 'os2';

    $exit = system qq{$^X -le "print q{ok 1 - interpreted system(EXPR)"}};
    next_test();
    is( $exit, 0, '  exited 0' );
}

$exit = system qq{$^X -le "print q{ok 3 - split & direct call system(EXPR)"}};
next_test();
is( $exit, 0, '  exited 0' );

# On VMS you need the quotes around the program or it won't work.
# On Unix its the opposite.
my $quote = $^O eq 'VMS' ? '"' : '';
$exit = system $^X, '-le', 
               "${quote}print q{ok 5 - system(PROG, LIST)}${quote}";
next_test();
is( $exit, 0, '  exited 0' );


is( system(qq{$^X -e "exit 0"}), 0,     'Explicit exit of 0' );

my $exit_one = $^O eq 'VMS' ? 4 << 8 : 1 << 8;
is( system(qq{$^X "-I../lib" -e "use vmsish qw(hushed); exit 1"}), $exit_one,
    'Explicit exit of 1' );


$rc = system "lskdfj";
unless( ok($rc == 255 << 8 or $rc == -1 or $rc == 256) ) {
    print "# \$rc == $rc\n";
}

unless ( ok( $! == 2  or  $! =~ /\bno\b.*\bfile/i or  
             $! == 13 or  $! =~ /permission denied/i or
             $! == 22 or  $! =~ /invalid argument/           ) ) {
    printf "# \$! eq %d, '%s'\n", $!, $!;
}

TODO: {
    if( $^O =~ /Win32/ ) {
        print "not ok 11 - exec failure doesn't terminate process # TODO Win32 exec failure waits for user input\n";
        last TODO;
    }

    ok( !exec("lskdjfalksdjfdjfkls"), 
        "exec failure doesn't terminate process");
}

exec $^X, '-le', qq{${quote}print 'ok 12 - exec PROG, LIST'${quote}};
fail("This should never be reached if the exec() worked");
