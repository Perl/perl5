package Mac::err;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
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

bootstrap Mac::err $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Mac::err - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Mac::err;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Mac::err was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
