use strict; use warnings;

package ExpireTest;

my %cache;

sub TIEHASH {	
  my ($pack) = @_;
  bless \%cache => $pack;
}

sub EXISTS {
  my ($cache, $key) = @_;
  exists $cache->{$key} ? 1 : 0;
}

sub FETCH {
  my ($cache, $key) = @_;
  $cache->{$key};
}

sub STORE {
  my ($cache, $key, $val) = @_;
  $cache->{$key} = $val;
}

sub expire {
  my ($key) = @_;
  delete $cache{$key};
}

1;

__END__

=pod

=head1 NAME

ExpireTest - test for Memoize expiration semantics

=head1 DESCRIPTION

This module is just for testing expiration semantics.  It's not a very
good example of how to write an expiration module.

If you are looking for an example, I recommend that you look at the
simple example in the Memoize::Expire documentation, or at the code
for Memoize::Expire itself.

=cut
