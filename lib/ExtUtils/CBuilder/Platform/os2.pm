package ExtUtils::CBuilder::Platform::os2;

use strict;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw($VERSION @ISA);
$VERSION = '0.13';
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub need_prelink { 1 }

sub prelink {
  # Generate import libraries (XXXX currently near .DEF; should be near DLL!)
  my $self = shift;
  my @res = $self->SUPER::prelink(@_);
  die "Unexpected number of DEF files" unless @res == 1;
  die "Can't find DEF file in the output"
    unless $res[0] =~ m,^(.*?)([^\\/]+)\.def$,si;
  my $libname = "$2$self->{config}{lib_ext}";
  $self->do_system('emximp', '-o', $libname, $res[0]) or die "emxexp: res=$?";
  return (@res, $libname);
}

sub _do_link {
  # Some 'env' do exec(), thus return too early when run from ksh;
  # To avoid 'env', remove (useless) shrpenv
  my $self = shift;
  local $self->{config}{shrpenv} = '';
  return $self->SUPER::_do_link(@_);
}

sub extra_link_args_after_prelink {	# Add .DEF file to the link line
  my ($self, %args) = @_;
  grep /\.def$/i, @{$args{prelink_res}};
}

sub link_executable {
  # ldflags is not expecting .exe extension given on command line; remove -Zexe
  my $self = shift;
  local $self->{config}{ldflags} = $self->{config}{ldflags};
  $self->{config}{ldflags} =~ s/(?<!\S)-Zexe(?!\S)//;
  return $self->SUPER::link_executable(@_);
}


1;
