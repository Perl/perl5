package Locale::Codes::LangExt;
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
use Locale::Codes::LangExt_Codes;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.18';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2langext
                langext2code
                all_langext_codes
                all_langext_names
                langext_code2code
                LOCALE_LANGEXT_ALPHA
               );

sub _code {
   my($code,$codeset) = @_;
   $code = ""  if (! $code);

   $codeset = LOCALE_LANGEXT_DEFAULT  if (! defined($codeset)  ||  $codeset eq "");

   if ($codeset =~ /^\d+$/) {
      if      ($codeset ==  LOCALE_LANGEXT_ALPHA) {
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
# code2langext ( CODE [,CODESET] )
#
#=======================================================================

sub code2langext {
   my($err,$code,$codeset) = _code(@_);
   return undef  if ($err  ||
                     ! defined $code);

   return Locale::Codes::_code2name("langext",$code,$codeset);
}

#=======================================================================
#
# langext2code ( LANGEXT [,CODESET] )
#
#=======================================================================

sub langext2code {
   my($langext,$codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return undef  if ($err  ||
                     ! defined $langext);

   return Locale::Codes::_name2code("langext",$langext,$codeset);
}

#=======================================================================
#
# langext_code2code ( CODE,CODESET_IN,CODESET_OUT )
#
#=======================================================================

sub langext_code2code {
   (@_ == 3) or croak "langext_code2code() takes 3 arguments!";
   my($code,$inset,$outset) = @_;
   my($err,$tmp);
   ($err,$code,$inset) = _code($code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code("",$outset);
   return undef  if ($err);

   return Locale::Codes::_code2code("langext",$code,$inset,$outset);
}

#=======================================================================
#
# all_langext_codes ( [CODESET] )
#
#=======================================================================

sub all_langext_codes {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return ()  if ($err);

   return Locale::Codes::_all_codes("langext",$codeset);
}


#=======================================================================
#
# all_langext_names ( [CODESET] )
#
#=======================================================================

sub all_langext_names {
   my($codeset) = @_;
   my($err,$tmp);
   ($err,$tmp,$codeset) = _code("",$codeset);
   return ()  if ($err);

   return Locale::Codes::_all_names("langext",$codeset);
}

#=======================================================================
#
# rename_langext ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub rename_langext {
   my($code,$new_name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_rename("langext",$code,$new_name,$codeset,$nowarn);
}

#=======================================================================
#
# add_langext ( CODE,NAME [,CODESET] )
#
#=======================================================================

sub add_langext {
   my($code,$name,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_add_code("langext",$code,$name,$codeset,$nowarn);
}

#=======================================================================
#
# delete_langext ( CODE [,CODESET] )
#
#=======================================================================

sub delete_langext {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($code,$codeset);

   return Locale::Codes::_delete_code("langext",$code,$codeset,$nowarn);
}

#=======================================================================
#
# add_langext_alias ( NAME,NEW_NAME )
#
#=======================================================================

sub add_langext_alias {
   my($name,$new_name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_add_alias("langext",$name,$new_name,$nowarn);
}

#=======================================================================
#
# delete_langext_alias ( NAME )
#
#=======================================================================

sub delete_langext_alias {
   my($name,$nowarn) = @_;
   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   return Locale::Codes::_delete_alias("langext",$name,$nowarn);
}

#=======================================================================
#
# rename_langext_code ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub rename_langext_code {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_rename_code("langext",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# add_langext_code_alias ( CODE,NEW_CODE [,CODESET] )
#
#=======================================================================

sub add_langext_code_alias {
   my($code,$new_code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);
   ($err,$new_code,$codeset) = _code($new_code,$codeset)  if (! $err);

   return Locale::Codes::_add_code_alias("langext",$code,$new_code,$codeset,$nowarn);
}

#=======================================================================
#
# delete_langext_code_alias ( CODE [,CODESET] )
#
#=======================================================================

sub delete_langext_code_alias {
   my($code,@args) = @_;
   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");
   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($code,$codeset);

   return Locale::Codes::_delete_code_alias("langext",$code,$codeset,$nowarn);
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
