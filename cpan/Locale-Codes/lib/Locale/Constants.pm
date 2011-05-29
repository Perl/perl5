package Locale::Constants;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2011 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;

require Exporter;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------

our($VERSION,@ISA,@EXPORT);

$VERSION='3.16';
@ISA     = qw(Exporter);
@EXPORT  = qw(LOCALE_CODE_ALPHA_2
              LOCALE_CODE_ALPHA_3
              LOCALE_CODE_NUMERIC
              LOCALE_CODE_FIPS
              LOCALE_CODE_DOM
              LOCALE_CODE_DEFAULT

              LOCALE_LANG_ALPHA_2
              LOCALE_LANG_ALPHA_3
              LOCALE_LANG_TERM
              LOCALE_LANG_DEFAULT

              LOCALE_CURR_ALPHA
              LOCALE_CURR_NUMERIC
              LOCALE_CURR_DEFAULT

              LOCALE_SCRIPT_ALPHA
              LOCALE_SCRIPT_NUMERIC
              LOCALE_SCRIPT_DEFAULT
            );

#-----------------------------------------------------------------------
#	Constants
#-----------------------------------------------------------------------

use constant LOCALE_CODE_ALPHA_2   => 1;
use constant LOCALE_CODE_ALPHA_3   => 2;
use constant LOCALE_CODE_NUMERIC   => 3;
use constant LOCALE_CODE_FIPS      => 4;
use constant LOCALE_CODE_DOM       => 5;

use constant LOCALE_CODE_DEFAULT   => LOCALE_CODE_ALPHA_2;

use constant LOCALE_LANG_ALPHA_2   => 1;
use constant LOCALE_LANG_ALPHA_3   => 2;
use constant LOCALE_LANG_TERM      => 3;

use constant LOCALE_LANG_DEFAULT   => LOCALE_LANG_ALPHA_2;

use constant LOCALE_CURR_ALPHA     => 1;
use constant LOCALE_CURR_NUMERIC   => 2;

use constant LOCALE_CURR_DEFAULT   => LOCALE_CURR_ALPHA;

use constant LOCALE_SCRIPT_ALPHA   => 1;
use constant LOCALE_SCRIPT_NUMERIC => 2;

use constant LOCALE_SCRIPT_DEFAULT => LOCALE_SCRIPT_ALPHA;

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
