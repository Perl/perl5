package File::Basename;

require 5.000;
use Config;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(fileparse fileparse_set_fstype basename dirname);

#   fileparse_set_fstype() - specify OS-based rules used in future
#                            calls to routines in this package
#
#   Currently recognized values: VMS, MSDOS, MacOS
#       Any other name uses Unix-style rules

sub fileparse_set_fstype {
  my($old) = $Fileparse_fstype;
  $Fileparse_fstype = $_[0] if $_[0];
  $old;
}

#   fileparse() - parse file specification
#
#   calling sequence:
#     ($filename,$prefix,$tail) = &basename_pat($filespec,@excludelist);
#     where  $filespec    is the file specification to be parsed, and
#            @excludelist is a list of patterns which should be removed
#                         from the end of $filename.
#            $filename    is the part of $filespec after $prefix (i.e. the
#                         name of the file).  The elements of @excludelist
#                         are compared to $filename, and if an  
#            $prefix     is the path portion $filespec, up to and including
#                        the end of the last directory name
#            $tail        any characters removed from $filename because they
#                         matched an element of @excludelist.
#
#   fileparse() first removes the directory specification from $filespec,
#   according to the syntax of the OS (code is provided below to handle
#   VMS, Unix, MSDOS and MacOS; you can pick the one you want using
#   fileparse_set_fstype(), or you can accept the default, which is
#   based on the information in the %Config array).  It then compares
#   each element of @excludelist to $filename, and if that element is a
#   suffix of $filename, it is removed from $filename and prepended to
#   $tail.  By specifying the elements of @excludelist in the right order,
#   you can 'nibble back' $filename to extract the portion of interest
#   to you.
#
#   For example, on a system running Unix,
#   ($base,$path,$type) = fileparse('/virgil/aeneid/draft.book7',
#                                       '\.book\d+');
#   would yield $base == 'draft',
#               $path == '/virgil/aeneid/'  (note trailing slash)
#               $tail == '.book7'.
#   Similarly, on a system running VMS,
#   ($name,$dir,$type) = fileparse('Doc_Root:[Help]Rhetoric.Rnh','\..*');
#   would yield $name == 'Rhetoric';
#               $dir == 'Doc_Root:[Help]', and
#               $type == '.Rnh'.
#
#   Version 2.2  13-Oct-1994  Charles Bailey  bailey@genetics.upenn.edu 


sub fileparse {
  my($fullname,@suffices) = @_;
  my($fstype) = $Fileparse_fstype;
  my($dirpath,$tail,$suffix,$idx);

  if ($fstype =~ /^VMS/i) {
    if ($fullname =~ m#/#) { $fstype = '' }  # We're doing Unix emulation
    else {
      ($dirpath,$basename) = ($fullname =~ /(.*[:>\]])?(.*)/);
      $dirpath = $ENV{'DEFAULT'} unless $dirpath;
    }
  }
  if ($fstype =~ /^MSDOS/i) {
    ($dirpath,$basename) = ($fullname =~ /(.*\\)?(.*)/);
    $dirpath = '.' unless $dirpath;
  }
  elsif ($fstype =~ /^MAC/i) {
    ($dirpath,$basename) = ($fullname =~ /(.*:)?(.*)/);
  }
  elsif ($fstype !~ /^VMS/i) {  # default to Unix
    ($dirpath,$basename) = ($fullname =~ m#(.*/)?(.*)#);
    $dirpath = '.' unless $dirpath;
  }

  if (@suffices) {
    foreach $suffix (@suffices) {
      if ($basename =~ /($suffix)$/) {
        $tail = $1 . $tail;
        $basename = $`;
      }
    }
  }

  wantarray ? ($basename,$dirpath,$tail) : $basename;

}


#   basename() - returns first element of list returned by fileparse()

sub basename {
  my($name) = shift;
  (fileparse($name, map("\Q$_\E",@_)))[0];
}
  

#    dirname() - returns device and directory portion of file specification
#        Behavior matches that of Unix dirname(1) exactly for Unix and MSDOS
#        filespecs except for names ending with a separator, e.g., "/xx/yy/".
#        This differs from the second element of the list returned
#        by fileparse() in that the trailing '/' (Unix) or '\' (MSDOS) (and
#        the last directory name if the filespec ends in a '/' or '\'), is lost.

sub dirname {
    my($basename,$dirname) = fileparse($_[0]);
    my($fstype) = $Fileparse_fstype;

    if ($fstype =~ /VMS/i) { 
        if ($_[0] =~ m#/#) { $fstype = '' }
        else { return $dirname }
    }
    if ($fstype =~ /MacOS/i) { return $dirname }
    elsif ($fstype =~ /MSDOS/i) { 
        if ( $dirname =~ /:\\$/) { return $dirname }
        chop $dirname;
        $dirname =~ s:[^\\]+$:: unless $basename;
        $dirname = '.' unless $dirname;
    }
    else { 
        if ( $dirname eq '/') { return $dirname }
        chop $dirname;
        $dirname =~ s:[^/]+$:: unless $basename;
        $dirname = '.' unless $dirname;
    }

    $dirname;
}

$Fileparse_fstype = $Config{'osname'};

1;
