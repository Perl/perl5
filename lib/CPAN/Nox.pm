package CPAN::Nox;
use strict;
use vars qw($VERSION @EXPORT);

BEGIN{
  $CPAN::Suppress_readline=1 unless defined $CPAN::term;
}

use base 'Exporter';
use CPAN;

my $Id = q$Id: APC.pm 147 2005-08-09 04:25:25Z k $;
our $VERSION = sprintf "%.3f", 2 + substr(q$Rev: 147 $,4)/1000;
$CPAN::META->has_inst('Digest::MD5','no');
$CPAN::META->has_inst('LWP','no');
$CPAN::META->has_inst('Compress::Zlib','no');
@EXPORT = @CPAN::EXPORT;

*AUTOLOAD = \&CPAN::AUTOLOAD;

1;

__END__

=head1 NAME

CPAN::Nox - Wrapper around CPAN.pm without using any XS module

=head1 SYNOPSIS

Interactive mode:

  perl -MCPAN::Nox -e shell;

=head1 DESCRIPTION

This package has the same functionality as CPAN.pm, but tries to
prevent the usage of compiled extensions during its own
execution. Its primary purpose is a rescue in case you upgraded perl
and broke binary compatibility somehow.

=head1  SEE ALSO

CPAN(3)

=cut

