package ExtUtils::ParseXS::Constants;
use strict;
use warnings;
use Symbol;

=head1 NAME

ExtUtils::ParseXS::Constants - Initialization values for some globals

=head1 SYNOPSIS

  use ExtUtils::ParseXS::Constants ();

  $proto_re = $ExtUtils::ParseXS::Constants::proto_re;

=head1 DESCRIPTION

Initialization of certain non-subroutine variables in ExtUtils::ParseXS and some of its
supporting packages has been moved into this package so that those values can
be defined exactly once and then re-used in any package.

Nothing is exported.  Use fully qualified variable names.

=cut

our @InitFileCode = ();
our $FH           = Symbol::gensym();
our $proto_re     = "[" . quotemeta('\$%&*@;[]_') . "]";
our $Overload     = 0;
our $errors       = 0;
our $Fallback     = '&PL_sv_undef';
our @keywords     = qw( 
  REQUIRE BOOT CASE PREINIT INPUT INIT CODE PPCODE
  OUTPUT CLEANUP ALIAS ATTRS PROTOTYPES PROTOTYPE
  VERSIONCHECK INCLUDE INCLUDE_COMMAND SCOPE INTERFACE
  INTERFACE_MACRO C_ARGS POSTCALL OVERLOAD FALLBACK
);

1;
