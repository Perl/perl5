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

=over

=item eliminate_macros

Expands MM[KS]/Make macros in a text string, using the contents of
identically named elements of C<%$self>, and returns the result
as a file specification in Unix syntax.

=cut

sub eliminate_macros {
    my($self,$path) = @_;
    return '' unless $path;
    $self = {} unless ref $self;
    my($npath) = unixify($path);
    my($complex) = 0;
    my($head,$macro,$tail);

    # perform m##g in scalar context so it acts as an iterator
    while ($npath =~ m#(.*?)\$\((\S+?)\)(.*)#g) { 
        if ($self->{$2}) {
            ($head,$macro,$tail) = ($1,$2,$3);
            if (ref $self->{$macro}) {
                if (ref $self->{$macro} eq 'ARRAY') {
                    $macro = join ' ', @{$self->{$macro}};
                }
                else {
                    print "Note: can't expand macro \$($macro) containing ",ref($self->{$macro}),
                          "\n\t(using MMK-specific deferred substitutuon; MMS will break)\n";
                    $macro = "\cB$macro\cB";
                    $complex = 1;
                }
            }
            else { ($macro = unixify($self->{$macro})) =~ s#/$##; }
            $npath = "$head$macro$tail";
        }
    }
    if ($complex) { $npath =~ s#\cB(.*?)\cB#\${$1}#g; }
    $npath;
}

=item fixpath

Catchall routine to clean up problem MM[SK]/Make macros.  Expands macros
in any directory specification, in order to avoid juxtaposing two
VMS-syntax directories when MM[SK] is run.  Also expands expressions which
are all macro, so that we can tell how long the expansion is, and avoid
overrunning DCL's command buffer when MM[KS] is running.

If optional second argument has a TRUE value, then the return string is
a VMS-syntax directory specification, if it is FALSE, the return string
is a VMS-syntax file specification, and if it is not specified, fixpath()
checks to see whether it matches the name of a directory in the current
default directory, and returns a directory or file specification accordingly.

=cut

sub fixpath {
    my($self,$path,$force_path) = @_;
    return '' unless $path;
    $self = bless {} unless ref $self;
    my($fixedpath,$prefix,$name);

    if ($path =~ m#^\$\([^\)]+\)$# || $path =~ m#[/:>\]]#) { 
        if ($force_path or $path =~ /(?:DIR\)|\])$/) {
            $fixedpath = vmspath($self->eliminate_macros($path));
        }
        else {
            $fixedpath = vmsify($self->eliminate_macros($path));
        }
    }
    elsif ((($prefix,$name) = ($path =~ m#^\$\(([^\)]+)\)(.+)#)) && $self->{$prefix}) {
        my($vmspre) = $self->eliminate_macros("\$($prefix)");
        # is it a dir or just a name?
        $vmspre = ($vmspre =~ m|/| or $prefix =~ /DIR$/) ? vmspath($vmspre) : '';
        $fixedpath = ($vmspre ? $vmspre : $self->{$prefix}) . $name;
        $fixedpath = vmspath($fixedpath) if $force_path;
    }
    else {
        $fixedpath = $path;
        $fixedpath = vmspath($fixedpath) if $force_path;
    }
    # No hints, so we try to guess
    if (!defined($force_path) and $fixedpath !~ /[:>(.\]]/) {
        $fixedpath = vmspath($fixedpath) if -d $fixedpath;
    }
    # Trim off root dirname if it's had other dirs inserted in front of it.
    $fixedpath =~ s/\.000000([\]>])/$1/;
    $fixedpath;
}

=back

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

=item splitpath

    ($volume,$directories,$file) = File::Spec->splitpath( $path );
    ($volume,$directories,$file) = File::Spec->splitpath( $path, $no_file );

Splits a VMS path in to volume, directory, and filename portions.
Ignores $no_file, if present, since VMS paths indicate the 'fileness' of a 
file.

The results can be passed to L</catpath()> to get back a path equivalent to
(usually identical to) the original path.

=cut

sub splitpath {
    my $self = shift ;
    my ($path, $nofile) = @_;

    my ($volume,$directory,$file) ;

    if ( $path =~ m{/} ) {
        $path =~ 
            m{^ ( (?: /[^/]* )? )
                ( (?: .*/(?:[^/]+.dir)? )? )
                (.*)
             }x;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }
    else {
        $path =~ 
            m{^ ( (?: (?: (?: [\w\$-]+ (?: "[^"]*")?:: )? [\w\$-]+: )? ) )
                ( (?:\[.*\])? )
                (.*)
             }x;
        $volume    = $1;
        $directory = $2;
        $file      = $3;
    }

    $directory = $1
        if $directory =~ /^\[(.*)\]$/ ;

    return ($volume,$directory,$file);
}


=item splitdir

The opposite of L</catdir()>.

    @dirs = File::Spec->splitdir( $directories );

$directories must be only the directory portion of the path.

'[' and ']' delimiters are optional. An empty string argument is
equivalent to '[]': both return an array with no elements.

=cut

sub splitdir {
    my $self = shift ;
    my $directories = $_[0] ;

    return File::Spec::Unix::splitdir( $self, @_ )
        if ( $directories =~ m{/} ) ;

    $directories =~ s/^\[(.*)\]$/$1/ ;

    #
    # split() likes to forget about trailing null fields, so here we
    # check to be sure that there will not be any before handling the
    # simple case.
    #
    if ( $directories !~ m{\.$} ) {
        return split( m{\.}, $directories );
    }
    else {
        #
        # since there was a trailing separator, add a file name to the end, 
        # then do the split, then replace it with ''.
        #
        my( @directories )= split( m{\.}, "${directories}dummy" ) ;
        $directories[ $#directories ]= '' ;
        return @directories ;
    }
}


sub catpath {
    my $self = shift;

    return File::Spec::Unix::catpath( $self, @_ )
        if ( join( '', @_ ) =~ m{/} ) ;

    my ($volume,$directory,$file) = @_;

    $volume .= ':'
        if $volume =~ /[^:]$/ ;

    $directory = "[$directory"
        if $directory =~ /^[^\[]/ ;

    $directory .= ']'
        if $directory =~ /[^\]]$/ ;

    return "$volume$directory$file" ;
}


sub abs2rel {
    my $self = shift;

    return File::Spec::Unix::abs2rel( $self, @_ )
        if ( join( '', @_ ) =~ m{/} ) ;

    my($path,$base) = @_;

    # Note: we use '/' to glue things together here, then let canonpath()
    # clean them up at the end.

    # Clean up $path
    if ( ! $self->file_name_is_absolute( $path ) ) {
        $path = $self->rel2abs( $path ) ;
    }
    else {
        $path = $self->canonpath( $path ) ;
    }

    # Figure out the effective $base and clean it up.
    if ( ! $self->file_name_is_absolute( $base ) ) {
        $base = $self->rel2abs( $base ) ;
    }
    elsif ( !defined( $base ) || $base eq '' ) {
        $base = cwd() ;
    }
    else {
        $base = $self->canonpath( $base ) ;
    }

    # Split up paths
    my ( undef, $path_directories, $path_file ) =
        $self->splitpath( $path, 1 ) ;

    $path_directories = $1
        if $path_directories =~ /^\[(.*)\]$/ ;

    my ( undef, $base_directories, undef ) =
        $self->splitpath( $base, 1 ) ;

    $base_directories = $1
        if $base_directories =~ /^\[(.*)\]$/ ;

    # Now, remove all leading components that are the same
    my @pathchunks = $self->splitdir( $path_directories );
    my @basechunks = $self->splitdir( $base_directories );

    while ( @pathchunks && 
            @basechunks && 
            lc( $pathchunks[0] ) eq lc( $basechunks[0] ) 
          ) {
        shift @pathchunks ;
        shift @basechunks ;
    }

    # @basechunks now contains the directories to climb out of,
    # @pathchunks now has the directories to descend in to.
    $path_directories = '-.' x @basechunks . join( '.', @pathchunks ) ;
    $path_directories =~ s{\.$}{} ;
    return $self->catpath( '', $path_directories, $path_file ) ;
}


sub rel2abs($;$;) {
    my $self = shift ;
    return File::Spec::Unix::rel2abs( $self, @_ )
        if ( join( '', @_ ) =~ m{/} ) ;

    my ($path,$base ) = @_;
    # Clean up and split up $path
    if ( ! $self->file_name_is_absolute( $path ) ) {
        # Figure out the effective $base and clean it up.
        if ( !defined( $base ) || $base eq '' ) {
            $base = cwd() ;
        }
        elsif ( ! $self->file_name_is_absolute( $base ) ) {
            $base = $self->rel2abs( $base ) ;
        }
        else {
            $base = $self->canonpath( $base ) ;
        }

        # Split up paths
        my ( undef, $path_directories, $path_file ) =
            $self->splitpath( $path ) ;

        my ( $base_volume, $base_directories, undef ) =
            $self->splitpath( $base ) ;

        my $sep = '' ;
        $sep = '.'
            if ( $base_directories =~ m{[^.]$} &&
                 $path_directories =~ m{^[^.]}
            ) ;
        $base_directories = "$base_directories$sep$path_directories" ;

        $path = $self->catpath( $base_volume, $base_directories, $path_file );
   }

    return $self->canonpath( $path ) ;
}


=back

=head1 SEE ALSO

L<File::Spec>

=cut

1;
