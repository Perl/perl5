package ExtUtils::MM_DOS;

use strict;
use vars qw($VERSION @ISA);

$VERSION = 0.01;

require ExtUtils::MM_Win32;
@ISA = qw(ExtUtils::MM_Win32);


=head1 NAME

ExtUtils::MM_DOS - DOS specific subclass of ExtUtils::MM_Win32

=head1 SYNOPSIS

  Don't use this module directly.
  Use ExtUtils::MM and let it choose.

=head1 DESCRIPTION

This is a subclass of ExtUtils::MM_Win32 which contains functionality
for DOS.

Unless otherwise stated, it works just like ExtUtils::MM_Win32

=head2 Overridden methods

=over 4

=item B<replace_manpage_separator>

=cut

sub replace_manpage_separator {
    my($self, $man) = @_;

    $man =~ s,/+,__,g;
    return $man;
}

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix

=head1 SEE ALSO

L<ExtUtils::MM_Win32>, L<ExtUtils::MakeMaker>

1;
