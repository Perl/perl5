#!./perl -w

use strict;
use warnings;

BEGIN {
    chdir '..' if -e './test.pl';
}

require './t/test.pl';
plan(4);

sub win32_u64uf {
    my ($template) = @_;
    my $format;

    chdir 'win32' or die "Can't chdir to win32: $!";
    open my $fh, '-|', $^X, '-I.', '-I../lib', 'config_sh.PL', '--prebuilt',
        'SKIP_CCHOME_CHECK=1', 'cc=cc', 'static_ext=',
        'd_mymalloc=undef', 'cf_by=nobody', 'cf_email=nobody@example.invalid',
        'WIN64=undef', 'use64bitint=undef', 'uselongdouble=undef',
        'usequadmath=undef', 'useithreads=undef', 'usecplusplus=undef',
        $template
        or die "Can't run win32/config_sh.PL";

    while (<$fh>) {
        $format = $1 if /^sPRIu64='(.+)'$/;
    }
    close $fh or die "win32/config_sh.PL failed";
    unlink 'nul' if $^O ne 'MSWin32' and -f 'nul';
    chdir '..' or die "Can't chdir to the top level: $!";

    return $format;
}

is(win32_u64uf('config.vc'), '"I64u"',
   'the MSVC 32-bit configuration formats U64 with I64u');
is(win32_u64uf('config.gc'), '"I64u"',
   'the MinGW 32-bit configuration formats U64 with I64u');

for my $header (qw(config_H.vc config_H.gc)) {
    open my $fh, '<', "win32/$header"
        or die "Can't open win32/$header: $!";
    my $found = grep /^#define U64uf\s+"I64u"/, <$fh>;
    close $fh or die "Can't close win32/$header: $!";
    ok($found, "$header exports the Win32 U64 format");
}

# ex: set ts=8 sts=4 sw=4 et:
