package assertions::activate;

our $VERSION = '0.01';

# use strict;
# use warnings;

sub import {
    shift;
    push @{^ASSERTING}, ( map { qr/^$_$/ } @_) ;
}

1;
__END__

=head1 NAME

assertions::activate - assertions activation

=head1 SYNOPSIS

  use assertions::activate 'Foo', 'bar', 'Foo::boz::.*' ;

=head1 ABSTRACT

C<assertions::activate> module is used to configure assertion
execution.

=head1 DESCRIPTION



=head2 EXPORT

None by default.

=head1 SEE ALSO

L<assertions>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
