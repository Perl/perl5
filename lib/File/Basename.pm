=head1 NAME

File::Basename - Parse file paths into directory, filename and suffix.

=head1 SYNOPSIS

    use File::Basename;

    ($name,$path,$suffix) = fileparse($fullname,@suffixlist);
    $name = fileparse($fullname,@suffixlist);

    $basename = basename($fullname,@suffixlist);
    $dirname  = dirname($fullname);


=head1 DESCRIPTION

These routines allow you to parse file paths into their directory, filename
and suffix.

B<NOTE>: C<dirname()> and C<basename()> emulate the behaviours, and quirks, of
the shell and C functions of the same name.  See each function's documention
for details.

=cut


package File::Basename;

# A bit of juggling to insure that C<use re 'taint';> always works, since
# File::Basename is used during the Perl build, when the re extension may
# not be available.
BEGIN {
  unless (eval { require re; })
    { eval ' sub re::import { $^H |= 0x00100000; } ' } # HINT_RE_TAINT
  import re 'taint';
}


use strict;
use 5.006;
use warnings;
our(@ISA, @EXPORT, $VERSION, $Fileparse_fstype, $Fileparse_igncase);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(fileparse fileparse_set_fstype basename dirname);
$VERSION = "2.73";

fileparse_set_fstype($^O);


=over 4

=item C<fileparse>

    my($filename, $directories, $suffix) = fileparse($path);
    my($filename, $directories, $suffix) = fileparse($path, @suffixes);
    my $filename                         = fileparse($path, @suffixes);

The C<fileparse()> routine divides a file path into its $directories, $filename
and (optionally) the filename $suffix.

$directories contains everything up to and including the last
directory separator in the $path including the volume (if applicable).
The remainder of the $path is the $filename.

     # On Unix returns ("baz", "/foo/bar/", "")
     fileparse("/foo/bar/baz");

     # On Windows returns ("baz", "C:\foo\bar\", "")
     fileparse("C:\foo\bar\baz");

     # On Unix returns ("", "/foo/bar/baz/", "")
     fileparse("/foo/bar/baz/");

If @suffixes are given each element is a pattern (either a string or a
C<qr//>) matched against the end of the $filename.  The matching
portion is removed and becomes the $suffix.

     # On Unix returns ("baz", "/foo/bar", ".txt")
     fileparse("/foo/bar/baz", qr/\.[^.]*/);

If type is one of "VMS", "MSDOS", "MacOS", "AmigaOS", "OS2", "MSWin32"
or "RISCOS" (see C<fileparse_set_fstype()>) then the pattern matching
for suffix removal is performed case-insensitively, since those
systems are not case-sensitive when opening existing files.

You are guaranteed that C<$directories . $filename . $suffix> will
denote the same location as the original $path.

=cut


sub fileparse {
  my($fullname,@suffices) = @_;
  unless (defined $fullname) {
      require Carp;
      Carp::croak("fileparse(): need a valid pathname");
  }
  my($fstype,$igncase) = ($Fileparse_fstype, $Fileparse_igncase);
  my($dirpath,$tail,$suffix,$basename);
  my($taint) = substr($fullname,0,0);  # Is $fullname tainted?

  if ($fstype =~ /^VMS/i) {
    if ($fullname =~ m#/#) { $fstype = '' }  # We're doing Unix emulation
    else {
      ($dirpath,$basename) = ($fullname =~ /^(.*[:>\]])?(.*)/s);
      $dirpath ||= '';  # should always be defined
    }
  }
  if ($fstype =~ /^MS(DOS|Win32)|epoc/i) {
    ($dirpath,$basename) = ($fullname =~ /^((?:.*[:\\\/])?)(.*)/s);
    $dirpath .= '.\\' unless $dirpath =~ /[\\\/]\z/;
  }
  elsif ($fstype =~ /^os2/i) {
    ($dirpath,$basename) = ($fullname =~ m#^((?:.*[:\\/])?)(.*)#s);
    $dirpath = './' unless $dirpath;	# Can't be 0
    $dirpath .= '/' unless $dirpath =~ m#[\\/]\z#;
  }
  elsif ($fstype =~ /^MacOS/si) {
    ($dirpath,$basename) = ($fullname =~ /^(.*:)?(.*)/s);
    $dirpath = ':' unless $dirpath;
  }
  elsif ($fstype =~ /^AmigaOS/i) {
    ($dirpath,$basename) = ($fullname =~ /(.*[:\/])?(.*)/s);
    $dirpath = './' unless $dirpath;
  }
  elsif ($fstype !~ /^VMS/i) {  # default to Unix
    ($dirpath,$basename) = ($fullname =~ m#^(.*/)?(.*)#s);
    if ($^O eq 'VMS' and $fullname =~ m:^(/[^/]+/000000(/|$))(.*):) {
      # dev:[000000] is top of VMS tree, similar to Unix '/'
      # so strip it off and treat the rest as "normal"
      my $devspec  = $1;
      my $remainder = $3;
      ($dirpath,$basename) = ($remainder =~ m#^(.*/)?(.*)#s);
      $dirpath ||= '';  # should always be defined
      $dirpath = $devspec.$dirpath;
    }
    $dirpath = './' unless $dirpath;
  }

  if (@suffices) {
    $tail = '';
    foreach $suffix (@suffices) {
      my $pat = ($igncase ? '(?i)' : '') . "($suffix)\$";
      if ($basename =~ s/$pat//s) {
        $taint .= substr($suffix,0,0);
        $tail = $1 . $tail;
      }
    }
  }

  # Ensure taint is propgated from the path to its pieces.
  $tail .= $taint if defined $tail; # avoid warning if $tail == undef
  wantarray ? ($basename .= $taint, $dirpath .= $taint, $tail)
            : ($basename .= $taint);
}



=item C<basename>

    my $filename = basename($path);
    my $filename = basename($path, @suffixes);

C<basename()> works just like C<fileparse()> in scalar context - you only get
the $filename - except that it always quotes metacharacters in the @suffixes.

    # These two function calls are equivalent.
    my $filename = basename("/foo/bar/baz.txt",  ".txt");
    my $filename = fileparse("/foo/bar/baz.txt", qr/\Q.txt\E/);

This function is provided for compatibility with the Unix shell command 
C<basename(1)>.

=cut


sub basename {
  my($name) = shift;
  (fileparse($name, map("\Q$_\E",@_)))[0];
}



=item C<dirname>

This function is provided for compatibility with the Unix shell
command C<dirname(1)> and has inherited some of its quirks.  In spite of
its name it does B<NOT> always return the directory name as you might
expect.  To be safe, if you want the directory name of a path use
C<fileparse()>.

    # On all but Unix and MSDOS
    my $directories = dirname($path);

On all system types but Unix and MSDOS this works just like
C<fileparse($path)> but returning just the $directories.

    # On Unix and MSDOS
    my $path_one_level_up = dirname($path);

When using Unix or MSDOS syntax this emulates the C<dirname(1)> shell function
which is subtly different from how C<fileparse()> works.  It returns all but
the last level of a file path even if the last level is clearly a directory.
In effect, it is not returning the directory portion but simply the path one
level up acting like C<chop()> for file paths.

Also unlike C<fileparse()>, C<dirname()> does not include a trailing slash on
its returned path.

    # returns /foo/bar.  fileparse() would return /foo/bar/
    dirname("/foo/bar/baz");

    # also returns /foo/bar despite the fact that baz is clearly a 
    # directory.  fileparse() would return /foo/bar/baz/
    dirname("/foo/bar/baz/");

    # returns '.'.  fileparse() would return 'foo/'
    dirname("foo/");

Under VMS, if there is no directory information in the $path, then the
current default device and directory is used.

=cut


sub dirname {
    my($fstype) = $Fileparse_fstype;

    if( $fstype =~ /VMS/i and $_[0] =~ m{/} ) {
        # Parse as Unix
        local($File::Basename::Fileparse_fstype) = '';
        return dirname(@_);
    }

    my($basename,$dirname) = fileparse($_[0]);

    if ($fstype =~ /VMS/i) { 
        $dirname ||= $ENV{DEFAULT};
    }
    elsif ($fstype =~ /MacOS/i) {
	if( !length($basename) && $dirname !~ /^[^:]+:\z/) {
	    $dirname =~ s/([^:]):\z/$1/s;
	    ($basename,$dirname) = fileparse $dirname;
	}
	$dirname .= ":" unless $dirname =~ /:\z/;
    }
    elsif ($fstype =~ /MS(DOS|Win32)|os2/i) { 
        $dirname =~ s/([^:])[\\\/]*\z/$1/;
        unless( length($basename) ) {
	    ($basename,$dirname) = fileparse $dirname;
	    $dirname =~ s/([^:])[\\\/]*\z/$1/;
	}
    }
    elsif ($fstype =~ /AmigaOS/i) {
        if ( $dirname =~ /:\z/) { return $dirname }
        chop $dirname;
        $dirname =~ s#[^:/]+\z## unless length($basename);
    }
    else {
        $dirname =~ s{(.)/*\z}{$1}s;
        unless( length($basename) ) {
	    ($basename,$dirname) = fileparse $dirname;
	    $dirname =~ s{(.)/*\z}{$1}s;
	}
    }

    $dirname;
}


=item C<fileparse_set_fstype>

  my $previous_fstype = fileparse_set_fstype($type);

Normally File::Basename will assume a file path type native to your current
operating system (ie. /foo/bar style on Unix, \foo\bar on Windows, etc...).
With this function you can override that assumption.

Valid $types are "VMS", "MSDOS", "MacOS", "AmigaOS", "OS2", "RISCOS",
"MSWin32" and "Unix" (case-insensitive).  If an unrecognized $type is
given Unix semantics will be assumed.

If you've selected VMS syntax, and the file specification you pass to
one of these routines contains a "/", they assume you are using Unix
emulation and apply the Unix syntax rules instead, for that function
call only.

=back

=cut


sub fileparse_set_fstype {
  my @old = ($Fileparse_fstype, $Fileparse_igncase);
  if (@_) {
    $Fileparse_fstype = $_[0];
    $Fileparse_igncase = ($_[0] =~ /^(?:MacOS|VMS|AmigaOS|os2|RISCOS|MSWin32|MSDOS)/i);
  }
  wantarray ? @old : $old[0];
}


1;
