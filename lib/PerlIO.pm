package PerlIO;

# Map layer name to package that defines it
my %alias = (encoding => 'Encode');

sub import
{
 my $class = shift;
 while (@_)
  {
   my $layer = shift;
   if (exists $alias{$layer})
    {
     $layer = $alias{$layer}
    }
   else
    {
     $layer = "${class}::$layer";
    }
   eval "require $layer";
   warn $@ if $@;
  }
}

1;
__END__

=head1 NAME

PerlIO - On demand loader for PerlIO layers and root of PerlIO::* name space

=head1 SYNOPSIS

  open($fh,">:crlf","my.txt")
  open($fh,">:raw","his.jpg")

  Shell:
    PERLIO=perlio perl ....

=head1 DESCRIPTION

When an undefined layer 'foo' is encountered in an C<open> or C<binmode> layer
specification then C code performs the equivalent of:

  use PerlIO 'foo';

The perl code in PerlIO.pm then attempts to locate a layer by doing

  require PerlIO::foo;

Otherwise the C<PerlIO> package is a place holder for additional
PerlIO related functions.

The following layers are currently defined:

=over 4

=item unix

Low level layer which calls C<read>, C<write> and C<lseek> etc.

=item stdio

Layer which calls C<fread>, C<fwrite> and C<fseek>/C<ftell> etc.  Note
that as this is "real" stdio it will ignore any layers beneath it and
got straight to the operating system via the C library as usual.

=item perlio

This is a re-implementation of "stdio-like" buffering written as a
PerlIO "layer".  As such it will call whatever layer is below it for
its operations.

=item crlf

A layer which does CRLF to "\n" translation distinguishing "text" and
"binary" files in the manner of MS-DOS and similar operating systems.

=item utf8

Declares that the stream accepts perl's internal encoding of
characters.  (Which really is UTF-8 on ASCII machines, but is
UTF-EBCDIC on EBCDIC machines.)  This allows any character perl can
represent to be read from or written to the stream. The UTF-X encoding
is chosen to render simple text parts (i.e.  non-accented letters,
digits and common punctuation) human readable in the encoded file.

Here is how to write your native data out using UTF-8 (or UTF-EBCDIC)
and then read it back in.

	open(F, ">:utf8", "data.utf");
	print F $out;
	close(F);

	open(F, "<:utf8", "data.utf");
	$in = <F>;
	close(F);

=item raw

A pseudo-layer which performs two functions (which is messy, but
necessary to maintain compatibility with non-PerlIO builds of perl
and their way things have been documented elsewhere).

Firstly it forces the file handle to be considered binary at that
point in the layer stack,

Secondly in prevents the IO system seaching back before it in the
layer specification.  Thus:

    open($fh,":raw:perlio",...)

Forces the use of C<perlio> layer even if the platform default, or
C<use open> default is something else (such as ":encoding(iso-8859-7)")
which would interfere with binary nature of the stream.

=back

=head2 Defaults and how to override them

If the platform is MS-DOS like and normally does CRLF to "\n" translation
for text files then the default layers are :

  unix crlf

(The low level "unix" layer may be replaced by a platform specific low
level layer.)

Otherwise if C<Configure> found out how to do "fast" IO using system's
stdio, then the default layers are :

  unix stdio

Otherwise the default layers are

  unix perlio

These defaults may change once perlio has been better tested and tuned.

The default can be overridden by setting the environment variable
PERLIO to a space separated list of layers (unix or platform low level
layer is always pushed first).

This can be used to see the effect of/bugs in the various layers e.g.

  cd .../perl/t
  PERLIO=stdio  ./perl harness
  PERLIO=perlio ./perl harness

=head1 AUTHOR

Nick Ing-Simmons E<lt>nick@ing-simmons.netE<gt>

=head1 SEE ALSO

L<perlfunc/"binmode">, L<perlfunc/"open">, L<perlunicode>, L<Encode>

=cut

