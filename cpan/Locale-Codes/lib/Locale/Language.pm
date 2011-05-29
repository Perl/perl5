package Locale::Language;
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
use Locale::Codes::Language;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.16';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2language
                language2code
                all_language_codes
                all_language_names
                language_code2code
                LOCALE_LANG_ALPHA_2
                LOCALE_LANG_ALPHA_3
                LOCALE_LANG_TERM
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_LANG_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_LANG_ALPHA_2) {
         $codeset = "alpha2";
      } elsif ($codeset ==  LOCALE_LANG_ALPHA_3) {
         $codeset = "alpha3";
      } elsif ($codeset ==  LOCALE_LANG_TERM) {
         $codeset = "term";
      } else {
         return (1);
      }
   }

   if      ($codeset eq "alpha2"  ||
            $codeset eq "alpha3"  ||
            $codeset eq "term") {
      $code    = lc($code);
   } else {
      return (1);
   }

   return (0,$code,$codeset);
}

#=======================================================================
#
# code2language ( CODE [,CODESET] )
#
#=======================================================================

sub code2language {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("language",$code,$codeset);
}

#=======================================================================
#
# language2code ( LANGUAGE [,CODESET] )
#
#=======================================================================

sub language2code {
   my($language,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $language);

   return Locale::Codes::_name2code("language",$language,$codeset);
}

#=======================================================================
#
# language_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub language_code2code {
   (@_ == 3) or croak "language_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("language",$code,$inset,$outset);
}

#=======================================================================
#
# all_language_codes ( [CODESET] )
#
#=======================================================================

sub all_language_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_codes("language",$codeset);
}


#=======================================================================
#
# all_language_names ( [CODESET] )
#
#=======================================================================

sub all_language_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_names("language",$codeset);
}

#=======================================================================
#
# rename_language ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_language {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("language",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_language ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_language {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("language",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_language ( CODE [,CODESET] )
#
#=======================================================================

sub delete_language {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("language",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_language_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_language_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("language",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_language_alias ( NAME )
#
#=======================================================================

sub delete_language_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("language",$name,$nowarn);
}

#=======================================================================
#
# rename_language_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_language_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("language",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_language_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_language_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("language",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_language_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_language_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("language",$code,$codeset,$nowarn);
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
