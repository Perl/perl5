#!./perl -w

#
# test method calls and autoloading.
#

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    require "test.pl";
}

use strict;
use utf8;
use open qw( :utf8 :std );
no warnings 'once';

plan(tests => 16);

#Can't use bless yet, as it might not be clean

sub F::ｂ { ::is shift, "F";  "UTF8 meth"       }
sub Ｆ::b { ::is shift, "Ｆ";  "UTF8 Stash"     }
sub Ｆ::ｂ { ::is shift, "Ｆ"; "UTF8 Stash&meth" }

is(F->ｂ, "UTF8 meth", "If the method is in UTF-8, lookup works through explicitly named methods");
is(F->${\"ｂ"}, "UTF8 meth", '..as does for ->${\""}');
eval { F->${\"ｂ\0nul"} };
ok $@, "If the method is in UTF-8, lookup is nul-clean";

is(Ｆ->b, "UTF8 Stash", "If the stash is in UTF-8, lookup works through explicitly named methods");
is(Ｆ->${\"b"}, "UTF8 Stash", '..as does for ->${\""}');
eval { Ｆ->${\"b\0nul"} };
ok $@, "If the stash is in UTF-8, lookup is nul-clean";

is(Ｆ->ｂ, "UTF8 Stash&meth", "If both stash and method are in UTF-8, lookup works through explicitly named methods");
is(Ｆ->${\"ｂ"}, "UTF8 Stash&meth", '..as does for ->${\""}');
eval { Ｆ->${\"ｂ\0nul"} };
ok $@, "Even if both stash and method are in UTF-8, lookup is nul-clean";

eval { my $ref = \my $var; $ref->ｍｅｔｈｏｄ };
like $@, qr/Can't call method "ｍｅｔｈｏｄ" on unblessed reference /u;
