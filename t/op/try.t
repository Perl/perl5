#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use strict;
use warnings;
use feature 'try';
no warnings 'experimental::try';

{
    my $x;
    try {
        $x .= "try";
    }
    catch ($e) {
        $x .= "catch";
    }
    is($x, "try", 'successful try/catch runs try but not catch');
}

{
    my $x;
    my $caught;
    try {
        $x .= "try";
        die "Oopsie\n";
    }
    catch ($e) {
        $x .= "catch";
        $caught = $e;
        is($@, "", '$@ is empty within catch block');
    }
    is($x, "trycatch", 'die in try runs catch block');
    is($caught, "Oopsie\n", 'catch block saw exception value');
}

# return inside try {} makes containing function return
{
    sub f
    {
        try {
            return "return inside try";
        }
        catch ($e) { }
        return "return from func";
    }
    is(f(), "return inside try", 'return inside try');
}

# Loop controls inside try {} do not emit warnings
{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= $_[0] };

   {
      try {
         last;
      }
      catch ($e) { }
   }

   {
      try {
         next;
      }
      catch ($e) { }
   }

   my $count = 0;
   {
      try {
         $count++;
         redo if $count < 2;
      }
      catch ($e) { }
   }

   is($warnings, "", 'No warnings emitted by next/last/redo inside try');

   $warnings = "";

   LOOP_L: {
      try {
         last LOOP_L;
      }
      catch ($e) { }
   }

   LOOP_N: {
      try {
         next LOOP_N;
      }
      catch ($e) { }
   }

   $count = 0;
   LOOP_R: {
      try {
         $count++;
         redo LOOP_R if $count < 2;
      }
      catch ($e) { }
   }

   is($warnings, "", 'No warnings emitted by next/last/redo LABEL inside try');
}

# try/catch should localise $@
{
    eval { die "Value before\n"; };

    try { die "Localized value\n" } catch ($e) {}

    is($@, "Value before\n", 'try/catch localized $@');
}

# try/catch is not confused by false values
{
    my $caught;
    try {
        die 0;
    }
    catch ($e) {
        $caught++;
    }

    ok( $caught, 'catch{} sees a false exception' );
}

# try/catch is not confused by always-false objects
{
    my $caught;
    try {
        die FALSE->new;
    }
    catch ($e) {
        $caught++;
    }

    ok( $caught, 'catch{} sees a false-overload exception object' );

    {
        package FALSE;
        use overload 'bool' => sub { 0 };
        sub new { bless [], shift }
    }
}

done_testing;
