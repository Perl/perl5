package Locale::Currency;
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
use Locale::Codes::Currency;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.16';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2currency
                currency2code
                all_currency_codes
                all_currency_names
                currency_code2code
                LOCALE_CURR_ALPHA
                LOCALE_CURR_NUMERIC
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_CURR_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_CURR_ALPHA) {
         $codeset = "alpha";
      } elsif ($codeset ==  LOCALE_CURR_NUMERIC) {
         $codeset = "num";
      } else {
         return (1);
      }
   }

   if      ($codeset eq "alpha") {
      $code    = uc($code);
   } elsif ($codeset eq "num") {
      if (defined($code)  &&  $code ne "") {
         return (1)  unless ($code =~ /^\d+$/);
         $code    = sprintf("%.3d", $code);
      }
   } else {
      return (1);
   }

   return (0,$code,$codeset);
}

#=======================================================================
#
# code2currency ( CODE [,CODESET] )
#
#=======================================================================

sub code2currency {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("currency",$code,$codeset);
}

#=======================================================================
#
# currency2code ( CURRENCY [,CODESET] )
#
#=======================================================================

sub currency2code {
   my($currency,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $currency);

   return Locale::Codes::_name2code("currency",$currency,$codeset);
}

#=======================================================================
#
# currency_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub currency_code2code {
   (@_ == 3) or croak "currency_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("currency",$code,$inset,$outset);
}

#=======================================================================
#
# all_currency_codes ( [CODESET] )
#
#=======================================================================

sub all_currency_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_codes("currency",$codeset);
}


#=======================================================================
#
# all_currency_names ( [CODESET] )
#
#=======================================================================

sub all_currency_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_names("currency",$codeset);
}

#=======================================================================
#
# rename_currency ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_currency {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("currency",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_currency ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_currency {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("currency",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_currency ( CODE [,CODESET] )
#
#=======================================================================

sub delete_currency {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("currency",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_currency_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_currency_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("currency",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_currency_alias ( NAME )
#
#=======================================================================

sub delete_currency_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("currency",$name,$nowarn);
}

#=======================================================================
#
# rename_currency_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_currency_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("currency",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_currency_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_currency_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("currency",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_currency_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_currency_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("currency",$code,$codeset,$nowarn);
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
