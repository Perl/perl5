package ExtUtils::CBuilder::Platform::Unix;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(ExtUtils::CBuilder::Base);

sub link {
  my $self = shift;
  my $cf = $self->{config};
  
  # Some platforms (notably Mac OS X 10.3, but some others too) expect
  # the syntax "FOO=BAR /bin/command arg arg" to work in %Config
  # (notably $Config{ld}).  It usually works in system(SCALAR), but we
  # use system(LIST). We fix it up here with 'env'.
  
  local $cf->{ld} = $cf->{ld};
  if (ref $cf->{ld}) {
    unshift @{$cf->{ld}}, 'env' if $cf->{ld}[0] =~ /^\s*\w+=/;
  } else {
    $cf->{ld} =~ s/^(\s*\w+=)/env $1/;
  }
  
  return $self->SUPER::link(@_);
}

1;
