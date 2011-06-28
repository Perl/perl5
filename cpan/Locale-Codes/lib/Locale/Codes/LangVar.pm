package Locale::Codes::LangVar;
# Copyright (c) 2011-2011 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
require 5.002;

require Exporter;
use Carp;
use Locale::Codes;
use Locale::Codes::Constants;
use Locale::Codes::LangVar_Codes;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.17';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2langvar
                langvar2code
                all_langvar_codes
                all_langvar_names
                langvar_code2code
                LOCALE_LANGVAR_ALPHA
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_LANGVAR_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_LANGVAR_ALPHA) {
         $codeset = "alpha";
      } else {
         return (1);
      }
   }

   if      ($codeset eq "alpha") {
      $code    = lc($code);
   } else {
      return (1);
   }

   return (0,$code,$codeset);
}

#=======================================================================
#
# code2langvar ( CODE [,CODESET] )
#
#=======================================================================

sub code2langvar {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("langvar",$code,$codeset);
}

#=======================================================================
#
# langvar2code ( LANGVAR [,CODESET] )
#
#=======================================================================

sub langvar2code {
   my($langvar,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $langvar);

   return Locale::Codes::_name2code("langvar",$langvar,$codeset);
}

#=======================================================================
#
# langvar_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub langvar_code2code {
   (@_ == 3) or croak "langvar_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("langvar",$code,$inset,$outset);
}

#=======================================================================
#
# all_langvar_codes ( [CODESET] )
#
#=======================================================================

sub all_langvar_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return ()  if ($err);

   return Locale::Codes::_all_codes("langvar",$codeset);
}


#=======================================================================
#
# all_langvar_names ( [CODESET] )
#
#=======================================================================

sub all_langvar_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return ()  if ($err);

   return Locale::Codes::_all_names("langvar",$codeset);
}

#=======================================================================
#
# rename_langvar ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_langvar {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("langvar",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_langvar ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_langvar {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("langvar",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_langvar ( CODE [,CODESET] )
#
#=======================================================================

sub delete_langvar {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("langvar",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_langvar_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_langvar_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("langvar",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_langvar_alias ( NAME )
#
#=======================================================================

sub delete_langvar_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("langvar",$name,$nowarn);
}

#=======================================================================
#
# rename_langvar_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_langvar_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("langvar",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_langvar_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_langvar_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("langvar",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_langvar_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_langvar_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("langvar",$code,$codeset,$nowarn);
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
