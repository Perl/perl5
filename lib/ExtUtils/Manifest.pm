package ExtUtils::Manifest;

=head1 NAME

ExtUtils::Manifest - utilities to write and check a MANIFEST file

=head1 SYNOPSIS

C<require ExtUtils::Manifest;>

C<ExtUtils::Manifest::mkmanifest;>

C<ExtUtils::Manifest::manicheck;>

C<ExtUtils::Manifest::filecheck;>

C<ExtUtils::Manifest::fullcheck;>

C<ExtUtils::Manifest::maniread($file);>

C<ExtUtils::Manifest::manicopy($read,$target);>

=head1 DESCRIPTION

Mkmanifest() writes all files in and below the current directory to a
file named C<MANIFEST> in the current directory. It works similar to

    find . -print

but in doing so checks each line in an existing C<MANIFEST> file and
includes any comments that are found in the existing C<MANIFEST> file
in the new one. Anything between white space and an end of line within
a C<MANIFEST> file is considered to be a comment. Filenames and
comments are seperated by one or more TAB characters in the
output. All files that match any regular expression in a file
C<MANIFEST.SKIP> (if such a file exists) are ignored.

Manicheck() checks if all the files within a C<MANIFEST> in the current
directory really do exist.

Filecheck() finds files below the current directory that are not
mentioned in the C<MANIFEST> file. An optional file C<MANIFEST.SKIP>
will be consulted. Any file matching a regular expression in such a
file will not be reported as missing in the C<MANIFEST> file.

Fullcheck() does both a manicheck() and a filecheck().

Maniread($file) reads a named C<MANIFEST> file (defaults to
C<MANIFEST> in the current directory) and returns a HASH reference
with files being the keys and comments being the values of the HASH.

I<Manicopy($read,$target)> copies the files that are the keys in the
HASH I<%$read> to the named target directory. The HASH reference
I<$read> is typically returned by the maniread() function. This
function is useful for producing a directory tree identical to the
intended distribution tree.

=head1 MANIFEST.SKIP

The file MANIFEST.SKIP may contain regular expressions of files that
should be ignored by mkmanifest() and filecheck(). The regular
expressions should appear one on each line. A typical example:

    \bRCS\b
    ^MANIFEST\.
    ^Makefile$
    ~$
    \.html$
    \.old$
    ^blib/
    ^MakeMaker-\d

=head1 EXPORT_OK

C<&mkmanifest>, C<&manicheck>, C<&filecheck>, C<&fullcheck>,
C<&maniread>, and C<&manicopy> are exportable.

=head1 DIAGNOSTICS

All diagnostic output is sent to C<STDERR>.

=over
    
=item C<Not in MANIFEST:> I<file>
is reported if a file is found, that is missing in the C<MANIFEST>
file which is excluded by a regular expression in the file
C<MANIFEST.SKIP>.

=item C<No such file:> I<file>
is reported if a file mentioned in a C<MANIFEST> file does not
exist.

=item C<MANIFEST:> I<$!>
is reported if C<MANIFEST> could not be opened.

=item C<Added to MANIFEST:> I<file>
is reported by mkmanifest() if $Verbose is set and a file is added
to MANIFEST. $Verbose is set to 1 by default.

=back

=head1 AUTHOR

Andreas Koenig F<E<lt>koenig@franz.ww.TU-Berlin.DEE<gt>>

=cut

require Exporter;
@ISA=('Exporter');
@EXPORT_OK = ('mkmanifest', 'manicheck', 'fullcheck', 'filecheck', 
	      'maniread', 'manicopy');

use File::Find;
use Carp;

$Debug = 0;
$Verbose = 1;

($Version) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
$Version = $Version; #avoid warning

$Quiet = 0;

sub mkmanifest {
    my $manimiss = 0;
    my $read = maniread() or $manimiss++;
    $read = {} if $manimiss;
    my $matches = _maniskip();
    my $found = manifind();
    my($key,$val,$file,%all);
    my %all = (%$found, %$read);
    local *M;
    rename "MANIFEST", "MANIFEST.bak" unless $manimiss;
    open M, ">MANIFEST" or die "Could not open MANIFEST: $!";
    foreach $file (sort keys %all) {
	next if &$matches($file);
	if ($Verbose){
	    warn "Added to MANIFEST: $file\n" unless exists $read->{$file};
	}
	my $tabs = (5 - (length($file)+1)/8);
	$tabs = 1 if $tabs < 1;
	$tabs = 0 unless $all{$file};
	print M $file, "\t" x $tabs, $all{$file}, "\n";
    }
    close M;
}

sub manifind {
    local $found = {};
    find(sub {return if -d $_;
	      (my $name = $File::Find::name) =~ s|./||;
	      warn "Debug: diskfile $name\n" if $Debug;
	      $found->{$name} = "";}, ".");
    $found;
}

sub fullcheck {
    _manicheck(3);
}

sub manicheck {
    return @{(_manicheck(1))[0]};
}

sub filecheck {
    return @{(_manicheck(2))[1]};
}

sub _manicheck {
    my($arg) = @_;
    my $read = maniread();
    my $file;
    my(@missfile,@missentry);
    if ($arg & 1){
	my $found = manifind();
	foreach $file (sort keys %$read){
	    warn "Debug: manicheck checking from MANIFEST $file\n" if $Debug;
	    unless ( exists $found->{$file} ) {
	      warn "No such file: $file\n" unless $Quiet;
	      push @missfile, $file;
	    }
	}
    }
    if ($arg & 2){
	$read ||= {};
	my $matches = _maniskip();
	my $found = manifind();
	foreach $file (sort keys %$found){
	    next if &$matches($file);
	    warn "Debug: manicheck checking from disk $file\n" if $Debug;
	    unless ( exists $read->{$file} ) {
	      warn "Not in MANIFEST: $file\n" unless $Quiet;
	      push @missentry, $file;
	    }
	}
    }
    (\@missfile,\@missentry);
}

sub maniread {
    my ($mfile) = @_;
    $mfile = "MANIFEST" unless defined $mfile;
    my $read = {};
    local *M;
    unless (open M, $mfile){
	warn "$mfile: $!";
	return $read;
    }
    while (<M>){
	chomp;
	/^(\S+)\s*(.*)/ and $read->{$1}=$2;
    }
    close M;
    $read;
}

# returns an anonymous sub that decides if an argument matches
sub _maniskip {
    my ($mfile) = @_;
    my $matches = sub {0};
    my @skip ;
    my $mfile = "MANIFEST.SKIP" unless defined $mfile;
    local *M;
    return $matches unless -f $mfile;
    open M, $mfile or return $matches;
    while (<M>){
	chomp;
	next if /^\s*$/;
	push @skip, $_;
    }
    close M;
    my $sub = "\$matches = "
	. "sub { my(\$arg)=\@_; return 1 if "
	. join (" || ",  (map {s!/!\\/!g; "\$arg =~ m/$_/o "} @skip), 0)
	. " }";
    eval $sub;
    print "Debug: $sub\n" if $Debug;
    $matches;
}

sub manicopy {
    my($read,$target)=@_;
    croak "manicopy() called without target argument" unless defined $target;
    require File::Path;
    require File::Basename;
    my(%dirs,$file);
    foreach $file (keys %$read){
	my $dir = File::Basename::dirname($file);
	File::Path::mkpath("$target/$dir");
	cp_if_diff($file, "$target/$file");
    }
}

sub cp_if_diff {
    my($from,$to)=@_;
    -f $from || carp "$0: $from not found";
    system "cmp", "-s", $from, $to;
    if ($?) {
	unlink($to);   # In case we don't have write permissions.
	(system 'cp', $from, $to) == 0 or confess "system 'cp': $!";
    }
}

1;
