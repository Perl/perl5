package File::Spec::Unix;

use strict;

=head1 NAME

File::Spec::Unix - methods used by File::Spec

=head1 SYNOPSIS

 require File::Spec::Unix; # Done automatically by File::Spec

=head1 DESCRIPTION

Methods for manipulating file specifications.

=head1 METHODS

=over 2

=item canonpath

No physical check on the filesystem, but a logical cleanup of a
path. On UNIX eliminated successive slashes and successive "/.".

=cut

sub canonpath {
    my ($self,$path) = @_;
    $path =~ s|/+|/|g;                             # xx////xx  -> xx/xx
    $path =~ s|(/\.)+/|/|g;                        # xx/././xx -> xx/xx
    $path =~ s|^(\./)+|| unless $path eq "./";     # ./xx      -> xx
    $path =~ s|/$|| unless $path eq "/";           # xx/       -> xx
    return $path;
}

=item catdir

Concatenate two or more directory names to form a complete path ending
with a directory. But remove the trailing slash from the resulting
string, because it doesn't look good, isn't necessary and confuses
OS2. Of course, if this is the root directory, don't cut off the
trailing slash :-)

=cut

sub catdir {
    my $self = shift;
    my @args = @_;
    foreach (@args) {
	# append a slash to each argument unless it has one there
	$_ .= "/" if $_ eq '' || substr($_,-1) ne "/";
    }
    return $self->canonpath(join('', @args));
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
    $dir .= "/" unless substr($dir,-1) eq "/";
    return $dir.$file;
}

=item curdir

Returns a string representation of the current directory.  "." on UNIX.

=cut

sub curdir {
    return ".";
}

=item devnull

Returns a string representation of the null device. "/dev/null" on UNIX.

=cut

sub devnull {
    return "/dev/null";
}

=item rootdir

Returns a string representation of the root directory.  "/" on UNIX.

=cut

sub rootdir {
    return "/";
}

=item tmpdir

Returns a string representation of the first writable directory
from the following list or "" if none are writable:

    $ENV{TMPDIR}
    /tmp

=cut

my $tmpdir;
sub tmpdir {
    return $tmpdir if defined $tmpdir;
    foreach ($ENV{TMPDIR}, "/tmp") {
	next unless defined && -d && -w _;
	$tmpdir = $_;
	last;
    }
    $tmpdir = '' unless defined $tmpdir;
    return $tmpdir;
}

=item updir

Returns a string representation of the parent directory.  ".." on UNIX.

=cut

sub updir {
    return "..";
}

=item no_upwards

Given a list of file names, strip out those that refer to a parent
directory. (Does not strip symlinks, only '.', '..', and equivalents.)

=cut

sub no_upwards {
    my $self = shift;
    return grep(!/^\.{1,2}$/, @_);
}

=item file_name_is_absolute

Takes as argument a path and returns true, if it is an absolute path.

=cut

sub file_name_is_absolute {
    my ($self,$file) = @_;
    return scalar($file =~ m:^/:);
}

=item path

Takes no argument, returns the environment variable PATH as an array.

=cut

sub path {
    my @path = split(':', $ENV{PATH});
    foreach (@path) { $_ = '.' if $_ eq '' }
    return @path;
}

=item join

join is the same as catfile.

=cut

sub join {
    my $self = shift;
    return $self->catfile(@_);
}

=back

=head1 SEE ALSO

L<File::Spec>

=cut

1;
