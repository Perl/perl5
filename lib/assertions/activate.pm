package assertions::activate;

our $VERSION = '0.01';

sub import {
    shift;
    @_ = '.*' unless @_;
    push @{^ASSERTING}, map { qr/^(?:$_)\z/ } @_;
}

1;
__END__

=head1 NAME

assertions::activate - activate assertions

=head1 SYNOPSIS

  use assertions::activate 'Foo', 'bar', 'Foo::boz::.*';

  # activate all assertions
  use assertions::activate;

=head1 DESCRIPTION

This module is used internally by perl (and its C<-A> command-line switch) to
enable and disable assertions. It can also be used directly.

The import parameters are a list of strings or of regular expressions. The
assertion tags that match those regexps are enabled. If no parameter is
given, all assertions are activated.

=head1 SEE ALSO

L<assertions>, L<perlrun>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
