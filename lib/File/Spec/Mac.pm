package File::Spec::Mac;

use strict;
use vars qw(@ISA $VERSION);
require File::Spec::Unix;

$VERSION = '1.2';

@ISA = qw(File::Spec::Unix);

use Cwd;

=head1 NAME

File::Spec::Mac - File::Spec for MacOS

=head1 SYNOPSIS

 require File::Spec::Mac; # Done internally by File::Spec if needed

=head1 DESCRIPTION

Methods for manipulating file specifications.

=head1 METHODS

=over 2

=item canonpath

On MacOS, there's nothing to be done.  Returns what it's given.

=cut

sub canonpath {
    my ($self,$path) = @_;
    return $path;
}

=item catdir

Concatenate two or more directory names to form a path separated by colons
(":") ending with a directory.  Automatically puts a trailing ":" on the
end of the complete path, because that's what's done in MacPerl's
environment and helps to distinguish a file path from a directory path.

The intended purpose of this routine is to concatenate I<directory names>.
But because of the nature of Macintosh paths, some additional possibilities
are allowed to make using this routine give reasonable results for some
common situations. In other words, you are also allowed to concatenate
I<paths> instead of directory names (strictly speaking, a string like ":a"
is a path, but not a name, since it contains a punctuation character ":").

Here are the rules that are used: Each argument has its trailing ":" removed.
Each argument, except the first, has its leading ":" removed.  They are then
joined together by a ":" and a trailing ":" is added to the path.

So, beside calls like

    File::Spec->catdir("a") = "a:"
    File::Spec->catdir("a","b") = "a:b:"
    File::Spec->catdir("","a","b") = ":a:b:"
    File::Spec->catdir("a","","b") = "a::b:"
    File::Spec->catdir("") = ":"
    File::Spec->catdir("a","b","") = "a:b::"     (!)
    File::Spec->catdir() = ""                    (special case)

calls like the following

    File::Spec->catdir("a:",":b") = "a:b:"
    File::Spec->catdir("a:b:",":c") = "a:b:c:"
    File::Spec->catdir("a:","b") = "a:b:"
    File::Spec->catdir("a",":b") = "a:b:"
    File::Spec->catdir(":a","b") = ":a:b:"
    File::Spec->catdir("","",":a",":b") = "::a:b:"
    File::Spec->catdir("",":a",":b") = ":a:b:" (!)
    File::Spec->catdir(":") = ":"

are allowed.

To get a path beginning with a ":" (a relative path), put a "" as the first
argument. Beginning the first argument with a ":" (e.g. ":a") will also work
(see the examples).

Since Mac OS (Classic) uses the concept of volumes, there is an ambiguity:
Does the first argument in

    File::Spec->catdir("LWP","Protocol");

denote a volume or a directory, i.e. should the path be relative or absolute?
There is no way of telling except by checking for the existence of "LWP:" (a
volume) or ":LWP" (a directory), but those checks aren't made here. Thus, according
to the above rules, the path "LWP:Protocol:" will be returned, which, considered
alone, is an absolute path, although the volume "LWP:" may not exist. Hence, don't
forget to put a ":" in the appropriate place in the path if you want to
distinguish unambiguously. (Remember that a valid relative path should always begin
with a ":", unless you are specifying a file or a directory that resides in the
I<current> directory. In that case, the leading ":" is not mandatory.)

With version 1.2 of File::Spec, there's a new method called C<catpath>, that
takes volume, directory and file portions and returns an entire path (see below).
While C<catdir> is still suitable for the concatenation of I<directory names>,
you should consider using C<catpath> to concatenate I<volume names> and
I<directory paths>, because it avoids any ambiguities. E.g.

    $dir      = File::Spec->catdir("LWP","Protocol");
    $abs_path = File::Spec->catpath("MacintoshHD:", $dir, "");

yields

    "MacintoshHD:LWP:Protocol:" .


=cut

sub catdir {
    my $self = shift;
    return '' unless @_;
    my @args = @_;
    my $result = shift @args;
    #  To match the actual end of the string,
    #  not ignoring newline, you can use \Z(?!\n).
    $result =~ s/:\Z(?!\n)//;
    foreach (@args) {
	s/:\Z(?!\n)//;
	s/^://s;
	$result .= ":$_";
    }
    return "$result:";
}

=item catfile

Concatenate one or more directory names and a filename to form a
complete path ending with a filename.  Since this uses catdir, the
same caveats apply.  Note that the leading ":" is removed from the
filename, so that

    File::Spec->catfile("a", "b", "file"); # = "a:b:file"

and

    File::Spec->catfile("a", "b", ":file"); # = "a:b:file"

give the same answer, as one might expect. To concatenate I<volume names>,
I<directory paths> and I<filenames>, you should consider using C<catpath>
(see below).

=cut

sub catfile {
    my $self = shift;
    return '' unless @_;
    my $file = pop @_;
    return $file unless @_;
    my $dir = $self->catdir(@_);
    $file =~ s/^://s;
    return $dir.$file;
}

=item curdir

Returns a string representing the current directory. On Mac OS, this is ":".

=cut

sub curdir {
    return ":";
}

=item devnull

Returns a string representing the null device. On Mac OS, this is "Dev:Null".

=cut

sub devnull {
    return "Dev:Null";
}

=item rootdir

Returns a string representing the root directory.  Under MacPerl,
returns the name of the startup volume, since that's the closest in
concept, although other volumes aren't rooted there. The name has a
trailing ":", because that's the correct specification for a volume
name on Mac OS.

=cut

sub rootdir {
#
#  There's no real root directory on MacOS.  The name of the startup
#  volume is returned, since that's the closest in concept.
#
    require Mac::Files;
    my $system =  Mac::Files::FindFolder(&Mac::Files::kOnSystemDisk,
					 &Mac::Files::kSystemFolderType);
    $system =~ s/:.*\Z(?!\n)/:/s;
    return $system;
}

=item tmpdir

Returns the contents of $ENV{TMPDIR}, if that directory exits or the current working
directory otherwise. Under MacPerl, $ENV{TMPDIR} will contain a path like
"MacintoshHD:Temporary Items:", which is a hidden directory on your startup volume.

=cut

my $tmpdir;
sub tmpdir {
    return $tmpdir if defined $tmpdir;
    $tmpdir = $ENV{TMPDIR} if -d $ENV{TMPDIR};
    unless (defined($tmpdir)) {
   	$tmpdir = cwd();
    }
    return $tmpdir;
}

=item updir

Returns a string representing the parent directory. On Mac OS, this is "::".

=cut

sub updir {
    return "::";
}

=item file_name_is_absolute

Takes as argument a path and returns true, if it is an absolute path.
This does not consult the local filesystem. If
the path has a leading ":", it's a relative path. Otherwise, it's an
absolute path, unless the path doesn't contain any colons, i.e. it's a name
like "a". In this particular case, the path is considered to be relative
(i.e. it is considered to be a filename). Use ":" in the appropriate place
in the path if you want to distinguish unambiguously. As a special case,
the filename '' is always considered to be absolute.

E.g.

    File::Spec->file_name_is_absolute("a");             # false (relative)
    File::Spec->file_name_is_absolute(":a:b:");         # false (relative)
    File::Spec->file_name_is_absolute("MacintoshHD:");  # true (absolute)
    File::Spec->file_name_is_absolute("");              # true (absolute)


=cut

sub file_name_is_absolute {
    my ($self,$file) = @_;
    if ($file =~ /:/) {
	return (! ($file =~ m/^:/s) );
    } elsif ( $file eq '' ) {
        return 1 ;
    } else {
	return 0; # i.e. a file like "a"
    }
}

=item path

Returns the null list for the MacPerl application, since the concept is
usually meaningless under MacOS. But if you're using the MacPerl tool under
MPW, it gives back $ENV{Commands} suitably split, as is done in
:lib:ExtUtils:MM_Mac.pm.

=cut

sub path {
#
#  The concept is meaningless under the MacPerl application.
#  Under MPW, it has a meaning.
#
    return unless exists $ENV{Commands};
    return split(/,/, $ENV{Commands});
}

=item splitpath

    ($volume,$directories,$file) = File::Spec->splitpath( $path );
    ($volume,$directories,$file) = File::Spec->splitpath( $path, $no_file );

Splits a path in to volume, directory, and filename portions.

On Mac OS, assumes that the last part of the path is a filename unless
$no_file is true or a trailing separator ":" is present.

The volume portion is always returned with a trailing ":". The directory portion
is always returned with a leading (to denote a relative path) and a trailing ":"
(to denote a directory). The file portion is always returned I<without> a leading ":".
Empty portions are returned as "".

The results can be passed to L</catpath()> to get back a path equivalent to
(usually identical to) the original path.


=cut

sub splitpath {
    my ($self,$path, $nofile) = @_;
    my ($volume,$directory,$file);

    if ( $nofile ) {
        ( $volume, $directory ) = $path =~ m|^((?:[^:]+:)?)(.*)|s;
    }
    else {
        $path =~
            m|^( (?: [^:]+: )? )
               ( (?: .*: )? )
               ( .* )
             |xs;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }

    $volume = '' unless defined($volume);
	$directory = ":$directory" if ( $volume && $directory ); # take care of "HD::dir"
    if ($directory) {
        # Make sure non-empty directories begin and end in ':'
        $directory .= ':' unless (substr($directory,-1) eq ':');
        $directory = ":$directory" unless (substr($directory,0,1) eq ':');
    } else {
	$directory = '';
    }
    $file = '' unless defined($file);

    return ($volume,$directory,$file);
}


=item splitdir

The opposite of L</catdir()>.

    @dirs = File::Spec->splitdir( $directories );

$directories must be only the directory portion of the path on systems
that have the concept of a volume or that have path syntax that differentiates
files from directories.

Unlike just splitting the directories on the separator, empty directory names
(C<"">) can be returned. Since C<catdir()> on Mac OS always appends a trailing
colon to distinguish a directory path from a file path, a single trailing colon
will be ignored, i.e. there's no empty directory name after it.

Hence, on Mac OS, both

    File::Spec->splitdir( ":a:b::c:" );    and
    File::Spec->splitdir( ":a:b::c" );

yield:

    ( "", "a", "b", "", "c")

while

    File::Spec->splitdir( ":a:b::c::" );

yields:

    ( "", "a", "b", "", "c", "")


=cut

sub splitdir {
    my ($self,$directories) = @_ ;

    if ($directories =~ /^:*\Z(?!\n)/) {
	# dir is an empty string or a colon path like ':', i.e. the
	# current dir, or '::', the parent dir, etc. We return that
	# dir (as is done on Unix).
	return $directories;
    }

    # remove a trailing colon, if any (this way, splitdir is the
    # opposite of catdir, which automatically appends a ':')
    $directories =~ s/:\Z(?!\n)//;

    #
    # split() likes to forget about trailing null fields, so here we
    # check to be sure that there will not be any before handling the
    # simple case.
    #
    if ( $directories !~ m@:\Z(?!\n)@ ) {
        return split( m@:@, $directories );
    }
    else {
        #
        # since there was a trailing separator, add a file name to the end,
        # then do the split, then replace it with ''.
        #
        my( @directories )= split( m@:@, "${directories}dummy" ) ;
        $directories[ $#directories ]= '' ;
        return @directories ;
    }
}


=item catpath

    $path = File::Spec->catpath($volume,$directory,$file);

Takes volume, directory and file portions and returns an entire path. On Mac OS,
$volume, $directory and $file are concatenated.  A ':' is inserted if need be. You
may pass an empty string for each portion. If all portions are empty, the empty
string is returned. If $volume is empty, the result will be a relative path,
beginning with a ':'. If $volume and $directory are empty, a leading ":" (if any)
is removed form $file and the remainder is returned. If $file is empty, the
resulting path will have a trailing ':'.


=cut

sub catpath {
    my ($self,$volume,$directory,$file) = @_;

    if ( (! $volume) && (! $directory) ) {
	$file =~ s/^:// if $file;
	return $file ;
    }

    my $path = $volume; # may be ''
    $path .= ':' unless (substr($path, -1) eq ':'); # ensure trailing ':'

    if ($directory) {
	$directory =~ s/^://; # remove leading ':' if any
	$path .= $directory;
	$path .= ':' unless (substr($path, -1) eq ':'); # ensure trailing ':'
    }

    if ($file) {
	$file =~ s/^://; # remove leading ':' if any
	$path .= $file;
    }

    return $path;
}

=item abs2rel

Takes a destination path and an optional base path and returns a relative path
from the base path to the destination path:

    $rel_path = File::Spec->abs2rel( $path ) ;
    $rel_path = File::Spec->abs2rel( $path, $base ) ;

Note that both paths are assumed to have a notation that distinguishes a
directory path (with trailing ':') from a file path (without trailing ':').

If $base is not present or '', then the current working directory is used.
If $base is relative, then it is converted to absolute form using C<rel2abs()>.
This means that it is taken to be relative to the current working directory.

Since Mac OS has the concept of volumes, this assumes that both paths
are on the $destination volume, and ignores the $base volume (!).

If $base doesn't have a trailing colon, the last element of $base is
assumed to be a filename. This filename is ignored (!). Otherwise all path
components are assumed to be directories.

If $path is relative, it is converted to absolute form using C<rel2abs()>.
This means that it is taken to be relative to the current working directory.

Based on code written by Shigio Yamaguchi.


=cut

# maybe this should be done in canonpath() ?
sub _resolve_updirs {
	my $path = shift @_;
	my $proceed;

	# resolve any updirs, e.g. "HD:tmp::file" -> "HD:file"
	do {
		$proceed = ($path =~ s/^(.*):[^:]+::(.*?)\z/$1:$2/);
	} while ($proceed);

	return $path;
}


sub abs2rel {
    my($self,$path,$base) = @_;

    # Clean up $path
    if ( ! $self->file_name_is_absolute( $path ) ) {
        $path = $self->rel2abs( $path ) ;
    }

    # Figure out the effective $base and clean it up.
    if ( !defined( $base ) || $base eq '' ) {
	$base = cwd();
    }
    elsif ( ! $self->file_name_is_absolute( $base ) ) {
        $base = $self->rel2abs( $base ) ;
	$base = _resolve_updirs( $base ); # resolve updirs in $base
    }
    else {
	$base = _resolve_updirs( $base );
    }

    # Split up paths
    my ( $path_dirs, $path_file ) =  ($self->splitpath( $path ))[1,2] ;

    # ignore $base's volume and file
    my $base_dirs = ($self->splitpath( $base ))[1] ;

    # Now, remove all leading components that are the same
    my @pathchunks = $self->splitdir( $path_dirs );
    my @basechunks = $self->splitdir( $base_dirs );

    while ( @pathchunks &&
	    @basechunks &&
	    lc( $pathchunks[0] ) eq lc( $basechunks[0] ) ) {
        shift @pathchunks ;
        shift @basechunks ;
    }

    # @pathchunks now has the directories to descend in to.
    $path_dirs = $self->catdir( @pathchunks );

    # @basechunks now contains the number of directories to climb out of.
    $base_dirs = (':' x @basechunks) . ':' ;

    return $self->catpath( '', $base_dirs . $path_dirs, $path_file ) ;
}

=item rel2abs

Converts a relative path to an absolute path:

    $abs_path = File::Spec->rel2abs( $path ) ;
    $abs_path = File::Spec->rel2abs( $path, $base ) ;

Note that both paths are assumed to have a notation that distinguishes a
directory path (with trailing ':') from a file path (without trailing ':').

If $base is not present or '', then $base is set to the current working
directory. If $base is relative, then it is converted to absolute form
using C<rel2abs()>. This means that it is taken to be relative to the
current working directory.

If $base doesn't have a trailing colon, the last element of $base is
assumed to be a filename. This filename is ignored (!). Otherwise all path
components are assumed to be directories.

If $path is already absolute, it is returned and $base is ignored.

Based on code written by Shigio Yamaguchi.

=cut

sub rel2abs {
    my ($self,$path,$base) = @_;

    if ( ! $self->file_name_is_absolute($path) ) {
        # Figure out the effective $base and clean it up.
        if ( !defined( $base ) || $base eq '' ) {
	    $base = cwd();
        }
        elsif ( ! $self->file_name_is_absolute($base) ) {
            $base = $self->rel2abs($base) ;
        }

	# Split up paths

	# igonore $path's volume
        my ( $path_dirs, $path_file ) = ($self->splitpath($path))[1,2] ;

        # ignore $base's file part
	my ( $base_vol, $base_dirs, undef ) = $self->splitpath($base) ;

	# Glom them together
	$path_dirs = ':' if ($path_dirs eq '');
	$base_dirs =~ s/:$//; # remove trailing ':', if any
	$base_dirs = $base_dirs . $path_dirs;

        $path = $self->catpath( $base_vol, $base_dirs, $path_file );
    }
    return $path;
}


=back

=head1 AUTHORS

See the authors list in L<File::Spec>. Mac OS support by Paul Schinder
<schinder@pobox.com> and Thomas Wegner <wegner_thomas@yahoo.com>.


=head1 SEE ALSO

L<File::Spec>

=cut

1;
