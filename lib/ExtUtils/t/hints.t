#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}
chdir 't';

use Test::More tests => 1;

mkdir 'hints';
my $hint = $^O;
open(HINT, ">hints/$hint.pl") || die "Can't write dummy hints file: $!";
print HINT <<'CLOO';
$self->{CCFLAGS} = 'basset hounds got long ears';
CLOO
close HINT;

use ExtUtils::MakeMaker;
my $mm = bless {}, 'ExtUtils::MakeMaker';
$mm->check_hints;
is( $mm->{CCFLAGS}, 'basset hounds got long ears' );


END {
    use File::Path;
    rmtree ['hints'];
}
