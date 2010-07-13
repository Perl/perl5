#!perl -w

BEGIN {
  push @INC, "::lib:$MacPerl::Architecture:" if $^O eq 'MacOS';
  require Config; import Config;
  if ($Config{'extensions'} !~ /\bXS\/APItest\b/) {
    # Look, I'm using this fully-qualified variable more than once!
    my $arch = $MacPerl::Architecture;
    print "1..0 # Skip: XS::APItest was not built\n";
    exit 0;
  }
}

use strict;
use utf8;
use Test::More tests => 5;

BEGIN {use_ok('XS::APItest')};

sub make_temp_mg_lv :lvalue {  XS::APItest::TempLv::make_temp_mg_lv($_[0]); }

{
    my $x = "[]";
    eval { XS::APItest::TempLv::make_temp_mg_lv($x) = "a"; };
    is($@, '',    'temp mg lv from xs exception check');
    is($x, '[a]', 'temp mg lv from xs success');
}

{
    local $TODO = "PP lvalue sub can't return magical temp";
    my $x = "{}";
    eval { make_temp_mg_lv($x) = "b"; };
    is($@, '',    'temp mg lv from pp exception check');
    is($x, '{b}', 'temp mg lv from pp success');
}

1;
