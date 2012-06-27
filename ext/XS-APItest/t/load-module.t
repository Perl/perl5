#!perl -w
use strict;

use Test::More;
use XS::APItest;

# This isn't complete yet. In particular, we don't test import lists, or
# the other flags. But it's better than nothing.

is($INC{'less.pm'}, undef, "less isn't loaded");
load_module(PERL_LOADMOD_NOIMPORT, 'less');
like($INC{'less.pm'}, qr!(?:\A|/)lib/less\.pm\z!, "less is now loaded");

delete $INC{'less.pm'};
delete $::{'less::'};

is(eval { load_module(PERL_LOADMOD_NOIMPORT, 'less', 1); 1}, undef,
   "expect load_module() to fail");
like($@, qr/less version 1 required--this is only version 0\./,
     'with the correct error message');

is(eval { load_module(PERL_LOADMOD_NOIMPORT, 'less', 0.03); 1}, 1,
   "expect load_module() not to fail");

for (["", qr!\ABareword in require maps to empty filename!],
     ["::", qr!\ABareword in require maps to empty filename!],
     ["::::", qr!\ABareword in require maps to disallowed filename "/\.pm"!],
     ["::/", qr!\ABareword in require maps to disallowed filename "/\.pm"!],
     ["::/WOOSH", qr!\ABareword in require maps to disallowed filename "/WOOSH\.pm"!],
     [".WOOSH", qr!\ABareword in require maps to disallowed filename "\.WOOSH\.pm"!],
     ["::.WOOSH", qr!\ABareword in require maps to disallowed filename "\.WOOSH\.pm"!],
     ["WOOSH::.sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::.sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/.sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/..sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/../sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::..::sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::.::sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::./sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/./sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/.::sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH/..::sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::../sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH::../..::sock", qr!\ABareword in require contains "/\."!],
     ["::WOOSH\0sock", qr!\ABareword in require contains "\\0"!],
    ) {
    my ($module, $error) = @$_;
    my $module2 = $module; # load_module mangles its first argument
    is(eval { load_module(PERL_LOADMOD_NOIMPORT, $module); 1}, undef,
       "expect load_module() for '$module2' to fail");
    like($@, $error);
}

done_testing();
