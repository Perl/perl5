package ExtUtils::CBuilder::Platform::VMS;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw($VERSION @ISA);
$VERSION = '0.12';
@ISA = qw(ExtUtils::CBuilder::Base);

sub need_prelink { 0 }

sub arg_include_dirs {
  my $self = shift;
  return '/include=(' . join(',', @_) . ')';
}

sub arg_nolink { return; }

sub arg_object_file {
  my ($self, $file) = @_;
  return "/obj=$file";
}

sub arg_exec_file {
  my ($self, $file) = @_;
  return ("/exe=$file");
}

sub arg_share_object_file {
  my ($self, $file) = @_;
  return ("$self->{config}{lddlflags}=$file");
}

1;
