package utf8;

sub import {
    $^H |= 0x00000008;
    $enc{caller()} = $_[1] if $_[1];
}

sub unimport {
    $^H &= ~0x00000008;
}

sub AUTOLOAD {
    require "utf8_heavy.pl";
    goto &$AUTOLOAD;
}

1;
__END__

=head1 NAME

utf8 - Perl pragma to turn on UTF-8 and Unicode support

=head1 SYNOPSIS

    use utf8;
    no utf8;

=head1 DESCRIPTION

The utf8 pragma tells Perl to use UTF-8 as its internal string
representation for the rest of the enclosing block.  (The "no utf8"
pragma tells Perl to switch back to ordinary byte-oriented processing
for the rest of the enclosing block.)  Under utf8, many operations that
formerly operated on bytes change to operating on characters.  For
ASCII data this makes no difference, because UTF-8 stores ASCII in
single bytes, but for any character greater than C<chr(127)>, the
character is stored in a sequence of two or more bytes, all of which
have the high bit set.  But by and large, the user need not worry about
this, because the utf8 pragma hides it from the user.  A character
under utf8 is logically just a number ranging from 0 to 2**32 or so.
Larger characters encode to longer sequences of bytes, but again, this
is hidden.

Use of the utf8 pragma has the following effects:

=over 4

=item *

Strings and patterns may contain characters that have an ordinal value
larger than 255.  Presuming you use a Unicode editor to edit your
program, these will typically occur directly within the literal strings
as UTF-8 characters, but you can also specify a particular character
with an extension of the C<\x> notation.  UTF-8 characters are
specified by putting the hexidecimal code within curlies after the
C<\x>.  For instance, a Unicode smiley face is C<\x{263A}>.  A
character in the Latin-1 range (128..255) should be written C<\x{ab}>
rather than C<\xab>, since the former will turn into a two-byte UTF-8
code, while the latter will continue to be interpreted as generating a
8-bit byte rather than a character.  In fact, if -w is turned on, it will
produce a warning that you might be generating invalid UTF-8.

=item *

Identifiers within the Perl script may contain Unicode alphanumeric
characters, including ideographs.  (You are currently on your own when
it comes to using the canonical forms of characters--Perl doesn't (yet)
attempt to canonicalize variable names for you.)

=item *

Regular expressions match characters instead of bytes.  For instance,
"." matches a character instead of a byte.  (However, the C<\C> pattern
is provided to force a match a single byte ("C<char>" in C, hence
C<\C>).)

=item *

Character classes in regular expressions match characters instead of
bytes, and match against the character properties specified in the
Unicode properties database.  So C<\w> can be used to match an ideograph,
for instance.

=item *

Named Unicode properties and block ranges make be used as character
classes via the new C<\p{}> (matches property) and C<\P{}> (doesn't
match property) constructs.  For instance, C<\p{Lu}> matches any
character with the Unicode uppercase property, while C<\p{M}> matches
any mark character.  Single letter properties may omit the brackets, so
that can be written C<\pM> also.  Many predefined character classes are
available, such as C<\p{IsMirrored}> and  C<\p{InTibetan}>.

=item *

The special pattern C<\X> match matches any extended Unicode sequence
(a "combining character sequence" in Standardese), where the first
character is a base character and subsequent characters are mark
characters that apply to the base character.  It is equivalent to
C<(?:\PM\pM*)>.

=item *

The C<tr///> operator translates characters instead of bytes.  It can also
be forced to translate between 8-bit codes and UTF-8 regardless of the
surrounding utf8 state.  For instance, if you know your input in Latin-1,
you can say:

    use utf8;
    while (<>) {
	tr/\0-\xff//CU;		# latin1 char to utf8
	...
    }

Similarly you could translate your output with

    tr/\0-\x{ff}//UC;		# utf8 to latin1 char

No, C<s///> doesn't take /U or /C (yet?).

=item *

Case translation operators use the Unicode case translation tables.
Note that C<uc()> translates to uppercase, while C<ucfirst> translates
to titlecase (for languages that make the distinction).  Naturally
the corresponding backslash sequences have the same semantics.

=item *

Most operators that deal with positions or lengths in the string will
automatically switch to using character positions, including C<chop()>,
C<substr()>, C<pos()>, C<index()>, C<rindex()>, C<sprintf()>,
C<write()>, and C<length()>.  Operators that specifically don't switch
include C<vec()>, C<pack()>, and C<unpack()>.  Operators that really
don't care include C<chomp()>, as well as any other operator that
treats a string as a bucket of bits, such as C<sort()>, and the
operators dealing with filenames.

=item *

The C<pack()>/C<unpack()> letters "C<c>" and "C<C>" do I<not> change,
since they're often used for byte-oriented formats.  (Again, think
"C<char>" in the C language.)  However, there is a new "C<U>" specifier
that will convert between UTF-8 characters and integers.  (It works
outside of the utf8 pragma too.)

=item *

The C<chr()> and C<ord()> functions work on characters.  This is like
C<pack("U")> and C<unpack("U")>, not like C<pack("C")> and
C<unpack("C")>.  In fact, the latter are how you now emulate
byte-oriented C<chr()> and C<ord()> under utf8.

=item *

And finally, C<scalar reverse()> reverses by character rather than by byte.

=back

=head1 CAVEATS

As of yet, there is no method for automatically coercing input and
output to some encoding other than UTF-8.  This is planned in the near
future, however.

In any event, you'll need to keep track of whether interfaces to other
modules expect UTF-8 data or something else.  The utf8 pragma does not
magically mark strings for you in order to remember their encoding, nor
will any automatic coercion happen (other than that eventually planned
for I/O).  If you want such automatic coercion, you can build yourself
a set of pretty object-oriented modules.  Expect it to run considerably
slower than than this low-level support.

Use of locales with utf8 may lead to odd results.  Currently there is
some attempt to apply 8-bit locale info to characters in the range
0..255, but this is demonstrably incorrect for locales that use
characters above that range (when mapped into Unicode).  It will also
tend to run slower.  Avoidance of locales is strongly encouraged.

=cut
