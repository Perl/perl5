#!/usr/bin/perl -w
# Copyright (c) 2010-2010 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

%script_alias =
  (
  );

%script_iso_orig =
  (
   "Ethiopic (Ge\x{2bb}ez)"          => "Ethiopic (Geez)",
   "Hangul (Hang\x{16d}l, Hangeul)"  => "Hangul (Hangul, Hangeul)",
   "Hanunoo (Hanun\x{f3}o)"          => "Hanunoo (Hanunoo)",
   "Lepcha (R\x{f3}ng)"              => "Lepcha (Rong)",
   "Nakhi Geba ('Na-'Khi \x{b2}Gg\x{14f}-\x{b9}baw, Naxi Geba)" =>
      "Nakhi Geba ('Na-'Khi Ggo-baw, Naxi Geba)",
   "N\x{2019}Ko"                     => "N'Ko",
   "Ol Chiki (Ol Cemet\x{2019}, Ol, Santali)" =>
      "Ol Chiki (Ol Cemet, Ol, Santali)",
  );

%script_iso_ignore =
  (
   "Zxxx"    => 1,
   "Zyyy"    => 1,
   "Zzzz"    => 1,
  );
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

