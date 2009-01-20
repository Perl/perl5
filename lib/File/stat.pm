package File::stat;
use 5.006;

use strict;
use warnings;
use Carp;

our(@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

our $VERSION = '1.01';

BEGIN { 
    use Exporter   ();
    @EXPORT      = qw(stat lstat);
    @EXPORT_OK   = qw( $st_dev	   $st_ino    $st_mode 
		       $st_nlink   $st_uid    $st_gid 
		       $st_rdev    $st_size 
		       $st_atime   $st_mtime  $st_ctime 
		       $st_blksize $st_blocks
		    );
    %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}
use vars @EXPORT_OK;

use Fcntl qw(S_IRUSR S_IWUSR S_IXUSR);

BEGIN {
    # These constants will croak on use if the platform doesn't define
    # them. It's important to avoid inflicting that on the user.
    no strict 'refs';
    for (qw(suid sgid svtx)) {
        my $val = eval { &{"Fcntl::S_I\U$_"} };
        *{"_$_"} = defined $val ? sub { $_[0] & $val ? 1 : "" } : sub { "" };
    }
    for (qw(SOCK CHR BLK REG DIR FIFO LNK)) {
        *{"S_IS$_"} = defined eval { &{"Fcntl::S_IF$_"} }
            ? \&{"Fcntl::S_IS$_"} : sub { "" };
    }
}

# from doio.c
sub _ingroup {

    $^O eq "MacOS"  and return 1;
    
    my ($gid, $eff)   = @_;

    # I am assuming that since VMS doesn't have getgroups(2), $) will
    # always only contain a single entry.
    $^O eq "VMS"    and return $_[0] == $);

    my ($egid, @supp) = split " ", $);
    my ($rgid)        = split " ", $(;

    $gid == ($eff ? $egid : $rgid)  and return 1;
    grep $gid == $_, @supp          and return 1;

    return "";
}

# VMS uses the Unix version of the routine, even though this is very
# suboptimal. VMS has a permissions structure that doesn't really fit
# into struct stat, and unlike on Win32 the normal -X operators respect
# that, but unfortunately by the time we get here we've already lost the
# information we need. It looks to me as though if we were to preserve
# the st_devnam entry of vmsish.h's fake struct stat (which actually
# holds the filename) it might be possible to do this right, but both
# getting that value out of the struct (perl's stat doesn't return it)
# and interpreting it later would require this module to have an XS
# component (at which point we might as well just call Perl_cando and
# have done with it).
    
if (grep $^O eq $_, qw/os2 MSWin32 dos/) {

    # from doio.c
    *cando = sub { ($_[0] & $_[2]->mode) ? 1 : "" };
}
else {

    # from doio.c
    *cando = sub {
        my ($s, $mode, $eff) = @_;
        my $uid = $eff ? $> : $<;

        $uid == 0                   and return 1;

        # This code basically assumes that the rwx bits of the mode are
        # the 0777 bits, but so does Perl_cando.
        if ($s->uid == $uid) {
            $s->mode & $mode        and return 1;
        }
        elsif (_ingroup($s->gid, $eff)) {
            $s->mode & ($mode >> 3) and return 1;
        }
        else {
            $s->mode & ($mode >> 6) and return 1;
        }
        return "";
    };
}

my %op = (
    r => sub { cando($_[0], S_IRUSR, 1) },
    w => sub { cando($_[0], S_IWUSR, 1) },
    x => sub { cando($_[0], S_IXUSR, 1) },
    o => sub { $_[0]->uid == $>         },

    R => sub { cando($_[0], S_IRUSR, 0) },
    W => sub { cando($_[0], S_IWUSR, 0) },
    X => sub { cando($_[0], S_IXUSR, 0) },
    O => sub { $_[0]->uid == $<         },

    e => sub { 1 },
    z => sub { $_[0]->size == 0     },
    s => sub { $_[0]->size          },

    f => sub { S_ISREG ($_[0]->mode) },
    d => sub { S_ISDIR ($_[0]->mode) },
    l => sub { S_ISLNK ($_[0]->mode) },
    p => sub { S_ISFIFO($_[0]->mode) },
    S => sub { S_ISSOCK($_[0]->mode) },
    b => sub { S_ISBLK ($_[0]->mode) },
    c => sub { S_ISCHR ($_[0]->mode) },

    u => sub { _suid($_[0]->mode) },
    g => sub { _sgid($_[0]->mode) },
    k => sub { _svtx($_[0]->mode) },

    M => sub { ($^T - $_[0]->mtime) / 86400 },
    C => sub { ($^T - $_[0]->ctime) / 86400 },
    A => sub { ($^T - $_[0]->atime) / 86400 },
);

use overload 
    fallback => 1,
    -X => sub {
        my ($s, $op) = @_;
        if ($op{$op}) {
            return $op{$op}->($_[0]);
        }
        else {
            croak "-$op is not implemented on a File::stat object";
        }
    };

# Class::Struct forbids use of @ISA
sub import { goto &Exporter::import }

use Class::Struct qw(struct);
struct 'File::stat' => [
     map { $_ => '$' } qw{
	 dev ino mode nlink uid gid rdev size
	 atime mtime ctime blksize blocks
     }
];

sub populate (@) {
    return unless @_;
    my $stob = new();
    @$stob = (
	$st_dev, $st_ino, $st_mode, $st_nlink, $st_uid, $st_gid, $st_rdev,
        $st_size, $st_atime, $st_mtime, $st_ctime, $st_blksize, $st_blocks ) 
	    = @_;
    return $stob;
} 

sub lstat ($)  { populate(CORE::lstat(shift)) }

sub stat ($) {
    my $arg = shift;
    my $st = populate(CORE::stat $arg);
    return $st if defined $st;
	my $fh;
    {
		local $!;
		no strict 'refs';
		require Symbol;
		$fh = \*{ Symbol::qualify( $arg, caller() )};
		return unless defined fileno $fh;
	}
    return populate(CORE::stat $fh);
}

1;
__END__

=head1 NAME

File::stat - by-name interface to Perl's built-in stat() functions

=head1 SYNOPSIS

 use File::stat;
 $st = stat($file) or die "No $file: $!";
 if ( ($st->mode & 0111) && $st->nlink > 1) ) {
     print "$file is executable with lotsa links\n";
 } 

 use File::stat qw(:FIELDS);
 stat($file) or die "No $file: $!";
 if ( ($st_mode & 0111) && ($st_nlink > 1) ) {
     print "$file is executable with lotsa links\n";
 } 

=head1 DESCRIPTION

This module's default exports override the core stat() 
and lstat() functions, replacing them with versions that return 
"File::stat" objects.  This object has methods that
return the similarly named structure field name from the
stat(2) function; namely,
dev,
ino,
mode,
nlink,
uid,
gid,
rdev,
size,
atime,
mtime,
ctime,
blksize,
and
blocks.  

You may also import all the structure fields directly into your namespace
as regular variables using the :FIELDS import tag.  (Note that this still
overrides your stat() and lstat() functions.)  Access these fields as
variables named with a preceding C<st_> in front their method names.
Thus, C<$stat_obj-E<gt>dev()> corresponds to $st_dev if you import
the fields.

To access this functionality without the core overrides,
pass the C<use> an empty import list, and then access
function functions with their full qualified names.
On the other hand, the built-ins are still available
via the C<CORE::> pseudo-package.

=head1 BUGS

As of Perl 5.8.0 after using this module you cannot use the implicit
C<$_> or the special filehandle C<_> with stat() or lstat(), trying
to do so leads into strange errors.  The workaround is for C<$_> to
be explicit

    my $stat_obj = stat $_;

and for C<_> to explicitly populate the object using the unexported
and undocumented populate() function with CORE::stat():

    my $stat_obj = File::stat::populate(CORE::stat(_));

=head1 NOTE

While this class is currently implemented using the Class::Struct
module to build a struct-like class, you shouldn't rely upon this.

=head1 AUTHOR

Tom Christiansen
