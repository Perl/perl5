#
# Copyright (c) 1996, 1997, 1998 Shigio Yamaguchi. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#       File::PathConvert.pm
#

package File::PathConvert;
require 5.002;

use strict ;

BEGIN {
   use Exporter   ();
   use vars       qw($VERSION @ISA @EXPORT_OK);
   $VERSION       = 0.85;
   @ISA           = qw(Exporter);
   @EXPORT_OK     = qw(setfstype splitpath joinpath splitdirs joindirs realpat
 abs2rel rel2abs $maxsymlinks $verbose $SL $resolved );
}

use vars      qw( $maxsymlinks $verbose $SL $resolved ) ;
use Cwd;

#
# Initialize @EXPORT_OK vars
#
$maxsymlinks   = 32;       # allowed symlink number in a path
$verbose       = 0;        # 1: verbose on, 0: verbose off
$SL            = '' ;      # Separator char export
$resolved      = '' ;      # realpath() intermediate value export

#############################################################################
#
#  Package Globals
#

my $fstype        ; # A name indicating the type of filesystem currently in us

my $sep           ; # separator
my $sepRE         ; # RE to match spearator
my $notsepRE      ; # RE to match anything else
my $volumeRE      ; # RE to match the volume name
my $directoryRE   ; # RE to match the directory name
my $isrootRE      ; # RE to match root path: applied to directory portion only
my $thisDir       ; # Name of this directory
my $thisDirRE     ; # Name of this directory
my $parentDir     ; # Name of parent directory
my $parentDirRE   ; # RE to match parent dir name
my $casesensitive ; # Set to non-zero for case sensitive name comprisions.  On
y
                    # affects names, not any other REs, so $isrootRE for Win32
                    # must be case insensitive
my $idempotent    ; # Set to non-zero if '//' is equivalent to '/'.  This
                    # does not affect leading '//' and '\\' under Win32,
                    # but will fold '///' and '////', etc, in to '//' on this
                    # Win32



###########
#
# The following globals are regexs used in the indicated routines.  These
# are initialized by setfstype, so they don't need to be rebuilt each time
# the routine that uses them is called.

my $basenamesplitRE ; # Used in realpath() to split filenames.


###########
#
# This RE matches (and saves) the portion of the string that is just before
# the beginning of a name
#
my $beginning_of_name ;

#
# This whopper of an RE looks for the pattern "name/.." if it occurs
# after the beginning of the string or after the root RE, or after a separator

# We don't assume that the isrootRE has a trailing separator.
# It also makes sure that we aren't eliminating '../..' and './..' patterns
# by using the negative lookahead assertion '(?!' ... ')' construct.  It also
# ignores 'name/..name'.
#
my $name_sep_parentRE ;

#
# Matches '..$', '../' after a root
my $leading_parentRE ;

#
# Matches things like '/(./)+' and '^(./)+'
#
my $dot_sep_etcRE ;

#
# Matches trailing '/' or '/.'
#
my $trailing_sepRE ;


#############################################################################
#
#     Functions
#


#
# setfstype: takes the name of an operating system and sets up globals that
#            allow the other functions to operate on multiple OSs.  See
#            %fsconfig for the sets of settings.
#
#            This is run once on module load to configure for the OS named
#            in $^O.
#
# Interface:
#       i)     $osname, as in $^O or plain english: "MacOS", "DOS, etc.
#              This is _not_ usually case sensitive.
#       r)     Name of recognized name on success else undef.  Note that, as
#              shipped, 'unix' is the default is nothing else matches.
#       go)    $fstype and lots of internal parameters and regexs.
#       x)     Dies if a parameter required in @fsconfig is missing.
#
#
# There are some things I couldn't figure a way to parameterize by setting
# globals. $fstype is checked for filesystem type-specific logic, like
# VMS directory syntax.
#
# Setting up for a particular OS type takes two steps: identify the OS and
# set all of the 'atomic' global variables, then take some of the atomic
# globals which are regexps and build composite values from them.
#
# The atomic regexp terms are generally used to build the larger composite
# regexps that recognize and break apart paths.  This leads to
# two important rules for the atomic regexp terms:
#
# (1) Do not use '(' ... ')' in the regex terms, since they are used to build
# regexs that use '(' ... ')' to parse paths.
#
# (2) They must be built so that a '?' or other quantifier may be appended.
# This generally means using the '(?:' ... ')' or '[' ... ']' to group
# multicharacter patterns.  Other '(?' ... ')' may also do.
#
# The routines herein strive to preserve the
# original separator and root settings, and, it turns out, never need to
# prepend root to a string (although they do need to insert separators on
# occasion).  This is good, since the Win32 root expressions can be like
# '/', '\', 'A:/', 'a:/', or even '\\' or '//' for UNC style names.
#
# Note that the default root and default notsep are not used, and so are
# undefined.
#
# For DOS, MacOS, and VMS, we assume that all paths handed in are on the same
# volume.  This is not a significant limitation except for abs2rel, since the
# absolute path is assumed to be on the same volume as the base path.
#
sub setfstype($;) {
   my( $osname ) = @_ ;

   # Find the best match for OS and set up our atomic globals accordingly
   if ( $osname =~ /^(?:(ms)?(dos|win(32|nt)?))/i )
   {
      $fstype           = 'Win32' ;
      $sep              = '/' ;
      $sepRE            = '[\\\\/]' ;
      $notsepRE         = '[^\\\\/]' ;
      $volumeRE         = '(?:^(?:[a-zA-Z]:|(?:\\\\\\\\|//)[^\\\\/]+[\\\\/][^\
\\/]+)?)' ;
      $directoryRE      = '(?:(?:.*[\\\\/](?:\.\.?$)?)?)' ;
      $isrootRE         = '(?:^[\\\\/])' ;
      $thisDir          = '.' ;
      $thisDirRE        = '\.' ;
      $parentDir        = '..' ;
      $parentDirRE      = '(?:\.\.)' ;
      $casesensitive    = 0 ;
      $idempotent       = 1 ;
   }
   elsif ( $osname =~ /^MacOS$/i )
   {
      $fstype           = 'MacOS' ;
      $sep              = ':' ;
      $sepRE            = '\:' ;
      $notsepRE         = '[^:]' ;
      $volumeRE         = '(?:^(?:.*::)?)' ;
      $directoryRE      = '(?:(?:.*:)?)' ;
      $isrootRE         = '(?:^:)' ;
      $thisDir          = '.' ;
      $thisDirRE        = '\.' ;
      $parentDir        = '..' ;
      $parentDirRE      = '(?:\.\.)' ;
      $casesensitive    = 0 ;
      $idempotent       = 1 ;
   }
   elsif ( $osname =~ /^VMS$/i )
   {
      $fstype           = 'VMS' ;
      $sep              = '.' ;
      $sepRE            = '[\.\]]' ;
      $notsepRE         = '[^\.\]]' ;
      # volume is node::volume:, where node:: and volume: are optional
      # and node:: cannot be present without volume.  node can include
      # an access control string in double quotes.
      # Not supported:
      #     quoted full node names
      #     embedding a double quote in a string ("" to put " in)
      #     support ':' in node names
      #     foreign file specifications
      #     task specifications
      #     UIC Directory format (use the 6 digit name for it, instead)
      $volumeRE         = '(?:^(?:(?:[\w\$-]+(?:"[^"]*")?::)?[\w\$-]+:)?)' ;
      $directoryRE      = '(?:(?:\[.*\])?)' ;

      # Root is the lack of a leading '.', unless string is empty, which
      # means 'cwd', which is relative.
      $isrootRE         = '(?:^[^\.])' ;
      $thisDir          = '' ;
      $thisDirRE        = '\[\]' ;
      $parentDir        = '-' ;
      $parentDirRE      = '-' ;
      $casesensitive    = 0 ;
      $idempotent       = 0 ;
   }
   elsif ( $osname =~ /^URL$/i )
   {
      # URL spec based on RFC2396 (ftp://ftp.isi.edu/in-notes/rfc2396.txt)
      $fstype           = 'URL' ;
      $sep              = '/' ;
      $sepRE            = '/' ;
      $notsepRE         = '[^/]' ;
      # Volume= scheme + authority, both optional
      $volumeRE         = '(?:^(?:[a-zA-Z][a-zA-Z0-9+-.]*:)?(?://[^/?]*)?)' ;

      # Directories do _not_ include the query component: we pretend that
      # anything after a "?" is the filename or part of it.  So a '/'
      # terminates and is part of the directory spec, while a '?' or '#'
      # terminate and are not part of the directory spec.
      #
      # We pretend that ";param" syntax does not exist
      #
      $directoryRE      = '(?:(?:[^?#]*/(?:\.\.?(?:$|(?=[?#])))?)?)' ;
      $isrootRE         = '(?:^/)' ;
      $thisDir          = '.' ;
      $thisDirRE        = '\.' ;
      $parentDir        = '..' ;
      $parentDirRE      = '(?:\.\.)' ;
      # Assume case sensitive, since many (most?) are.  The user can override
      # this if they so desire.
      $casesensitive    = 1 ;
      $idempotent       = 1 ;
   }
   else
   {
      $fstype           = 'Unix' ;
      $sep              = '/' ;
      $sepRE            = '/' ;
      $notsepRE         = '[^/]' ;
      $volumeRE         = '' ;
      $directoryRE      = '(?:(?:.*/(?:\.\.?$)?)?)' ;
      $isrootRE         = '(?:^/)' ;
      $thisDir          = '.' ;
      $thisDirRE        = '\.' ;
      $parentDir        = '..' ;
      $parentDirRE      = '(?:\.\.)' ;
      $casesensitive    = 1 ;
      $idempotent       = 1 ;
   }

   # Now set our composite regexps.

   # Maintain old name for backward compatibility
   $SL= $sep ;

   # Build lots of REs used below, so they don't need to be built every time
   # the routines that use them are called.
   $basenamesplitRE   = '^(.*)' . $sepRE . '(' . $notsepRE . '*)$' ;

   $leading_parentRE  = '(' . $isrootRE . '?)(?:' . $parentDirRE . $sepRE . ')
(?:' . $parentDirRE . '$)?' ;
   $trailing_sepRE    = '(.)' . $sepRE . $thisDirRE . '?$' ;

   $beginning_of_name = '(?:^|' . $isrootRE . '|' . $sepRE . ')' ;

   $dot_sep_etcRE     =
      '(' . $beginning_of_name . ')(?:' . $thisDirRE . $sepRE . ')+';

   $name_sep_parentRE =
      '(' . $beginning_of_name . ')'
      . '(?!(?:' . $thisDirRE . '|' . $parentDirRE . ')' . $sepRE . ')'
      . $notsepRE . '+'
      . $sepRE . $parentDirRE
      . '(?:' . $sepRE . '|$)'
      ;

   if ( $verbose ) {
      print( <<TOHERE )  ;
fstype        = "$fstype"
sep           = "$sep"
sepRE         = /$sepRE/
notsepRE      = /$notsepRE/
volumeRE      = /$volumeRE/
directoryRE   = /$directoryRE/
isrootRE      = /$isrootRE/
thisDir       = "$thisDir"
thisDirRE     = /$thisDirRE/
parentDir     = "$parentDir"
parentDirRE   = /$parentDirRE/
casesensitive = "$casesensitive"
TOHERE
   }

   return $fstype ;
}


setfstype( $^O ) ;


#
# splitpath: Splits a path into component parts: volume, dirpath, and filename

#
#           Very much like File::Basename::fileparse(), but doesn't concern
#           itself with extensions and knows about volume names.
#
#           Returns ($volume, $directory, $filename ).
#
#           The contents of the returned list varies by operating system.
#
#           Unix:
#              $volume: always ''
#              $directory: up to, and including, final '/'
#              $filename: after final '/'
#
#           Win32:
#              $volume: drive letter and ':', if present
#              $directory and $filename are like on Unix, but '\' and '/' are
#              equivalent and the $volume is not in $directory..
#
#           VMS:
#              $volume: up to and including first ":"
#              $directory: "[...]" component
#              $filename: the rest.
#              $nofile is ignored
#
#           URL:
#              $volume: up to ':', then '//stuff/morestuff'.  No trailing '/'.
#              $directory: after $volume, up to last '/'
#              $filename: the rest.
#              $nofile is ignored
#
# Interface:
#       i)     $path
#       i)     $nofile: if true, then any trailing filename is assumed to
#              belong to the directory for non-VMS systems.
#       r)     list of ( $volume, $directory, $filename ).
#
sub splitpath {
   my( $path, $nofile )= @_ ;
   my( $volume, $directory, $file ) ;
   if ( $fstype ne 'VMS' && $fstype ne 'URL' && $nofile ) {
      $path =~ m/($volumeRE)(.*)$/ ;
      $volume   = $1 ;
      $directory= $2 ;
      $file     = '' ;
   }
   else {
      $path =~ m/($volumeRE)($directoryRE)(.*)$/ ;
      $volume   = $1 ;
      $directory= $2 ;
      $file     = $3 ;
   }

   # For Win32 UNC, force the directory portion to be non-empty. This is
   # because all UNC names are absolute, even if there's no trailing separator
   # after the sharename.
   #
   # This is a bit of a hack, necesitated by the implementation of $isrootRE,
   # which is only applied to the directory portion.
   #
   # A better long term solution might be to make the isroot test a member
   # function in the future, object-oriented version of this.
   #
   $directory = $1
     if ( $fstype eq 'Win32' && $volume =~ /^($sepRE)$sepRE/ && $directory eq
' ) ;

   return ( $volume, $directory, $file ) ;
}


#
# joinpath: joins the results of splitpath().  Not really necessary now, but
# good to have:
#
#     - API completeness
#     - Self documenting code
#     - Future handling of other filesystems
#
# For instance, if you leave the ':' or the '[' and ']' out of VMS $volume
# and $directory strings, this patches it up.  If you leave out the '['
# and provide the ']', or vice versa, it is not cleaned up.  This is
# because it's useful to automatically insert both '[' and ']', but if you
# leave off only one, it's likely that there's a bug elsewhere that needs
# looking in to.
#
# Automatically inserts a separator between directory and filename if needed
# for non-VMS OSs.
#
# Automatically inserts a separator between volume and directory or file
# if needed for Win32 UNC names.
#
sub joinpath($;$;$;) {
   my( $volume, $directory, $filename )= @_ ;

   # Fix up delimiters for $volume and $directory as needed for various OSs
   if ( $fstype eq 'VMS' ) {
      $volume .= ':'
         if ( $volume ne '' && $volume !~ m/:$/ ) ;

      $directory = join( '', ( '[', $directory, ']' ) )
         if ( $directory ne '' && $directory !~ m/^\[.*\]$/ ) ;
   }
   else {
      # Add trailing separator to directory names that require it and
      # need it.  URLs always require it if there are any directory
      # components.
      $directory .= $sep
         if (  $directory ne ''
            && ( $fstype eq 'URL' || $filename ne '' )
            && $directory !~ m/$sepRE$/
            ) ;

      # Add trailing separator to volume for UNC and HTML volume
      # names that lack it and need it.
      # Note that if a URL volume is a scheme only (ends in ':'),
      # we don't require a separator: it's a relative URL.
      $volume .= $sep
         if (  (  ( $fstype eq 'Win32' && $volume =~ m#^$sepRE{2}# )
               || ( $fstype eq 'URL'   && $volume =~ m#[^:/]$#     )
               )
            && $volume    !~ m#$sepRE$#
            && $directory !~ m#^$sepRE#
            && ( $directory ne '' || $filename ne '' )
            ) ;
   }

   return join( '', $volume, $directory, $filename ) ;
}


#
# splitdirs: Splits a string containing directory portion of a path
# in to component parts.  Preserves trailing null entries, unlike split().
#
# "a/b" should get you [ 'a', 'b' ]
#
# "a/b/" should get you [ 'a', 'b', '' ]
#
# "/a/b/" should get you [ '', 'a', 'b', '' ]
#
# "a/b" returns the same array as 'a/////b' for those OSs where
# the seperator is idempotent (Unix and DOS, at least, but not VMS).
#
# Interface:
#     i) directory path string
#
sub splitdirs($;) {
   my( $directorypath )= @_ ;

   $directorypath =~ s/^\[(.*)\]$/$1/
      if ( $fstype eq 'VMS' ) ;

   #
   # split() likes to forget about trailing null fields, so here we
   # check to be sure that there will not be any before handling the
   # simple case.
   #
   return split( $sepRE, $directorypath )
      if ( $directorypath !~ m/$sepRE$/ ) ;

   #
   # since there was a trailing separator, add a file name to the end, then
   # do the split, then replace it with ''.
   #
   $directorypath.= "file" ;
   my( @directories )= split( $sepRE, $directorypath ) ;
   $directories[ $#directories ]= '' ;

   return @directories ;
}

#
# joindirs: Joins an array of directory names in to a string, adding
# OS-specific delimiters, like '[' and ']' for VMS.
#
# Note that empty strings '' are no different then non-empty strings,
# but that undefined strings are skipped by this algorithm.
#
# This is done the hard way to preserve separators that are already
# present in any of the directory names.
#
# Could this be made faster by using a join() followed
# by s/($sepRE)$sepRE+/$1/g?
#
# Interface:
#     i) array of directory names
#     o) string representation of directory path
#
sub joindirs {
   my $directory_path ;

   $directory_path = shift
      while ( ! defined( $directory_path ) && @_ ) ;

   if ( ! defined( $directory_path ) ) {
      $directory_path = '' ;
   }
   else {
      local $_ ;

      for ( @_ ) {
        next if ( ! defined( $_ ) ) ;

        $directory_path .= $sep
           if ( $directory_path !~ /$sepRE$/ && ! /^$sepRE/ ) ;

        $directory_path .= $_ ;
      }
   }

   $directory_path = join( '', '[', $directory_path, ']' )
      if ( $fstype eq 'VMS' ) ;

   return $directory_path ;
}


#
# realpath: returns the canonicalized absolute path name
#
# Interface:
#       i)      $path   path
#       r)              resolved name on success else undef
#       go)     $resolved
#                       resolved name on success else the path name which
#                       caused the problem.
$resolved = '';
#
#       Note: this implementation is based 4.4BSD version realpath(3).
#
# TODO: Speed up by using Cwd::abs_path()?
#
sub realpath($;) {
    ($resolved) = @_;
    my($backdir) = cwd();
    my($dirname, $basename, $links, $reg);

    $resolved = regularize($resolved);
LOOP:
    {
        #
        # Find the dirname and basename.
        # Change directory to the dirname component.
        #
        if ($resolved =~ /$sepRE/) {
            ($dirname, $basename) = $resolved =~ /$basenamesplitRE/ ;
            $dirname = $sep if ( $dirname eq '' );
            $resolved = $dirname;
            unless (chdir($dirname)) {
                warn("realpath: chdir($dirname) failed: $! (in ${\cwd()}).") i
 $verbose;
                chdir($backdir);
                return undef;
            }
        } else {
            $dirname = '';
            $basename = $resolved;
        }
        #
        # If it is a symlink, read in the value and loop.
        # If it is a directory, then change to that directory.
        #
        if ( $basename ne '' ) {
            if (-l $basename) {
                unless ($resolved = readlink($basename)) {
                    warn("realpath: readlink($basename) failed: $! (in ${\cwd(
}).") if $verbose;
                    chdir($backdir);
                    return undef;
                }
                $basename = '';
                if (++$links > $maxsymlinks) {
                    warn("realpath: too many symbolic links: $links.") if $ver
ose;
                    chdir($backdir);
                    return undef;
                }
                redo LOOP;
            } elsif (-d _) {
                unless (chdir($basename)) {
                    warn("realpath: chdir($basename) failed: $! (in ${\cwd()})
") if $verbose;
                    chdir($backdir);
                    return undef;
                }
                $basename = '';
            }
        }
    }
    #
    # Get the current directory name and append the basename.
    #
    $resolved = cwd();
    if ( $basename ne '' ) {
        $resolved .= $sep if ($resolved ne $sep);
        $resolved .= $basename
    }
    chdir($backdir);
    return $resolved;
} # end sub realpath


#
# abs2rel: make a relative pathname from an absolute pathname
#
# Interface:
#       i)      $path   absolute path(needed)
#       i)      $base   base directory(optional)
#       r)              relative path of $path
#
#       Note:   abs2rel doesn't check whether the specified path exist or not.
#
sub abs2rel($;$;) {
    my($path, $base) = @_;
    my($reg );

    my( $path_volume, $path_directory, $path_file )= splitpath( $path,'nofile'
;
    if ( $path_directory !~ /$isrootRE/ ) {
        warn("abs2rel: nothing to do: '$path' is relative.") if $verbose;
        return $path;
    }

    $base = cwd()
       if ( $base eq '' ) ;

    my( $base_volume, $base_directory, $base_file )= splitpath( $base,'nofile'
;
    # check for a filename, since the nofile parameter does not work for OSs
    # like VMS that have explicit delimiters between the dir and file portions
    warn( "abs2rel: filename '$base_file' passed in \$base" )
       if ( $base_file ne '' && $verbose ) ;

    if ( $base_directory !~ /$isrootRE/ ) {
        # Make $base absolute
        my( $cw_volume, $cw_directory, $dummy ) = splitpath( cwd(), 'nofile' )
;
        # maybe we should warn if $cw_volume ne $base_volume and both are not
'
        $base_volume= $cw_volume
           if ( $base_volume eq '' && $cw_volume ne '' ) ;
        $base_directory = join( '', $cw_directory, $sep, $base_directory ) ;
    }

#print( "[$path_directory,$base_directory]\n" ) ;
    $path_directory = regularize( $path_directory );
    $base_directory = regularize( $base_directory );
#print( "[$path_directory,$base_directory]\n" ) ;
    # Now, remove all leading components that are the same, so 'name/a'
    # 'name/b' become 'a' and 'b'.
    my @pathchunks = split($sepRE, $path_directory);
    my @basechunks = split($sepRE, $base_directory);

    if ( $casesensitive )
    {
        while (@pathchunks && @basechunks && $pathchunks[0] eq $basechunks[0])
+        {
            shift @pathchunks ;
            shift @basechunks ;
        }
    }
    else {
        while (  @pathchunks
              && @basechunks
              && lc( $pathchunks[0] ) eq lc( $basechunks[0] )
              )
        {
            shift @pathchunks ;
            shift @basechunks ;
        }
    }

    # No need to use joindirs() here, since we know that the arrays
    # are well formed.
    $path_directory= join( $sep, @pathchunks );
    $base_directory= join( $sep, @basechunks );
#print( "[$path_directory,$base_directory]\n" ) ;

    # Convert $base_directory from absolute to relative
    if ( $fstype eq 'VMS' ) {
        $base_directory= $sep . $base_directory
            if ( $base_directory ne '' ) ;
    }
    else {
        $base_directory=~ s/^$sepRE// ;
    }

#print( "[$base_directory]\n" ) ;
    # $base_directory now contains the directories the resulting relative path
+    # must ascend out of before it can descend to $path_directory.  So,
    # replace all names with $parentDir
    $base_directory =~ s/$notsepRE+/$parentDir/g ;
#print( "[$base_directory]\n" ) ;

    # Glue the two together, using a separator if necessary, and preventing an
    # empty result.
    if ( $path_directory ne '' && $base_directory ne '' ) {
        $path_directory = "$base_directory$sep$path_directory" ;
    } else {
        $path_directory = "$base_directory$path_directory" ;
    }

    $path_directory = regularize( $path_directory ) ;

    # relative URLs should have no name in the volume, only a scheme.
    $path_volume=~ s#/.*##
        if ( $fstype eq 'URL' ) ;
    return joinpath( $path_volume, $path_directory, $path_file ) ;
}

#
# rel2abs: make an absolute pathname from a relative pathname
#
# Assumes no trailing file name on $base.  Ignores it if present on an OS
# like $VMS.
#
# Interface:
#       i)      $path   relative path (needed)
#       i)      $base   base directory  (optional)
#       r)              absolute path of $path
#
#       Note:   rel2abs doesn't check if the paths exist.
#
sub rel2abs($;$;) {
    my( $path, $base ) = @_;
    my( $reg );

    my( $path_volume, $path_directory, $path_file )= splitpath( $path, 'nofile
 ) ;
    if ( $path_directory =~ /$isrootRE/ ) {
        warn( "rel2abs: nothing to do: '$path' is absolute" )
            if $verbose;
        return $path;
    }

    warn( "rel2abs: volume '$path_volume' passed in relative path: \$path" )
        if ( $path_volume ne '' && $verbose ) ;

    $base = cwd()
        if ( !defined( $base ) || $base eq '' ) ;

    my( $base_volume, $base_directory, $base_file )= splitpath( $base, 'nofile
 ) ;
    # check for a filename, since the nofile parameter does not work for OSs
    # like VMS that have explicit delimiters between the dir and file portions
    warn( "rel2abs: filename '$base_file' passed in \$base" )
        if ( $base_file ne '' && $verbose ) ;

    if ( $base_directory !~ /$isrootRE/ ) {
        # Make $base absolute
        my( $cw_volume, $cw_directory, $dummy ) = splitpath( cwd(), 'nofile' )
;
        # maybe we should warn if $cw_volume ne $base_volume and both are not
'
        $base_volume= $cw_volume
            if ( $base_volume eq '' && $cw_volume ne '' ) ;
        $base_directory = join( '', $cw_directory, $sep, $base_directory ) ;
    }

    $path_directory = regularize( $path_directory );
    $base_directory = regularize( $base_directory );

    my $result_directory ;
    # Avoid using a separator if either directory component is empty.
    if ( $base_directory ne '' && $path_directory ne '' ) {
        $result_directory= joindirs( $base_directory, $path_directory ) ;
    }
    else {
        $result_directory= "$base_directory$path_directory" ;
    }

    $result_directory = regularize( $result_directory );

    return joinpath( $base_volume, $result_directory, $path_file ) ;
}

#
# regularize a path.
#
#    Removes dubious and redundant information.
#    should only be called on directory portion on OSs
#    with volumes and with delimeters that separate dir names from file names,
#    since the separators can take on different semantics, like "\\" for UNC
#    under Win32, or '.' in filenames under VMS.
#
sub regularize {
    my( $in )= $_[ 0 ] ;

    # Combine idempotent separators.  Do this first so all other REs only
    # need to match one separator. Use the first sep found instead of
    # sepRE to preserve slashes on Win32.
    $in =~ s/($sepRE)$sepRE+/$1/g
        if ( $idempotent ) ;

    # We do this after deleting redundant separators in order to be consistent

    # If a Win32 path ended in \/, we want to be sure that the \ is returned,
    # no the /.
    $in =~ /($sepRE)$sepRE*$/ ;
    my $trailing_sep = defined( $1 ) ? $1 : '' ;

    # Delete all occurences of 'name/..(/|$)'.  This is done with a while
    # loop to get rid of things like 'name1/name2/../..'. We chose the pattern
    # name/../ as the target instead of /name/.. so as to preserve 'rootness'.
    while ($in =~ s/$name_sep_parentRE/$1/g) {}

    # Get rid of ./ in '^./' and '/./'
    $in =~ s/$dot_sep_etcRE/$1/g ;

    # Get rid of trailing '/' and '/.' unless it would leave an empty string
    $in =~ s/$trailing_sepRE/$1/ ;

    # Get rid of '../' constructs from absolute paths
    $in =~ s/$leading_parentRE/$1/
      if ( $in =~ /$isrootRE/ ) ;

#    # Default to current directory if it's now empty.
#    $in = $thisDir if $_[0] eq '' ;
#
    # Restore trailing separator if it was lost. We do this to preserve
    # the 'dir-ness' of the path: paths that ended in a separator on entry
    # should leave with one in case the caller is using trailing slashes to
    # indicate paths to directories.
    $in .= $trailing_sep
        if ( $trailing_sep ne '' && $in !~ /$sepRE$/ ) ;

    return $in ;
}

1;

__END__

=head1 NAME

abs2rel - convert an absolute path to a relative path

rel2abs - convert a relative path to an absolute path

realpath - convert a logical path to a physical path (resolve symlinks)

splitpath - split a path in to volume, directory and filename components

joinpath - join volume, directory, and filename components to form a path

splitdirs - split directory specification in to component names

joindirs - join component names in to a directory specification

setfstype - set the file system type


=head1 SYNOPSIS

    use File::PathConvert qw(realpath abs2rel rel2abs setfstype splitpath
      joinpath splitdirs joindirs $resolved);

    $relpath = abs2rel($abspath);
    $abspath = abs2rel($abspath, $base);

    $abspath = rel2abs($relpath);
    $abspath = rel2abs($relpath, $base);

    $path = realpath($logpath) || die "resolution stopped at $resolved";

    ( $volume, $directory, $filename )= splitpath( $path ) ;
    ( $volume, $directory, $filename )= splitpath( $path, 'nofile' ) ;

    $path= joinpath( $volume, $directory, $filename ) ;

    @directories= splitdirs( $directory ) ;
    $directory= joindirs( @directories ) ;

=head1 DESCRIPTION

File::PathConvert provides functions to convert between absolute and
relative paths, and from logical paths to physical paths on a variety of
filesystems, including the URL 'filesystem'.

Paths are decomposed internally in to volume, directory, and, sometimes
filename portions as appropriate to the operation and filesystem, then
recombined.  This preserves the volume and filename portions so that they may
be returned, and prevents them from interfering with the path conversions.

Here are some examples of path decomposition.  A '****' in a column indicates
the column is not used in C<abs2rel> and C<rel2abs> functions for that
filesystem type.


    FS      VOLUME                  Directory       filename
    ======= ======================= =============== =============
    URL     http:                   /a/b/           c?query
            http://fubar.com        /a/b/           c?query
            //p.d.q.com             /a/b/c/         ?query

    VMS     Server::Volume:         [a.b]           c
            Server"access spec"::   [a.b]           c
            Volume:                 [a.b]           c

    Win32   A:                      \a\b\c          ****
            \\server\Volume         \a\b\c          ****
            \\server\Volume         \a/b/c          ****

    Unix    ****                    \a\b\c          ****

    MacOS   Volume::                a:b:c           ****

Many more examples abound in the test.pl included with this module.

Only the VMS and URL filesystems indicate if the last name in a path is a
directory or file.  For other filesystems, all non-volume names are assumed to
be directory names.  For URLs, the last name in a path is assumed to be a
filename unless it ends in '/', '/.', or '/..'.

Other assumptions are made as well, especially MacOS and VMS. THESE MAY CHANGE
BASED ON PROGRAMMER FEEDBACK!

The conversion routines C<abs2rel>, C<rel2abs>, and C<realpath> are the
main focus of this package.  C<splitpath> and C<joinpath> are provided to
allow volume oriented filesystems (almost anything non-unixian, actually)
to be accomodated.  C<splitdirs> and C<joindirs> provide directory path
grammar parsing and encoding, which is especially useful for VMS.

=over 4

=item setfstype

This is called automatically on module load to set the filesystem type
according to $^O. The user can call this later set the filesystem type
manually.  If the name is not recognized, unix defaults are used.  Names
matching /^URL$/i, /^VMS$/i, /^MacOS$/i, or /^(ms)?(win|dos)/32|nt)?$/i yield
the appropriate (hopefully) filesystem settings.  These strings may be
generalized in the future.

Examples:

    File::PathConvert::setfstype( 'url' ) ;
    File::PathConvert::setfstype( 'Win32' ) ;
    File::PathConvert::setfstype( 'HAL9000' ) ; # Results in Unix default

=item abs2rel

C<abs2rel> converts an absolute path name to a relative path:
converting /1/2/3/a/b/c relative to /1/2/3 returns a/b/c

    $relpath= abs2rel( $abspath ) ;
    $relpath= abs2rel( $abspath, $base ) ;

If $abspath is already relative, it is returned unchanged.  Otherwise the
relative path from $base to $abspath is returned.  If $base is undefined the
current directory is used.

The volume and filename portions of $base are ignored if present.
If $abspath and $base are on different volumes, the volume from $abspath is
used.

No filesystem calls are made except for getting the current working directory
if $base is undefined, so symbolic links are not checked for or resolved, and
no check is done for existance.

Examples

    # Unix
    'a/b/c' == abs2rel( 'a/b/c', $anything )
    'a/b/c' == abs2rel( '/1/2/3/a/b/c', '/1/2/3' )

    # DOS
    'a\\b/c' == abs2rel( 'a\\b/c', $anything )
    'a\\b/c' == abs2rel( '/1\\2/3/a\\b/c', '/1/2/3' )

    # URL
    'http:a/b/c'           == abs2rel( 'http:a/b/c', $anything )
    'http:a/b/c'           == abs2rel( 'http:/1/2/3/a/b/c',
                                       'ftp://t.org/1/2/3/?z' )
    'http:a/b/c?q'         == abs2rel( 'http:/1/2/3/a/b/c/?q',
                                       'ftp://t.org/1/2/3?z'  )
    'http://s.com/a/b/c?q' == abs2rel( 'http://s.com/1/2/3/a/b/c?q',
                                       'ftp://t.org/1/2/3/?z')

=item rel2abs

C<rel2abs> makes converts a relative path name to an absolute path:
converting a/b/c relative to /1/2/3 returns /1/2/3/a/b/c.

    $abspath= rel2abs( $relpath ) ;
    $abspath= rel2abs( $relpath, $base ) ;

If $relpath is already absolute, it is returned unchanged.  Otherwise $relpath
is taken to be relative to $base and the resulting absolute path is returned.
If $base is not supplied, the current working directory is used.

The volume portion of $relpath is ignored.  The filename portion of $base is
also ignored. The volume from $base is returned if present. The filename
portion of $abspath is returned if present.

No filesystem calls are made except for getting the current working directory
if $base is undefined, so symbolic links are not checked for or resolved, and
no check is done for existance.

C<rel2abs> will not return a path of the form "./file".

Examples

    # Unix
    '/a/b/c'       == rel2abs( '/a/b/c', $anything )
    '/1/2/3/a/b/c' == rel2abs( 'a/b/c', '/1/2/3' )

    # DOS
    '\\a\\b/c'                == rel2abs( '\\a\\b/c', $anything )
    '/1\\2/3\\a\\b/c'         == rel2abs( 'a\\b/c', '/1\\2/3' )
    'C:/1\\2/3\\a\\b/c'       == rel2abs( 'D:a\\b/c', 'C:/1\\2/3' )
    '\\\\s\\v/1\\2/3\\a\\b/c' == rel2abs( 'D:a\\b/c', '\\\\s\\v/1\\2/3' )

    # URL
    'http:/a/b/c?q'            == rel2abs( 'http:/a/b/c?q', $anything )
    'ftp://t.org/1/2/3/a/b/c?q'== rel2abs( 'http:a/b/c?q',
                                           'ftp://t.org/1/2/3?z' )


=item realpath

C<realpath> makes a canonicalized absolute pathname and
resolves all symbolic links, extra ``/'' characters, and references
to /./ and /../ in the path.
C<realpath> resolves both absolute and relative paths.
It returns the resolved name on success, otherwise it returns undef
and sets the valiable C<$File::PathConvert::resolved> to the pathname
that caused the problem.

All but the last component of the path must exist.

This implementation is based on 4.4BSD realpath(3).  It is not tested under
other operating systems at this time.

If '/sys' is a symbolic link to '/usr/src/sys':

    chdir('/usr');
    '/usr/src/sys/kern' == realpath('../sys/kern');
    '/usr/src/sys/kern' == realpath('/sys/kern');

=item splitpath

To be written...

=item joinpath

To be written...

Note that joinpath( splitpath( $path ) ) usually yields path.  URLs
with directory components ending in '/.' or '/..' will be fixed
up to end in '/./' and '/../'.

=item splitdirs

To be written...

=item joindirs


=back

=head1 BUGS

C<realpath> is not fully multiplatform.


=head1 LIMITATIONS

=over 4

=item *

In URLs, paths not ending in '/' are split such that the last name in the
path is a filename.  This is not intuitive: many people use such URLs for
directories, and most servers send a redirect.  This may cause programers
using this package to code in bugs, it may be more pragmatic to always assume
all names are directory names.  (Note that the query portion is always part
of the filename).

=item *

If the relative and base paths are on different volumes, no error is
returned.  A silent, hopefully reasonable assumption is made.

=item *

No detection of unix style paths is done when other filesystems are
selected, like File::Basename does.

=back

=head1 AUTHORS

Barrie Slaymaker <rbs@telerama.com>
Shigio Yamaguchi <shigio@wafu.netgate.net>

=cut
