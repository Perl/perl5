package assertions;

our $VERSION = '0.01';

# use strict;
# use warnings;

my $hint=0x01000000;

sub import {
    shift;
    @_=(scalar(caller)) unless @_;

    if ($_[0] eq '&') {
	return unless $^H & $hint;
	shift;
    }
	
    for my $tag (@_) {
	unless (grep { $tag=~$_ } @{^ASSERTING}) {
	    $^H &= ~$hint;
	    return;
	}
    }
    $^H |= $hint;
}

sub unimport {
    $^H &= ~$hint;
}

1;
__END__


=head1 NAME

assertions - selects assertions

=head1 SYNOPSIS

  sub assert (&) : assertion { &{$_[0]}() }

  use assertions 'foo';
  assert { print "asserting 'foo'\n" };

  {
      use assertions qw( foo bar );
      assert { print "asserting 'foo' & 'bar'\n" };
  }

  {
      use assertions qw( bar );
      assert { print "asserting 'bar'\n" };
  }

  {
      use assertions qw( & bar );
      assert { print "asserting 'foo' & 'bar'\n" };
  }

  assert { print "asserting 'foo' again\n" };


=head1 ABSTRACT

C<assertions> pragma selects the tags used to control assertion
execution.

=head1 DESCRIPTION




=head2 EXPORT

None by default.

=head1 SEE ALSO



=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
