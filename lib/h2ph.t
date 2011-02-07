#!./perl
use strict;

# quickie tests to see if h2ph actually runs and does more or less what is
# expected

use Test::More tests => 7;
use Test::PerlRun qw(perlrun perlrun_stderr_like perlrun_stderr_is);

my $extracted_program = '../utils/h2ph'; # unix, nt, ...
if ($^O eq 'VMS') { $extracted_program = '[-.utils]h2ph.com'; }
if (!(-e $extracted_program)) {
    print "1..0 # Skip: $extracted_program was not built\n";
    exit 0;
}

# quickly compare two text files
sub txt_compare {
    local $/;
    my ($A, $B);
    for (($A,$B) = @_) { open(_,"<$_") ? $_ = <_> : die "$_ : $!"; close _ }
    $A cmp $B;
}

my ($stdout, $stderr, $status) = perlrun({ file => $extracted_program,
					   args => ['-d.', '-Q', 'lib/h2ph.h']});
is( $stdout, '', "output is free of warnings" );
is( $stderr, '', "output is free of warnings" );
is( $status, 0, "$extracted_program runs successfully" );

is ( txt_compare("lib/h2ph.ph", "lib/h2ph.pht"),
     0,
     "generated file has expected contents" );

perlrun_stderr_like({ file => 'lib/h2ph.pht', switches => ['-c'] },
		    qr/syntax OK$/, "output compiles");

perlrun_stderr_like({ file => '_h2ph_pre.ph', switches => ['-c'] },
		    qr/syntax OK$/, "preamble compiles");

perlrun_stderr_is( <<'PROG', '', "output free of warnings" );
use warnings;
$SIG{__WARN__} = sub { die $_[0] }; require q(lib/h2ph.pht);
PROG

# cleanup
END {
    1 while unlink("lib/h2ph.ph");
    1 while unlink("_h2ph_pre.ph");
}
