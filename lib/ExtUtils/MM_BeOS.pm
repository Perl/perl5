package ExtUtils::MM_BeOS;

our $VERSION = '1.00';

=head1 NAME

ExtUtils::MM_BeOS - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_BeOS;	# Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=over 4

=cut 

use Config;
use File::Spec;
require Exporter;

require ExtUtils::MakeMaker;
ExtUtils::MakeMaker->import(qw( $Verbose &neatvalue));

unshift @MM::ISA, 'ExtUtils::MM_BeOS';

=item perl_archive

This is internal method that returns path to libperl.a equivalent
to be linked to dynamic extensions. UNIX does not have one, but at
least BeOS has one.

=cut

sub perl_archive
  {
  return File::Spec->catdir('$(PERL_INC)',$Config{libperl});
  }

1;
__END__

