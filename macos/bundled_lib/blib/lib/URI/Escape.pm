#
# $Id: Escape.pm,v 3.16 2000/08/16 18:45:23 gisle Exp $
#

package URI::Escape;
use strict;

=head1 NAME

URI::Escape - Escape and unescape unsafe characters

=head1 SYNOPSIS

 use URI::Escape;
 $safe = uri_escape("10% is enough\n");
 $verysafe = uri_escape("foo", "\0-\377");
 $str  = uri_unescape($safe);

=head1 DESCRIPTION

This module provides functions to escape and unescape URI strings as
defined by RFC 2396.  URIs consist of a restricted set of characters,
denoted as C<uric> in RFC 2396.  The restricted set of characters
consists of digits, letters, and a few graphic symbols chosen from
those common to most of the character encodings and input facilities
available to Internet users:

  "A" .. "Z", "a" .. "z", "0" .. "9",
  ";", "/", "?", ":", "@", "&", "=", "+", "$", ",",   # reserved
  "-", "_", ".", "!", "~", "*", "'", "(", ")"

In addition any byte (octet) can be represented in a URI by an escape
sequence; a triplet consisting of the character "%" followed by two
hexadecimal digits.  Bytes can also be represented directly by a
character using the US-ASCII character for that octet (iff the
character is part of C<uric>).

Some of the C<uric> characters are I<reserved> for use as delimiters
or as part of certain URI components.  These must be escaped if they are
to be treated as ordinary data.  Read RFC 2396 for further details.

The functions provided (and exported by default) from this module are:

=over 4

=item uri_escape($string, [$unsafe])

This function replaces all unsafe characters in the $string with their
escape sequences and returns the result.

The uri_escape() function takes an optional second argument that
overrides the set of characters that are to be escaped.  The set is
specified as a string that can be used in a regular expression
character class (between [ ]).  E.g.:

  "\x00-\x1f\x7f-\xff"          # all control and hi-bit characters
  "a-z"                         # all lower case characters
  "^A-Za-z"                     # everything not a letter

The default set of characters to be escaped is all those which are
I<not> part of the C<uric> character class shown above.

=item uri_unescape($string,...)

Returns a string with all %XX sequences replaced with the actual byte
(octet).

This does the same as:

   $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

but does not modify the string in-place as this RE would.  Using the
uri_unescape() function instead of the RE might make the code look
cleaner and is a few characters less to type.

In a simple benchmark test I made I got something like 40% slowdown by
calling the function (instead of the inline RE above) if a few chars
where unescaped and something like 700% slowdown if none where.  If
you are going to unescape a lot of times it might be a good idea to
inline the RE.

If the uri_unescape() function is passed multiple strings, then each
one is unescaped returned.

=back

The module can also export the C<%escapes> hash which contains the
mapping from all 256 bytes to the corresponding escape code.  Lookup
in this hash is faster than evaluating C<sprintf("%%%02X", ord($byte))>
each time.

=head1 SEE ALSO

L<URI>


=head1 COPYRIGHT

Copyright 1995-2000 Gisle Aas.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use vars qw(%escapes);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(uri_escape uri_unescape);
@EXPORT_OK = qw(%escapes);
$VERSION = sprintf("%d.%02d", q$Revision: 3.16 $ =~ /(\d+)\.(\d+)/);

use Carp ();

# Build a char->hex map
for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

my %subst;  # compiled patternes

sub uri_escape
{
    my($text, $patn) = @_;
    return undef unless defined $text;
    if (defined $patn){
	unless (exists  $subst{$patn}) {
	    # Because we can't compile the regex we fake it with a cached sub
	    $subst{$patn} =
	      eval "sub {\$_[0] =~ s/([$patn])/\$escapes{\$1}/g; }";
	    Carp::croak("uri_escape: $@") if $@;
	}
	&{$subst{$patn}}($text);
    } else {
	# Default unsafe characters. (RFC 2396 ^uric)
	$text =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
    }
    $text;
}

sub uri_unescape
{
    # Note from RFC1630:  "Sequences which start with a percent sign
    # but are not followed by two hexadecimal characters are reserved
    # for future extension"
    my $str = shift;
    if (@_ && wantarray) {
	# not executed for the common case of a single argument
	my @str = ($str, @_);  # need to copy
	foreach (@str) {
	  s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
	}
	return @str;
    }
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    $str;
}

1;
