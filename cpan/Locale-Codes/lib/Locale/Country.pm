package Locale::Country;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2011 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
require 5.002;

require Exporter;
use Carp;
use Locale::Codes;
use Locale::Constants;
use Locale::Codes::Country;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.16';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2country
                country2code
                all_country_codes
                all_country_names
                country_code2code
                LOCALE_CODE_ALPHA_2
                LOCALE_CODE_ALPHA_3
                LOCALE_CODE_NUMERIC
                LOCALE_CODE_FIPS
                LOCALE_CODE_DOM
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_CODE_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_CODE_ALPHA_2) {
         $codeset = "alpha2";
      } elsif ($codeset ==  LOCALE_CODE_ALPHA_3) {
         $codeset = "alpha3";
      } elsif ($codeset ==  LOCALE_CODE_NUMERIC) {
         $codeset = "num";
      } elsif ($codeset ==  LOCALE_CODE_FIPS) {
         $codeset = "fips";
      } elsif ($codeset ==  LOCALE_CODE_DOM) {
         $codeset = "dom";
      } else {
         return (1);
      }
   }

   if      ($codeset eq "alpha2"  ||
            $codeset eq "alpha3") {
      $code    = lc($code);
   } elsif ($codeset eq "num") {
      if (defined($code)  &&  $code ne "") {
         return (1)  unless ($code =~ /^\d+$/);
         $code    = sprintf("%.3d", $code);
      }
   } elsif ($codeset eq "fips"  ||
            $codeset eq "dom") {
      $code    = uc($code);
   } else {
      return (1);
   }

   return (0,$code,$codeset);
}

#=======================================================================
#
# code2country ( CODE [,CODESET] )
#
#=======================================================================

sub code2country {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("country",$code,$codeset);
}

#=======================================================================
#
# country2code ( COUNTRY [,CODESET] )
#
#=======================================================================

sub country2code {
   my($country,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $country);

   return Locale::Codes::_name2code("country",$country,$codeset);
}

#=======================================================================
#
# country_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub country_code2code {
   (@_ == 3) or croak "country_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("country",$code,$inset,$outset);
}

#=======================================================================
#
# all_country_codes ( [CODESET] )
#
#=======================================================================

sub all_country_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_codes("country",$codeset);
}


#=======================================================================
#
# all_country_names ( [CODESET] )
#
#=======================================================================

sub all_country_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_names("country",$codeset);
}

#=======================================================================
#
# rename_country ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_country {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("country",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_country ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_country {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("country",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_country ( CODE [,CODESET] )
#
#=======================================================================

sub delete_country {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("country",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_country_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_country_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("country",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_country_alias ( NAME )
#
#=======================================================================

sub delete_country_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("country",$name,$nowarn);
}

#=======================================================================
#
# rename_country_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_country_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("country",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_country_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_country_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("country",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_country_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_country_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("country",$code,$codeset,$nowarn);
}

#=======================================================================
#
# Old function for backward compatibility
#
#=======================================================================

sub alias_code {
   my($alias,$code,@args) = @_;
   my $success = rename_country_code($code,$alias,@args);
   return 0  if (! $success);
   return $alias;
}

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
