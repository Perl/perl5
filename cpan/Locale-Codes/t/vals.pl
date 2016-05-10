#!/usr/bin/perl
# Copyright (c) 2016-2016 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use warnings;
use strict;
no strict 'subs';
no strict 'refs';

$::generic_tests = '';

eval "use $::module";

sub test {
   my    ($op,@test) = @_;

   if ($op eq '2code') {
      my $code = &{ "${::type}2code" }(@test);
      return ($code ? lc($code) : $code);
   } elsif ($op eq '2name') {
      return &{ "code2${::type}" }(@test)
   } elsif ($op eq '_code2code') {
      my $code = &{ "${::type}_code2code" }(@test,"nowarn");
      return ($code ? lc($code) : $code);

   } elsif ($op eq 'all_codes') {
      my $n;
      if ($test[$#test] =~ /^\d+$/) {
         $n = pop(@test);
      }

      my @tmp = &{ "all_${::type}_codes" }(@test);
      if ($n  &&  @tmp > $n) {
         return @tmp[0..($n-1)];
      } else {
         return @tmp;
      }
   } elsif ($op eq 'all_names') {
      my $n;
      if ($test[$#test] =~ /^\d+$/) {
         $n = pop(@test);
      }

      my @tmp = &{ "all_${::type}_names" }(@test);
      if ($n  &&  @tmp > $n) {
         return @tmp[0..($n-1)];
      } else {
         return @tmp;
      }

   } elsif ($op eq 'rename') {
      return &{ "${::module}::rename_${::type}" }(@test,"nowarn")
   } elsif ($op eq 'add') {
      return &{ "${::module}::add_${::type}" }(@test,"nowarn")
   } elsif ($op eq 'delete') {
      return &{ "${::module}::delete_${::type}" }(@test,"nowarn")
   } elsif ($op eq 'add_alias') {
      return &{ "${::module}::add_${::type}_alias" }(@test,"nowarn")
   } elsif ($op eq 'delete_alias') {
      return &{ "${::module}::delete_${::type}_alias" }(@test,"nowarn")
   } elsif ($op eq 'rename_code') {
      return &{ "${::module}::rename_${::type}_code" }(@test,"nowarn")
   } elsif ($op eq 'add_code_alias') {
      return &{ "${::module}::add_${::type}_code_alias" }(@test,"nowarn")
   } elsif ($op eq 'delete_code_alias') {
      return &{ "${::module}::delete_${::type}_code_alias" }(@test,"nowarn")
   }
}

$::generic_tests = "
#################

2code
_undef_
   _undef_

2code
   _undef_

2code
_blank_
   _undef_

2code
UnusedName
   _undef_

2code
   _undef_

2code
_undef_
   _undef_

2name
_undef
   _undef_

2name
   _undef_

###

add
AAA
newCode
   1

2code
newCode
   aaa

delete
AAA
   1

2code
newCode
   _undef_

###

add
AAA
newCode
   1

rename
AAA
newCode2
   1

2code
newCode
   aaa

2code
newCode2
   aaa

###

add_alias
newCode2
newAlias
   1

2code
newAlias
   aaa

delete_alias
newAlias
   1

2code
newAlias
   _undef_

###

rename_code
AAA
BBB
   1

2name
AAA
   newCode2

2name
BBB
   newCode2

###

add_code_alias
BBB
CCC
   1

2name
BBB
   newCode2

2name
CCC
   newCode2

delete_code_alias
CCC
   1

2name
CCC
   _undef_

";

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:

