package encoding;
our $VERSION = do { my @r = (q$Revision: 1.25 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Encode;
use strict;

BEGIN {
    if (ord("A") == 193) {
	require Carp;
	Carp::croak "encoding pragma does not support EBCDIC platforms";
    }
}

sub import {
    my $class = shift;
    my $name  = shift;
    my %arg = @_;
    $name ||= $ENV{PERL_ENCODING};

    my $enc = find_encoding($name);
    unless (defined $enc) {
	require Carp;
	Carp::croak "Unknown encoding '$name'";
    }
    ${^ENCODING} = $enc; # this is all you need, actually.

    # $_OPEN_ORIG = ${^OPEN};
    for my $h (qw(STDIN STDOUT STDERR)){
	if ($arg{$h}){
	    unless (defined find_encoding($name)) {
		require Carp;
		Carp::croak "Unknown encoding for $h, '$arg{$h}'";
	    }
	    eval qq{ binmode($h, ":encoding($arg{$h})") };
	}else{
	    eval qq{ binmode($h, ":encoding($name)") };
	}
	if ($@){
	    require Carp;
	    Carp::croak($@);
	}
    }
    return 1; # I doubt if we need it, though
}

sub unimport{
    no warnings;
    undef ${^ENCODING};
    binmode(STDIN,  ":raw");
    binmode(STDOUT, ":raw");
    # Leaves STDERR alone.
    # binmode(STDERR, ":raw");
}

1;
__END__
=pod

=head1 NAME

encoding -  allows you to write your script in non-asii or non-utf8

=head1 SYNOPSIS

  use encoding "euc-jp"; # Jperl!

  # or you can even do this if your shell supports euc-jp

  > perl -Mencoding=euc-jp -e '...'

  # or from the shebang line

  #!/your/path/to/perl -Mencoding=euc-jp

  # more control

  # A simple euc-jp => utf-8 converter
  use encoding "euc-jp", STDOUT => "utf8";  while(<>){print};

  # "no encoding;" supported (but not scoped!)
  no encoding;

=head1 ABSTRACT

Perl 5.6.0 has introduced Unicode support.  You could apply
C<substr()> and regexes even to complex CJK characters -- so long as
the script was written in UTF-8.  But back then text editors that
support UTF-8 was still rare and many users rather chose to writer
scripts in legacy encodings, given up whole new feature of Perl 5.6.

With B<encoding> pragma, you can write your script in any encoding you like
(so long as the C<Encode> module supports it) and still enjoy Unicode
support.  You can write a code in EUC-JP as follows;

  my $Rakuda = "\xF1\xD1\xF1\xCC"; # Camel in Kanji
               #<-char-><-char->   # 4 octets
  s/\bCamel\b/$Rakuda/;

And with C<use encoding "euc-jp"> in effect, it is the same thing as
the code in UTF-8 as follow.

  my $Rakuda = "\x{99F1}\x{99DD}"; # who Unicode Characters
  s/\bCamel\b/$Rakuda/;

The B<encoding> pragma also modifies the file handle disciplines of
STDIN, STDOUT, and STDERR to the specified encoding.  Therefore,

  use encoding "euc-jp";
  my $message = "Camel is the symbol of perl.\n";
  my $Rakuda = "\xF1\xD1\xF1\xCC"; # Camel in Kanji
  $message =~ s/\bCamel\b/$Rakuda/;
  print $message;

Will print "\xF1\xD1\xF1\xCC is the symbol of perl.\n", not
"\x{99F1}\x{99DD} is the symbol of perl.\n".

You can override this by giving extra arguments.  See below.

=head1 USAGE

=over 4

=item use encoding [I<ENCNAME>] ;

Sets the script encoding to I<ENCNAME> and file handle disciplines of
STDIN, STDOUT are set to ":encoding(I<ENCNAME>)". Note STDERR will not 
be changed.

If no encoding is specified, the environment variable L<PERL_ENCODING>
is consulted. If no  encoding can be found, C<Unknown encoding 'I<ENCNAME>'>
error will be thrown. 

Note that non-STD file handles remain unaffected.  Use C<use open> or
C<binmode> to change disciplines of those.

=item use encoding I<ENCNAME> [ STDIN => I<ENCNAME_IN> ...] ;

You can also individually set encodings of STDIN, STDOUT, and STDERR
via STDI<FH> => I<ENCNAME_FH> form.  In this case, you cannot omit the
first I<ENCNAME>.

=item no encoding;

Unsets the script encoding and the disciplines of STDIN, STDOUT are
reset to ":raw".

=back

=head1 CAVEATS

=head2 NOT SCOPED

The pragma is a per script, not a per block lexical.  Only the last
C<use encoding> or C<matters, and it affects B<the whole script>.
Though <no encoding> pragma is supported and C<use encoding> can
appear as many times as you want in a given script, the multiple use
of this pragma is discouraged.

=head2 DO NOT MIX MULTIPLE ENCODINGS

Notice that only literals (string or regular expression) having only
legacy code points are affected: if you mix data like this

	\xDF\x{100}

the data is assumed to be in (Latin 1 and) Unicode, not in your native
encoding.  In other words, this will match in "greek":

	"\xDF" =~ /\x{3af}/

but this will not

	"\xDF\x{100}" =~ /\x{3af}\x{100}/

since the C<\xDF> on the left will B<not> be upgraded to C<\x{3af}>
because of the C<\x{100}> on the left.  You should not be mixing your
legacy data and Unicode in the same string.

This pragma also affects encoding of the 0x80..0xFF code point range:
normally characters in that range are left as eight-bit bytes (unless
they are combined with characters with code points 0x100 or larger,
in which case all characters need to become UTF-8 encoded), but if
the C<encoding> pragma is present, even the 0x80..0xFF range always
gets UTF-8 encoded.

After all, the best thing about this pragma is that you don't have to
resort to \x... just to spell your name in native encoding.  So feel
free to put your strings in your encoding in quotes and regexes.

=head1 EXAMPLE - Greekperl

    use encoding "iso 8859-7";

    # The \xDF of ISO 8859-7 (Greek) is \x{3af} in Unicode.

    $a = "\xDF";
    $b = "\x{100}";

    printf "%#x\n", ord($a); # will print 0x3af, not 0xdf

    $c = $a . $b;

    # $c will be "\x{3af}\x{100}", not "\x{df}\x{100}".

    # chr() is affected, and ...

    print "mega\n"  if ord(chr(0xdf)) == 0x3af;

    # ... ord() is affected by the encoding pragma ...

    print "tera\n" if ord(pack("C", 0xdf)) == 0x3af;

    # ... as are eq and cmp ...

    print "peta\n" if "\x{3af}" eq  pack("C", 0xdf);
    print "exa\n"  if "\x{3af}" cmp pack("C", 0xdf) == 0;

    # ... but pack/unpack C are not affected, in case you still
    # want back to your native encoding

    print "zetta\n" if unpack("C", (pack("C", 0xdf))) == 0xdf;

=head1 KNOWN PROBLEMS

For native multibyte encodings (either fixed or variable length)
the current implementation of the regular expressions may introduce
recoding errors for longer regular expression literals than 127 bytes.

The encoding pragma is not supported on EBCDIC platforms.
(Porters wanted.)

=head1 SEE ALSO

L<perlunicode>, L<Encode>, L<open>

=cut
