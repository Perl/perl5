#!./perl

BEGIN { chdir 't'; @INC = '../lib'; require './test.pl' }

plan 8;

@Foogh::ISA = "Bar";
*Phoogh::ISA = *Foogh::ISA;
@Foogh::ISA = "Baz";

ok 'Foogh'->isa("Baz"),
 'isa after another stash has claimed the @ISA via glob assignment';
ok 'Phoogh'->isa("Baz"),
 'isa on the stash that claimed the @ISA via glob assignment';
ok !Foogh->isa("Bar"),
 '!isa when another stash has claimed the @ISA via glob assignment';
ok !Phoogh->isa("Bar"),
 '!isa on the stash that claimed the @ISA via glob assignment';

@Foo::ISA = "Bar";
*Phoo::ISA = \@Foo::ISA;
@Foo::ISA = "Baz";

ok 'Foo'->isa("Baz"),
 'isa after another stash has claimed the @ISA via ref-to-glob assignment';
ok 'Phoo'->isa("Baz"),
 'isa on the stash that claimed the @ISA via ref-to-glob assignment';
ok !Foo->isa("Bar"),
 '!isa when another stash has claimed the @ISA via ref-to-glob assignment';
ok !Phoo->isa("Bar"),
 '!isa on the stash that claimed the @ISA via ref-to-glob assignment';
