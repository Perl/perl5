use strict;
use warnings;

use CPAN::Meta::Requirements;

use Test::More 0.88;

{
  my $req = CPAN::Meta::Requirements->new->add_minimum(Foo => 1);

  ok(  $req->accepts_module(Foo => 1));
  ok(! $req->accepts_module(Foo => 0));
}

{
  my $req = CPAN::Meta::Requirements->new->add_minimum(Foo => 0);

  ok(  $req->accepts_module(Foo => 1));
  ok(  $req->accepts_module(Foo => undef));
  ok(  $req->accepts_module(Foo => "v0"));
  ok(  $req->accepts_module(Foo => v1.2.3));
  ok(  $req->accepts_module(Foo => "v1.2.3"));
}

{
  my $req = CPAN::Meta::Requirements->new->add_maximum(Foo => 1);

  ok(  $req->accepts_module(Foo => 1));
  ok(! $req->accepts_module(Foo => 2));
}

{
  my $req = CPAN::Meta::Requirements->new->add_exclusion(Foo => 1);

  ok(  $req->accepts_module(Foo => 0));
  ok(! $req->accepts_module(Foo => 1));
}

done_testing;
