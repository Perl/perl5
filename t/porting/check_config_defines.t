#!./perl -w
use strict;

BEGIN {
    chdir ".." if -e "./test.pl";
}

# autodoc.pl will strictly enforce that anything in config.h generated
# from config_h.SH has documentation.  But there may be #define statements
# in config.h that were written there directly and not by processing
# config.sh (notably configure.com has depended heavily on this mechanism
# for many years). So flag any such definitions for review whether they
# have documentation or not.

require './t/test.pl';
plan(1);

my %rogue_defines = ();

my $config_h = $^O eq 'MSWin32' ? 'win32\full\config.h' : 'config.h';

open my $fh, '<', $config_h or die "Can't open $config_h: $!";
my $seen_config_start = 0;
while (<$fh>) {
    $seen_config_start = 1 if m/^#define _config_h_/;
    last if $seen_config_start;

    if (m/^\s*#define\s+(\S+)/) {
        $rogue_defines{$1}++;
    }
}
close $fh or die $!;

if (scalar keys %rogue_defines) {
    fail('Rogue macro definitions found in config.h!');
    my @messages = (
        ' ',
        'The following are defined in config.h but not processed from config.sh via',
        'config_h.SH. Please check whether these variables can be defined on the',
        'command line via -D, can be added to (or already exist in) config_h.SH, can',
        'be specified in one of the *ish.h platform-specific includes, or are ',
        'obsolete and can be removed.',
        ' '
    );

    for my $define (sort keys %rogue_defines) {
        push @messages, $define;
    }
    diag(@messages);
}
else {
    pass('No rogue macro definitions in config.h');
}
