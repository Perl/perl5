package File::Spec::VMS;

use strict;
use vars qw(@ISA);
require File::Spec::Unix;
@ISA = qw(File::Spec::Unix);

use File::Basename;
use VMS::Filespec;

=head1 NAME

File::Spec::VMS - methods for VMS file specs

=head1 SYNOPSIS

 require File::Spec::VMS; # Done internally by File::Spec if needed

=head1 DESCRIPTION

See File::Spec::Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=head2 Methods always loaded

=over

=item catdir

Concatenates a list of file specifications, and returns the result as a
VMS-syntax directory specification.

=cut

sub catdir {
    my ($self,@dirs) = @_;
    my $dir = pop @dirs;
    @dirs = grep($_,@dirs);
    my $rslt;
    if (@dirs) {
	my $path = (@dirs == 1 ? $dirs[0] : $self->catdir(@dirs));
	my ($spath,$sdir) = ($path,$dir);
	$spath =~ s/.dir$//; $sdir =~ s/.dir$//; 
	$sdir = $self->eliminate_macros($sdir) unless $sdir =~ /^[\w\-]+$/;
	$rslt = $self->fixpath($self->eliminate_macros($spath)."/$sdir",1);
    }
    else {
	if ($dir =~ /^\$\([^\)]+\)$/) { $rslt = $dir; }
	else                          { $rslt = vmspath($dir); }
    }
    return $rslt;
}

=item catfile

Concatenates a list of file specifications, and returns the result as a
VMS-syntax directory specification.

=cut

sub catfile {
    my ($self,@files) = @_;
    my $file = pop @files;
    @files = grep($_,@files);
    my $rslt;
    if (@files) {
	my $path = (@files == 1 ? $files[0] : $self->catdir(@files));
	my $spath = $path;
	$spath =~ s/.dir$//;
	if ($spath =~ /^[^\)\]\/:>]+\)$/ && basename($file) eq $file) {
	    $rslt = "$spath$file";
	}
	else {
	    $rslt = $self->eliminate_macros($spath);
	    $rslt = vmsify($rslt.($rslt ? '/' : '').unixify($file));
	}
    }
    else { $rslt = vmsify($file); }
    return $rslt;
}

=item curdir (override)

Returns a string representation of the current directory: '[]'

=cut

sub curdir {
    return '[]';
}

=item devnull (override)

Returns a string representation of the null device: '_NLA0:'

=cut

sub devnull {
    return "_NLA0:";
}

=item rootdir (override)

Returns a string representation of the root directory: 'SYS$DISK:[000000]'

=cut

sub rootdir {
    return 'SYS$DISK:[000000]';
}

=item tmpdir (override)

Returns a string representation of the first writable directory
from the following list or '' if none are writable:

    /sys$scratch
    $ENV{TMPDIR}

=cut

my $tmpdir;
sub tmpdir {
    return $tmpdir if defined $tmpdir;
    foreach ('/sys$scratch', $ENV{TMPDIR}) {
	next unless defined && -d && -w _;
	$tmpdir = $_;
	last;
    }
    $tmpdir = '' unless defined $tmpdir;
    return $tmpdir;
}

=item updir (override)

Returns a string representation of the parent directory: '[-]'

=cut

sub updir {
    return '[-]';
}

=item path (override)

Translate logical name DCL$PATH as a searchlist, rather than trying
to C<split> string value of C<$ENV{'PATH'}>.

=cut

sub path {
    my (@dirs,$dir,$i);
    while ($dir = $ENV{'DCL$PATH;' . $i++}) { push(@dirs,$dir); }
    return @dirs;
}

=item file_name_is_absolute (override)

Checks for VMS directory spec as well as Unix separators.

=cut

sub file_name_is_absolute {
    my ($self,$file) = @_;
    # If it's a logical name, expand it.
    $file = $ENV{$file} while $file =~ /^[\w\$\-]+$/ && $ENV{$file};
    return scalar($file =~ m!^/!              ||
		  $file =~ m![<\[][^.\-\]>]!  ||
		  $file =~ /:[^<\[]/);
}

=back

=head1 SEE ALSO

L<File::Spec>

=cut

1;
