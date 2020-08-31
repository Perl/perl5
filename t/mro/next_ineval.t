#!/usr/bin/perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
use warnings;

plan(tests => 1);

=pod

This tests the use of an eval{} block to wrap a next::method call.

=cut

{
    package AA;
    use mro 'c3'; 

    sub foo {
      die 'AA::foo died';
      return 'AA::foo succeeded';
    }
}

{
    package BB;
    use base 'AA';
    use mro 'c3'; 
    
    sub foo {
      eval {
        return 'BB::foo => ' . (shift)->next::method();
      };

      if ($@) {
        return $@;
      }
    }
}

like(BB->foo,
   qr/^AA::foo died/,
   'method resolved inside eval{}');


