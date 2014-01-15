package ExtUtils::CBuilder::Platform::android;

use strict;
use File::Spec;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw($VERSION @ISA);
$VERSION = '0.280212';
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

# The Android linker will not recognize symbols from
# libperl unless the module explicitly depends on it.
sub link {
  my ($self, %args) = @_;

  if ($self->{config}{useshrplib}) {
    $args{extra_linker_flags} = [
      $self->split_like_shell($args{extra_linker_flags}),
      '-L' . $self->perl_inc(),
      '-lperl',
    ];
  }

  return $self->SUPER::link(%args);
}

1;
