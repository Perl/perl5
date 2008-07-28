package ExtUtils::CBuilder::Platform::cygwin;

use strict;
use File::Spec;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw($VERSION @ISA);
$VERSION = '0.23';
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub link_executable {
  my $self = shift;
  # $Config{ld} is okay. revert the stupid Unix cc=ld override
  local $self->{config}{cc} = $self->{config}{ld};
  return $self->SUPER::link_executable(@_);
}

sub link {
  my ($self, %args) = @_;
  # libperl.dll.a fails with -Uusedl. -L../CORE -lperl is better
  $args{extra_linker_flags} = [
    '-L'.$self->perl_inc().' -lperl',
    $self->split_like_shell($args{extra_linker_flags})
  ];

  return $self->SUPER::link(%args);
}

1;
