package File::Spec::Win32;

use strict;
use vars qw(@ISA);
require File::Spec::Unix;
@ISA = qw(File::Spec::Unix);

=head1 NAME

File::Spec::Win32 - methods for Win32 file specs

=head1 SYNOPSIS

 require File::Spec::Win32; # Done internally by File::Spec if needed

=head1 DESCRIPTION

See File::Spec::Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=over

=item devnull

Returns a string representation of the null device.

=cut

sub devnull {
    return "nul";
}

=item tmpdir

Returns a string representation of the first existing directory
from the following list:

    $ENV{TMPDIR}
    $ENV{TEMP}
    $ENV{TMP}
    /tmp
    /

=cut

my $tmpdir;
sub tmpdir {
    return $tmpdir if defined $tmpdir;
    my $self = shift;
    foreach (@ENV{qw(TMPDIR TEMP TMP)}, qw(/tmp /)) {
	next unless defined && -d;
	$tmpdir = $_;
	last;
    }
    $tmpdir = '' unless defined $tmpdir;
    $tmpdir = $self->canonpath($tmpdir);
    return $tmpdir;
}

sub file_name_is_absolute {
    my ($self,$file) = @_;
    return scalar($file =~ m{^([a-z]:)?[\\/]}i);
}

=item catfile

Concatenate one or more directory names and a filename to form a
complete path ending with a filename

=cut

sub catfile {
    my $self = shift;
    my $file = pop @_;
    return $file unless @_;
    my $dir = $self->catdir(@_);
    $dir .= "\\" unless substr($dir,-1) eq "\\";
    return $dir.$file;
}

sub path {
    local $^W = 1;
    my $path = $ENV{'PATH'} || $ENV{'Path'} || $ENV{'path'};
    my @path = split(';',$path);
    foreach (@path) { $_ = '.' if $_ eq '' }
    return @path;
}

=item canonpath

No physical check on the filesystem, but a logical cleanup of a
path. On UNIX eliminated successive slashes and successive "/.".

=cut

sub canonpath {
    my ($self,$path) = @_;
    $path =~ s/^([a-z]:)/\u$1/;
    $path =~ s|/|\\|g;
    $path =~ s|([^\\])\\+|\1\\|g;                  # xx////xx  -> xx/xx
    $path =~ s|(\\\.)+\\|\\|g;                     # xx/././xx -> xx/xx
    $path =~ s|^(\.\\)+|| unless $path eq ".\\";   # ./xx      -> xx
    $path =~ s|\\$||
             unless $path =~ m#^([A-Z]:)?\\#;      # xx/       -> xx
    return $path;
}

=back

=head1 SEE ALSO

L<File::Spec>

=cut

1;
