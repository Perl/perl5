package Mac::err;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(Exporter DynaLoader);
$VERSION = '0.01';

sub import {
	my($pkg, $import) = @_;

	if	($import =~ /(?:mpw|mac)/i) {
		Mac_err_MPW();
	}
	elsif	($import =~ /(?:nix|perl)/i) {
		Mac_err_Unix();
	}
}

*format = *import{CODE};

bootstrap Mac::err $VERSION;

1;

__END__

=head1 NAME

Mac::err - Extension for formatting error messages

=head1 SYNOPSIS

  use Mac::err 'perl';
  warn "foo";
  Mac::err->format('MPW');
  warn "bar";

Results:

  foo at Dev:Pseudo line 2.
  # bar.
  File 'Dev:Pseudo'; Line 4


=head1 DESCRIPTION

By default, MacPerl produces error messages that are formatted for
use with MPW.  This module allows switching the formatting behavior.

Normal usage is simply C<use Mac::err 'type'>, where the format type
string is C<MPW> or C<perl>.  If the format type is C<perl>, then the
formatting will be the same as under Unix perl.

Formatting may be changed on the fly as well, with the C<format> method.

The error messages are formatted on output; so when looking at the error
message in a variable (such as in $@) it will remain unformatted.

=cut
