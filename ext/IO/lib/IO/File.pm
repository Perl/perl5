#

package IO::File;

=head1 NAME

IO::File - supply object methods for filehandles

=head1 SYNOPSIS

    use IO::File;

    $fh = new IO::File;
    if ($fh->open "< file") {
        print <$fh>;
        $fh->close;
    }

    $fh = new IO::File "> FOO";
    if (defined $fh) {
        print $fh "bar\n";
        $fh->close;
    }

    $fh = new IO::File "file", "r";
    if (defined $fh) {
        print <$fh>;
        undef $fh;       # automatically closes the file
    }

    $fh = new IO::File "file", O_WRONLY|O_APPEND;
    if (defined $fh) {
        print $fh "corge\n";
        undef $fh;       # automatically closes the file
    }

    $pos = $fh->getpos;
    $fh->setpos $pos;

    $fh->setvbuf($buffer_var, _IOLBF, 1024);

    autoflush STDOUT 1;

=head1 DESCRIPTION

C<IO::File::new> creates a C<IO::File>, which is a reference to a
newly created symbol (see the C<Symbol> package).  If it receives any
parameters, they are passed to C<IO::File::open>; if the open fails,
the C<IO::File> object is destroyed.  Otherwise, it is returned to
the caller.

C<IO::File::open> accepts one parameter or two.  With one parameter,
it is just a front end for the built-in C<open> function.  With two
parameters, the first parameter is a filename that may include
whitespace or other special characters, and the second parameter is
the open mode in either Perl form (">", "+<", etc.) or POSIX form
("w", "r+", etc.).

=head1 SEE ALSO

L<perlfunc>, 
L<perlop/"I/O Operators">,
L<"IO::Handle">
L<"IO::Seekable">

=head1 HISTORY

Derived from FileHandle.pm by Graham Barr <bodg@tiuk.ti.com>

=head1 REVISION

$Revision: 1.3 $

=cut

require 5.000;
use vars qw($VERSION @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Symbol;
use English;
use SelectSaver;
use IO::Handle qw(_open_mode_string);
use IO::Seekable;

require Exporter;
require DynaLoader;

@ISA = qw(IO::Handle IO::Seekable Exporter DynaLoader);

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

@EXPORT = @IO::Seekable::EXPORT;

################################################
## If the Fcntl extension is available,
##  export its constants.
##

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export $pkg, $callpkg;
    eval {
	require Fcntl;
	Exporter::export 'Fcntl', $callpkg;
    };
};


################################################
## Constructor
##

sub new {
    @_ >= 1 && @_ <= 3 or croak 'usage: new IO::File [FILENAME [,MODE]]';
    my $class = shift;
    my $fh = $class->SUPER::new();
    if (@_) {
	$fh->open(@_)
	    or return undef;
    }
    $fh;
}

################################################
## Open
##

sub open {
    @_ >= 2 && @_ <= 4 or croak 'usage: $fh->open(FILENAME [,MODE [,PERMS]])';
    my ($fh, $file) = @_;
    if (@_ > 2) {
	my ($mode, $perms) = @_[2, 3];
	if ($mode =~ /^\d+$/) {
	    defined $perms or $perms = 0666;
	    return sysopen($fh, $file, $mode, $perms);
	}
        $file = "./" . $file unless $file =~ m#^/#;
	$file = _open_mode_string($mode) . " $file\0";
    }
    open($fh, $file);
}

1;
