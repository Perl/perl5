#

package IO::Handle;

=head1 NAME

IO::Handle - supply object methods for filehandles

=head1 SYNOPSIS

    use IO::Handle;

    $fh = new IO::Handle;
    if ($fh->open "< file") {
        print <$fh>;
        $fh->close;
    }

    $fh = new IO::Handle "> FOO";
    if (defined $fh) {
        print $fh "bar\n";
        $fh->close;
    }

    $fh = new IO::Handle "file", "r";
    if (defined $fh) {
        print <$fh>;
        undef $fh;       # automatically closes the file
    }

    $fh = new IO::Handle "file", O_WRONLY|O_APPEND;
    if (defined $fh) {
        print $fh "corge\n";
        undef $fh;       # automatically closes the file
    }

    $pos = $fh->getpos;
    $fh->setpos $pos;

    $fh->setvbuf($buffer_var, _IOLBF, 1024);

    autoflush STDOUT 1;

=head1 DESCRIPTION

C<IO::Handle::new> creates a C<IO::Handle>, which is a reference to a
newly created symbol (see the C<Symbol> package).  If it receives any
parameters, they are passed to C<IO::Handle::open>; if the open fails,
the C<IO::Handle> object is destroyed.  Otherwise, it is returned to
the caller.

C<IO::Handle::new_from_fd> creates a C<IO::Handle> like C<new> does.
It requires two parameters, which are passed to C<IO::Handle::fdopen>;
if the fdopen fails, the C<IO::Handle> object is destroyed.
Otherwise, it is returned to the caller.

C<IO::Handle::open> accepts one parameter or two.  With one parameter,
it is just a front end for the built-in C<open> function.  With two
parameters, the first parameter is a filename that may include
whitespace or other special characters, and the second parameter is
the open mode in either Perl form (">", "+<", etc.) or POSIX form
("w", "r+", etc.).

C<IO::Handle::fdopen> is like C<open> except that its first parameter
is not a filename but rather a file handle name, a IO::Handle object,
or a file descriptor number.

C<IO::Handle::write> is like C<write> found in C, that is it is the
opposite of read. The wrapper for the perl C<write> function is
called C<format_write>.

C<IO::Handle::opened> returns true if the object is currently a valid
file descriptor.

If the C functions fgetpos() and fsetpos() are available, then
C<IO::Handle::getpos> returns an opaque value that represents the
current position of the IO::Handle, and C<IO::Handle::setpos> uses
that value to return to a previously visited position.

If the C function setvbuf() is available, then C<IO::Handle::setvbuf>
sets the buffering policy for the IO::Handle.  The calling sequence
for the Perl function is the same as its C counterpart, including the
macros C<_IOFBF>, C<_IOLBF>, and C<_IONBF>, except that the buffer
parameter specifies a scalar variable to use as a buffer.  WARNING: A
variable used as a buffer by C<IO::Handle::setvbuf> must not be
modified in any way until the IO::Handle is closed or until
C<IO::Handle::setvbuf> is called again, or memory corruption may
result!

See L<perlfunc> for complete descriptions of each of the following
supported C<IO::Handle> methods, which are just front ends for the
corresponding built-in functions:
  
    close
    fileno
    getc
    gets
    eof
    read
    truncate
    stat

See L<perlvar> for complete descriptions of each of the following
supported C<IO::Handle> methods:

    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed
    format_write

Furthermore, for doing normal I/O you might need these:

=over 

=item $fh->print

See L<perlfunc/print>.

=item $fh->printf

See L<perlfunc/printf>.

=item $fh->getline

This works like <$fh> described in L<perlop/"I/O Operators">
except that it's more readable and can be safely called in an
array context but still returns just one line.

=item $fh->getlines

This works like <$fh> when called in an array context to
read all the remaining lines in a file, except that it's more readable.
It will also croak() if accidentally called in a scalar context.

=back

=head1

The reference returned from new is a GLOB reference. Some modules that
inherit from C<IO::Handle> may want to keep object related variables
in the hash table part of the GLOB. In an attempt to prevent modules
trampling on each other I propose the that any such module should prefix
its variables with its own name separated by _'s. For example the IO::Socket
module keeps a C<timeout> variable in 'io_socket_timeout'.

=head1 SEE ALSO

L<perlfunc>, 
L<perlop/"I/O Operators">,
L<POSIX/"FileHandle">

=head1 BUGS

Due to backwards compatibility, all filehandles resemble objects
of class C<IO::Handle>, or actually classes derived from that class.
They actually aren't.  Which means you can't derive your own 
class from C<IO::Handle> and inherit those methods.

=head1 HISTORY

Derived from FileHandle.pm by Graham Barr <bodg@tiuk.ti.com>

=cut

require 5.000;
use vars qw($VERSION @EXPORT_OK $AUTOLOAD);
use Carp;
use Symbol;
use SelectSaver;

require Exporter;
@ISA = qw(Exporter);

##
## TEMPORARY workaround as perl expects handles to be <FileHandle> objects
##
@FileHandle::ISA = qw(IO::Handle);


$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

@EXPORT_OK = qw(
    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed
    format_write

    print
    printf
    getline
    getlines

    SEEK_SET
    SEEK_CUR
    SEEK_END
    _IOFBF
    _IOLBF
    _IONBF

    _open_mode_string
);


################################################
## Interaction with the XS.
##

require DynaLoader;
@IO::ISA = qw(DynaLoader);
bootstrap IO $VERSION;

sub AUTOLOAD {
    if ($AUTOLOAD =~ /::(_?[a-z])/) {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD
    }
    my $constname = $AUTOLOAD;
    $constname =~ s/.*:://;
    my $val = constant($constname);
    defined $val or croak "$constname is not a valid IO::Handle macro";
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}


################################################
## Constructors, destructors.
##

sub new {
    @_ == 1 or croak 'usage: new IO::Handle';
    my $class = ref($_[0]) || $_[0];
    my $fh = gensym;
    bless $fh, $class;
}

sub new_from_fd {
    @_ == 3 or croak 'usage: new_from_fd IO::Handle FD, MODE';
    my $class = shift;
    my $fh = gensym;
    IO::Handle::fdopen($fh, @_)
	or return undef;
    bless $fh, $class;
    $fh->_ref_fd;
    $fh;
}

# FileHandle::DESTROY use to call close(). This creates a problem
# if 2 Handle objects have the same fd. sv_clear will call io close
# when the refcount in the xpvio becomes zero.
#
# It is defined as empty to stop AUTOLOAD being called :-)

sub DESTROY { }

################################################
## Open and close.
##

sub _open_mode_string {
    my ($mode) = @_;
    $mode =~ /^\+?(<|>>?)$/
      or $mode =~ s/^r(\+?)$/$1</
      or $mode =~ s/^w(\+?)$/$1>/
      or $mode =~ s/^a(\+?)$/$1>>/
      or croak "IO::Handle: bad open mode: $mode";
    $mode;
}

sub fdopen {
    @_ == 3 or croak 'usage: $fh->fdopen(FD, MODE)';
    my ($fh, $fd, $mode) = @_;
    local(*GLOB);

    if (ref($fd) && "".$fd =~ /GLOB\(/o) {
	# It's a glob reference; Alias it as we cannot get name of anon GLOBs
	my $n = qualify(*GLOB);
	*GLOB = *{*$fd};
	$fd =  $n;
    } elsif ($fd =~ m#^\d+$#) {
	# It's an FD number; prefix with "=".
	$fd = "=$fd";
    }

    open($fh, _open_mode_string($mode) . '&' . $fd)
	? $fh : undef;
}

sub close {
    @_ == 1 or croak 'usage: $fh->close()';
    my($fh) = @_;
    my $r = close($fh);

    # This may seem as though it should be in IO::Pipe, but the
    # object gets blessed out of IO::Pipe when reader/writer is called
    waitpid(${*$fh}{'io_pipe_pid'},0)
	if(defined ${*$fh}{'io_pipe_pid'});

    $r;
}

################################################
## Normal I/O functions.
##

# fcntl
# flock
# ioctl
# select
# sysread
# syswrite

sub opened {
    @_ == 1 or croak 'usage: $fh->opened()';
    defined fileno($_[0]);
}

sub fileno {
    @_ == 1 or croak 'usage: $fh->fileno()';
    fileno($_[0]);
}

sub getc {
    @_ == 1 or croak 'usage: $fh->getc()';
    getc($_[0]);
}

sub gets {
    @_ == 1 or croak 'usage: $fh->gets()';
    my ($handle) = @_;
    scalar <$handle>;
}

sub eof {
    @_ == 1 or croak 'usage: $fh->eof()';
    eof($_[0]);
}

sub print {
    @_ or croak 'usage: $fh->print([ARGS])';
    my $this = shift;
    print $this @_;
}

sub printf {
    @_ >= 2 or croak 'usage: $fh->printf(FMT,[ARGS])';
    my $this = shift;
    printf $this @_;
}

sub getline {
    @_ == 1 or croak 'usage: $fh->getline';
    my $this = shift;
    return scalar <$this>;
} 

sub getlines {
    @_ == 1 or croak 'usage: $fh->getline()';
    my $this = shift;
    wantarray or
	croak "Can't call IO::Handle::getlines in a scalar context, use IO::Handle::getline";
    return <$this>;
}

sub truncate {
    @_ == 2 or croak 'usage: $fh->truncate(LEN)';
    truncate($_[0], $_[1]);
}

sub read {
    @_ == 3 || @_ == 4 or croak '$fh->read(BUF, LEN [, OFFSET])';
    read($_[0], $_[1], $_[2], $_[3] || 0);
}

sub write {
    @_ == 3 || @_ == 4 or croak '$fh->write(BUF, LEN [, OFFSET])';
    local($\) = "";
    print { $_[0] } substr($_[1], $_[3] || 0, $_[2]);
}

sub stat {
    @_ == 1 or croak 'usage: $fh->stat()';
    stat($_[0]);
}

################################################
## State modification functions.
##

sub autoflush {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $|;
    $| = @_ > 1 ? $_[1] : 1;
    $prev;
}

sub output_field_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $,;
    $, = $_[1] if @_ > 1;
    $prev;
}

sub output_record_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $\;
    $\ = $_[1] if @_ > 1;
    $prev;
}

sub input_record_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $/;
    $/ = $_[1] if @_ > 1;
    $prev;
}

sub input_line_number {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $.;
    $. = $_[1] if @_ > 1;
    $prev;
}

sub format_page_number {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $%;
    $% = $_[1] if @_ > 1;
    $prev;
}

sub format_lines_per_page {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $=;
    $= = $_[1] if @_ > 1;
    $prev;
}

sub format_lines_left {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $-;
    $- = $_[1] if @_ > 1;
    $prev;
}

sub format_name {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $~;
    $~ = qualify($_[1], caller) if @_ > 1;
    $prev;
}

sub format_top_name {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $^;
    $^ = qualify($_[1], caller) if @_ > 1;
    $prev;
}

sub format_line_break_characters {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $:;
    $: = $_[1] if @_ > 1;
    $prev;
}

sub format_formfeed {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $^L;
    $^L = $_[1] if @_ > 1;
    $prev;
}

sub formline {
    my $fh = shift;
    my $picture = shift;
    local($^A) = $^A;
    local($\) = "";
    formline($picture, @_);
    print $fh $^A;
}

sub format_write {
    @_ < 3 || croak 'usage: $fh->write( [FORMAT_NAME] )';
    if (@_ == 2) {
	my ($fh, $fmt) = @_;
	my $oldfmt = $fh->format_name($fmt);
	write($fh);
	$fh->format_name($oldfmt);
    } else {
	write($_[0]);
    }
}


1;
