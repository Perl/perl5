package IO::Handle;

=head1 NAME

IO::Handle - supply object methods for I/O handles

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

C<IO::Handle> is the base class for all other IO handle classes.
A C<IO::Handle> object is a reference to a symbol (see the C<Symbol> package)

=head1 CONSTRUCTOR

=over 4

=item new ()

Creates a new C<IO::Handle> object.

=item new_from_fd ( FD, MODE )

Creates a C<IO::Handle> like C<new> does.
It requires two parameters, which are passed to the method C<fdopen>;
if the fdopen fails, the object is destroyed. Otherwise, it is returned
to the caller.

=back

=head1 METHODS

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
    print
    printf
    sysread
    syswrite

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

=item $fh->getline

This works like <$fh> described in L<perlop/"I/O Operators">
except that it's more readable and can be safely called in an
array context but still returns just one line.

=item $fh->getlines

This works like <$fh> when called in an array context to
read all the remaining lines in a file, except that it's more readable.
It will also croak() if accidentally called in a scalar context.

=item $fh->fdopen ( FD, MODE )

C<fdopen> is like an ordinary C<open> except that its first parameter
is not a filename but rather a file handle name, a IO::Handle object,
or a file descriptor number.

=item $fh->write ( BUF, LEN [, OFFSET }\] )

C<write> is like C<write> found in C, that is it is the
opposite of read. The wrapper for the perl C<write> function is
called C<format_write>.

=item $fh->opened

Returns true if the object is currently a valid file descriptor.

=back

Lastly, a special method for working under B<-T> and setuid/gid scripts:

=over

=item $fh->untaint

Marks the object as taint-clean, and as such data read from it will also
be considered taint-clean. Note that this is a very trusting action to
take, and appropriate consideration for the data source and potential
vulnerability should be kept in mind.

=back

=head1 NOTE

A C<IO::Handle> object is a GLOB reference. Some modules that
inherit from C<IO::Handle> may want to keep object related variables
in the hash table part of the GLOB. In an attempt to prevent modules
trampling on each other I propose the that any such module should prefix
its variables with its own name separated by _'s. For example the IO::Socket
module keeps a C<timeout> variable in 'io_socket_timeout'.

=head1 SEE ALSO

L<perlfunc>, 
L<perlop/"I/O Operators">,
L<FileHandle>

=head1 BUGS

Due to backwards compatibility, all filehandles resemble objects
of class C<IO::Handle>, or actually classes derived from that class.
They actually aren't.  Which means you can't derive your own 
class from C<IO::Handle> and inherit those methods.

=head1 HISTORY

Derived from FileHandle.pm by Graham Barr E<lt>F<bodg@tiuk.ti.com>E<gt>

=cut

require 5.000;
use strict;
use vars qw($VERSION @EXPORT_OK $AUTOLOAD @ISA);
use Carp;
use Symbol;
use SelectSaver;

require Exporter;
@ISA = qw(Exporter);

$VERSION = "1.14";

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
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}


################################################
## Constructors, destructors.
##

sub new {
    my $class = ref($_[0]) || $_[0] || "IO::Handle";
    @_ == 1 or croak "usage: new $class";
    my $fh = gensym;
    bless $fh, $class;
}

sub new_from_fd {
    my $class = ref($_[0]) || $_[0] || "IO::Handle";
    @_ == 3 or croak "usage: new_from_fd $class FD, MODE";
    my $fh = gensym;
    shift;
    IO::Handle::fdopen($fh, @_)
	or return undef;
    bless $fh, $class;
}

sub DESTROY {
    my ($fh) = @_;

    # During global object destruction, this function may be called
    # on FILEHANDLEs as well as on the GLOBs that contains them.
    # Thus the following trickery.  If only the CORE file operators
    # could deal with FILEHANDLEs, it wouldn't be necessary...

    if ($fh =~ /=FILEHANDLE\(/) {
	local *TMP = $fh;
	close(TMP)
	    if defined fileno(TMP);
    }
    else {
	close($fh)
	    if defined fileno($fh);
    }
}

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

# flock
# select

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
    wantarray or
	croak 'Can\'t call $fh->getlines in a scalar context, use $fh->getline';
    my $this = shift;
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

sub sysread {
    @_ == 3 || @_ == 4 or croak '$fh->sysread(BUF, LEN [, OFFSET])';
    sysread($_[0], $_[1], $_[2], $_[3] || 0);
}

sub write {
    @_ == 3 || @_ == 4 or croak '$fh->write(BUF, LEN [, OFFSET])';
    local($\) = "";
    print { $_[0] } substr($_[1], $_[3] || 0, $_[2]);
}

sub syswrite {
    @_ == 3 || @_ == 4 or croak '$fh->syswrite(BUF, LEN [, OFFSET])';
    syswrite($_[0], $_[1], $_[2], $_[3] || 0);
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

sub fcntl {
    @_ == 3 || croak 'usage: $fh->fcntl( OP, VALUE );';
    my ($fh, $op, $val) = @_;
    my $r = fcntl($fh, $op, $val);
    defined $r && $r eq "0 but true" ? 0 : $r;
}

sub ioctl {
    @_ == 3 || croak 'usage: $fh->ioctl( OP, VALUE );';
    my ($fh, $op, $val) = @_;
    my $r = ioctl($fh, $op, $val);
    defined $r && $r eq "0 but true" ? 0 : $r;
}

1;
