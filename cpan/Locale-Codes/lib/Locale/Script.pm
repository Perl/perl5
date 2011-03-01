package Locale::Script;
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
use Locale::Codes::Script;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.16';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2script
                script2code
                all_script_codes
                all_script_names
                script_code2code
                LOCALE_SCRIPT_ALPHA
                LOCALE_SCRIPT_NUMERIC
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_SCRIPT_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_SCRIPT_ALPHA) {
         $codeset = "alpha";
      } elsif ($codeset ==  LOCALE_SCRIPT_NUMERIC) {
         $codeset = "num";
      } else {
         return (1);
      }
   }

   if      ($codeset eq "alpha") {
      $code    = ucfirst(lc($code));
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
# code2script ( CODE [,CODESET] )
#
#=======================================================================

sub code2script {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("script",$code,$codeset);
}

#=======================================================================
#
# script2code ( SCRIPT [,CODESET] )
#
#=======================================================================

sub script2code {
   my($script,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $script);

   return Locale::Codes::_name2code("script",$script,$codeset);
}

#=======================================================================
#
# script_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub script_code2code {
   (@_ == 3) or croak "script_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("script",$code,$inset,$outset);
}

#=======================================================================
#
# all_script_codes ( [CODESET] )
#
#=======================================================================

sub all_script_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_codes("script",$codeset);
}


#=======================================================================
#
# all_script_names ( [CODESET] )
#
#=======================================================================

sub all_script_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err);

   return Locale::Codes::_all_names("script",$codeset);
}

#=======================================================================
#
# rename_script ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_script {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("script",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_script ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_script {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("script",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_script ( CODE [,CODESET] )
#
#=======================================================================

sub delete_script {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("script",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_script_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_script_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("script",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_script_alias ( NAME )
#
#=======================================================================

sub delete_script_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("script",$name,$nowarn);
}

#=======================================================================
#
# rename_script_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_script_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("script",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_script_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_script_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("script",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_script_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_script_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if ($args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("script",$code,$codeset,$nowarn);
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
