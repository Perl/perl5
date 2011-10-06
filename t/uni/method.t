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

plan(tests => 25);

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

{
    use utf8;
    use open qw( :utf8 :std );

    my $e;
    
    eval '$e = bless {}, "Ｅ::Ａ"; Ｅ::Ａ->ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ａ" at/u);
    eval '$e = bless {}, "Ｅ::Ｂ"; $e->ｆｏｏ()';  
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｂ" at/u);
    eval 'Ｅ::Ｃ->ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｃ" (perhaps /u);
    
    eval 'UNIVERSAL->Ｅ::Ｄ::ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｄ" (perhaps /u);
    eval 'my $e = bless {}, "UNIVERSAL"; $e->Ｅ::Ｅ::ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｅ" (perhaps /u);
    
    $e = bless {}, "Ｅ::Ｆ";  # force package to exist
    eval 'UNIVERSAL->Ｅ::Ｆ::ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｆ" at/u);
    eval '$e = bless {}, "UNIVERSAL"; $e->Ｅ::Ｆ::ｆｏｏ()';
    like ($@, qr/^\QCan't locate object method "ｆｏｏ" via package "Ｅ::Ｆ" at/u);
}

is(do { use utf8; use open qw( :utf8 :std ); eval 'Ｆｏｏ->ｂｏｏｇｉｅ()';
	  $@ =~ /^\QCan't locate object method "ｂｏｏｇｉｅ" via package "Ｆｏｏ" (perhaps /u ? 1 : $@}, 1);

#This reimplements a bit of _fresh_perl() from test.pl, as we want to decode
#the output of that program before using it.
SKIP: {
    skip_if_miniperl('no dynamic loading on miniperl, no Encode');

    my $prog = q!use utf8; use open qw( :utf8 :std ); sub Ｔ::DESTROY { $x = $_[0]; } bless [], "Ｔ";!;
    utf8::decode($prog);

    my $tmpfile = tempfile();
    my $runperl_args = {};
    $runperl_args->{progfile} = $tmpfile;
    $runperl_args->{stderr} = 1;

    open TEST, '>', $tmpfile or die "Cannot open $tmpfile: $!";

    print TEST $prog;
    close TEST or die "Cannot close $tmpfile: $!";

    my $results = runperl(%$runperl_args);

    require Encode;
    $results = Encode::decode("UTF-8", $results);

    like($results,
            qr/DESTROY created new reference to dead object 'Ｔ' during global destruction./u,
            "DESTROY creating a new reference to the object generates a warning in UTF-8.");
}
