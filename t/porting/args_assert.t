#!perl

use strict;
use warnings;
use Config;

require './test.pl';

if ( $Config{usecrosscompile} ) {
  skip_all( "Not all files are available during cross-compilation" );
}

plan('no_plan');

# Fail for every PERL_ARGS_ASSERT* macro that was declared but not used.

my %declared;
my %used;

my $prefix = '';

unless (-d 't' && -f 'MANIFEST') {
    # we'll assume that we are in t then.
    # All files are internal to perl, so Unix-style is sufficiently portable.
    $prefix = '../';
}

{
    my $proto = $prefix . 'proto.h';

    open my $fh, '<', $proto or die "Can't open $proto: $!";

    while (<$fh>) {
        # The trailing '.' distinguishes real from dummy macros that have no
        # real asserts
	$declared{$1}++ if / ^ \s* \# \s* define \s+
                               ( PERL_ARGS_ASSERT \w+ ) \b
                           /ax;
    }
}

cmp_ok(scalar keys %declared, '>', 0, 'Some macros were declared');

if (!@ARGV) {
    my $manifest = $prefix . 'MANIFEST';
    open my $fh, '<', $manifest or die "Can't open $manifest: $!";
    while (<$fh>) {
        # *.c or */*.c; and special case several .h that have functions
        # defined in them
	push @ARGV, $prefix . $1 if m! ^
                                       ( (?: [^/]+ / )? [^/]*
                                         (?:             \.c
                                             |     inline\.h
                                             | perlstatic\.h
                                         )
                                       )
                                       \t
                                     !x;
    }
}

while (<>) {
    $used{$1}++ if / ^ \s+ (PERL_ARGS_ASSERT_ \w+ ) ; /ax;
}

my %unused;

foreach (keys %declared) {
    $unused{$_}++ unless $used{$_};
}

if (keys %unused) {
    fail("$_ is declared but not used") foreach sort keys %unused;
} else {
    pass('Every PERL_ARGS_ASSERT* macro declared is used');
}
