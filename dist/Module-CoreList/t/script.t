#!perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN { require_ok('Module::CoreList'); }

my $cl = './blib/script/corelist';

my $perl_5 = `$cl -r 5`;
is($perl_5, "Perl 5 was released on 1994-10-17\n\n", 'perl 5 ok');

my $perl_v5 = `$cl -r v5`;
is($perl_v5, "\nModule::CoreList has no info on perl v5\n\n", 'perl v5 not ok');

my $perl_5_10 = `$cl -r 5.10.0`;
is($perl_5_10, "Perl v5.10.0 was released on 2007-12-18\n\n", 'perl 5.10.0 ok');

my $perl_v5_10 = `$cl -r v5.10.0`;
is($perl_v5_10, "Perl v5.10.0 was released on 2007-12-18\n\n", 'perl v5.10.0 ok');

my $perl_0 = `$cl -r 0`;
is($perl_0, "\nModule::CoreList has no info on perl 0\n\n", 'perl 0 not ok');

my $perl_v0 = `$cl -r v0`;
is($perl_v0, "\nModule::CoreList has no info on perl v0\n\n", 'perl v0 not ok');

my $perl_a = `$cl -r a`;
is($perl_a, "\nModule::CoreList has no info on perl a\n\n", 'perl a not ok');

my $perl_all = `$cl -r`;

my $printed_version_count = () = $perl_all =~ /\n/g;
$printed_version_count -= 3; # 1 \n for prologue and 2 \n for epilogue

my $versions_count = grep !/0[01]0$/, keys %Module::CoreList::released;

is($printed_version_count, $versions_count, "perl all ok");
