#!./perl

BEGIN {
    if ($^O eq 'MacOS') {
	@INC = qw(: ::lib ::macos:lib);
    }
}

$|  = 1;
use warnings;
use strict;
use Config;

print "1..1\n";

my $test = 1;

sub ok { print "ok $test\n"; $test++ }

my $a;
my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

my $path = join " ", map { qq["-I$_"] } @INC;
my $redir = $Is_MacOS ? "" : "2>&1";
my $is_thread = $Config{use5005threads} && $Config{use5005threads} eq 'define';

if ($is_thread) {
    print "# use5005threads: test $test skipped\n";
} else {
    $a = `$^X $path "-MO=Showlex" -e "my %one" $redir`;
    if (ord('A') != 193) { # ASCIIish
        print "# [$a]\nnot " unless $a =~ /sv_undef.*PVNV.*%one.*sv_undef.*HV/s;
    }
    else { # EBCDICish C<1: PVNV (0x1a7ede34) "%\226\225\205">
        print "# [$a]\nnot " unless $a =~ /sv_undef.*PVNV.*%\\[0-9].*sv_undef.*HV/s;
    }
}
ok;
