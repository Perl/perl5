package open;
use Carp;
$open::hint_bits = 0x20000;

# layers array and hash mainly manipulated by C code in perlio.c
use vars qw(%layers @layers);

# Populate hash in non-PerlIO case
%layers = (crlf => 1, raw => 0) unless (@layers);

# warn join(',',keys %layers);

our $VERSION = '1.00';

sub import {
    my ($class,@args) = @_;
    croak("`use open' needs explicit list of disciplines") unless @args;
    $^H |= $open::hint_bits;
    my ($in,$out) = split(/\0/,(${^OPEN} || '\0'));
    my @in  = split(/\s+/,$in);
    my @out = split(/\s+/,$out);
    while (@args) {
	my $type = shift(@args);
	my $discp = shift(@args);
	my @val;
	foreach my $layer (split(/\s+/,$discp)) {
            $layer =~ s/^://;
	    unless(exists $layers{$layer}) {
		carp("Unknown discipline layer '$layer'");
	    }
	    push(@val,":$layer");
	    if ($layer =~ /^(crlf|raw)$/) {
		$^H{"open_$type"} = $layer;
	    }
	}
	if ($type eq 'IN') {
	    $in  = join(' ',@val);
	}
	elsif ($type eq 'OUT') {
	    $out = join(' ',@val);
	}
	else {
	    croak "Unknown discipline class '$type'";
	}
    }
    ${^OPEN} = join('\0',$in,$out);
}

1;
__END__

=head1 NAME

open - perl pragma to set default disciplines for input and output

=head1 SYNOPSIS

    use open IN => ":crlf", OUT => ":raw";

=head1 DESCRIPTION

Full-fledged support for I/O disciplines is now implemented provided
Perl is configured to use PerlIO as its IO system (which is now the
default).

The C<open> pragma serves as one of the interfaces to declare default
"layers" (aka disciplines) for all I/O.

The C<open> pragma is used to declare one or more default layers for
I/O operations.  Any open(), readpipe() (aka qx//) and similar
operators found within the lexical scope of this pragma will use the
declared defaults.

When open() is given an explicit list of layers they are appended to
the list declared using this pragma.

Directory handles may also support disciplines in future.

=head1 NONPERLIO FUNCTIONALITY

If Perl is not built to use PerlIO as its IO system then only the two
pseudo-disciplines ":raw" and ":crlf" are available.

The ":raw" discipline corresponds to "binary mode" and the ":crlf"
discipline corresponds to "text mode" on platforms that distinguish
between the two modes when opening files (which is many DOS-like
platforms, including Windows).  These two disciplines are no-ops on
platforms where binmode() is a no-op, but perform their functions
everywhere if PerlIO is enabled.

=head1 IMPLEMENTATION DETAILS

There are two package variables C<%layers> and C<@layers> which are
mainly manipulated by C code in F<perlio.c>, but are visible to the
nosy:

  print "Have ",join(',',keys %open::layers),"\n";
  print "Using ",join(',',@open::layers),"\n";

The C<%open::layers> hash is a record of the available "layers" that
may be pushed onto a C<PerlIO> stream. The values of the hash are Perl
objects, of class C<PerlIO::Layer> which are created by the C code in
F<perlio.c>.  As yet there is nothing useful you can do with the
objects at the perl level.

The C<@open::layers> array is the current set of layers and their
arguments.  The array consists of layer => argument pairs and I<must>
always have even number of entries and the even entries I<must> be
C<PerlIO::Layer> objects or Perl will "die" when it attempts to open a
filehandle. In most cases the odd entry will be C<undef>, but in the
case of (say) ":encoding(iso-8859-1)" it will be 'iso-8859-1'. These
argument entries are currently restricted to being strings.

When a new C<PerlIO> stream is opened, the C code looks at the array
to determine the default layers to be pushed. So with care it is
possible to manipulate the default layer "stack":

    splice(@PerlIO::layers,-2,2);
    push(@PerlIO::layers,$PerlIO::layers{'stdio'} => undef);

=head1 SEE ALSO

L<perlfunc/"binmode">, L<perlfunc/"open">, L<perlunicode>, L<PerlIO>

=cut
