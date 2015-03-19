#!/usr/bin/perl -w
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        chdir '../lib/parent';
        @INC = '..';
    }
}

use strict;
use Test::More;
use Config;
use lib 't/lib';

plan skip_all => ".pmc are only available with 5.6 and later" if $] < 5.006;
my $no_pmc;

if (Config->can('non_bincompat_options')) {
    foreach(Config::non_bincompat_options()) {
       if($_ eq "PERL_DISABLE_PMC"){
           $no_pmc = 1;
           last;
       }
    }
};
plan skip_all => ".pmc are disabled in this perl"
    if $no_pmc;
plan tests => 3;

use vars qw($got_here);

my $res = eval q{
    package MyTest;

    use parent 'FileThatOnlyExistsAsPMC';

    1
};
my $error = $@;

is $res, 1, "Block ran until the end";
is $error, '', "No error";

my $obj = bless {}, 'FileThatOnlyExistsAsPMC';
can_ok $obj, 'exclaim';
