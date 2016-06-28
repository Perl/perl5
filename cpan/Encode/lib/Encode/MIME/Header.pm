package Encode::MIME::Header;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = do { my @r = ( q$Revision: 2.23 $ =~ /\d+/g ); sprintf "%d." . "%02d" x $#r, @r };
use Encode qw(find_encoding encode_utf8 decode_utf8);
use MIME::Base64;
use Carp;

my %seed = (
    decode_b => '1',    # decodes 'B' encoding ?
    decode_q => '1',    # decodes 'Q' encoding ?
    encode   => 'B',    # encode with 'B' or 'Q' ?
    bpl      => 75,     # bytes per line
);

$Encode::Encoding{'MIME-Header'} =
  bless { %seed, Name => 'MIME-Header', } => __PACKAGE__;

$Encode::Encoding{'MIME-B'} = bless {
    %seed,
    decode_q => 0,
    Name     => 'MIME-B',
} => __PACKAGE__;

$Encode::Encoding{'MIME-Q'} = bless {
    %seed,
    decode_b => 0,
    encode   => 'Q',
    Name     => 'MIME-Q',
} => __PACKAGE__;

use parent qw(Encode::Encoding);

sub needs_lines { 1 }
sub perlio_ok   { 0 }

# RFC 2047 and RFC 2231 grammar
my $re_charset = qr/[-0-9A-Za-z_]+/;
my $re_language = qr/[A-Za-z]{1,8}(?:-[A-Za-z]{1,8})*/;
my $re_encoding = qr/[QqBb]/;
my $re_encoded_text = qr/[^\?\s]*/;
my $re_encoded_word = qr/=\?$re_charset(?:\*$re_language)?\?$re_encoding\?$re_encoded_text\?=/;
my $re_capture_encoded_word = qr/=\?($re_charset)((?:\*$re_language)?)\?($re_encoding)\?($re_encoded_text)\?=/;

our $STRICT_DECODE = 0;

sub decode($$;$) {
    use utf8;
    my ( $obj, $str, $chk ) = @_;

    # multi-line header to single line
    $str =~ s/(?:\r\n|[\r\n])([ \t])/$1/gos;

    # decode each line separately
    my @input = split /(\r\n|\r|\n)/o, $str;
    my $output = substr($str, 0, 0); # to propagate taintedness

    while ( @input ) {

        my $line = shift @input;
        my $sep = shift @input;

        # in strict mode encoded words must be always separated by spaces or tabs
        # except in comments when separator between words and comment round brackets can be omitted
        my $re_word_begin = $STRICT_DECODE ? qr/(?:[ \t\n]|\A)\(?/ : qr//;
        my $re_word_sep = $STRICT_DECODE ? qr/[ \t]+/ : qr/\s*/;
        my $re_word_end = $STRICT_DECODE ? qr/\)?(?:[ \t\n]|\z)/ : qr//;

        # concat consecutive encoded mime words with same charset, language and encoding
        # fixes breaking inside multi-byte characters
        1 while $line =~ s/($re_word_begin)$re_capture_encoded_word$re_word_sep=\?\2\3\?\4\?($re_encoded_text)\?=(?=$re_word_end)/$1=\?$2$3\?$4\?$5$6\?=/;

        $line =~ s{($re_word_begin)((?:$re_encoded_word$re_word_sep)*$re_encoded_word)(?=$re_word_end)}{
            my $begin = $1;
            my $words = $2;
            $words =~ s{$re_capture_encoded_word$re_word_sep?}{
                if (uc($3) eq 'B') {
                    $obj->{decode_b} or croak qq(MIME "B" unsupported);
                    decode_b($1, $4, $chk);
                } elsif (uc($3) eq 'Q') {
                    $obj->{decode_q} or croak qq(MIME "Q" unsupported);
                    decode_q($1, $4, $chk);
                } else {
                    croak qq(MIME "$3" encoding is nonexistent!);
                }
            }eg;
            $begin . $words;
        }eg;

        $output .= $line;
        $output .= $sep if defined $sep;

    }

    $_[1] = '' if $chk; # empty the input string in the stack so perlio is ok
    return $output;
}

sub decode_b {
    my ( $enc, $b, $chk ) = @_;
    my $d = find_encoding($enc) or croak qq(Unknown encoding "$enc");
    # MIME::Base64::decode_base64 ignores everything after a '=' padding character
    # split string after each sequence of padding characters and decode each substring
    my $db64 = join('', map { decode_base64($_) } split /(?<==)(?=[^=])/, $b);
    return $d->name eq 'utf8'
      ? Encode::decode_utf8($db64)
      : $d->decode( $db64, $chk || Encode::FB_PERLQQ );
}

sub decode_q {
    my ( $enc, $q, $chk ) = @_;
    my $d = find_encoding($enc) or croak qq(Unknown encoding "$enc");
    $q =~ s/_/ /go;
    $q =~ s/=([0-9A-Fa-f]{2})/pack("C", hex($1))/ego;
    return $d->name eq 'utf8'
      ? Encode::decode_utf8($q)
      : $d->decode( $q, $chk || Encode::FB_PERLQQ );
}

sub encode($$;$) {
    my ( $obj, $str, $chk ) = @_;
    $_[1] = '' if $chk; # empty the input string in the stack so perlio is ok
    return $obj->_fold_line($obj->_encode_line($str));
}

sub _fold_line {
    my ( $obj, $line ) = @_;
    my $bpl = $obj->{bpl};
    my $output = substr($line, 0, 0); # to propagate taintedness

    while ( length $line ) {
        if ( $line =~ s/^(.{0,$bpl})(\s|\z)// ) {
            $output .= $1;
            $output .= "\r\n" . $2 if length $line;
        } elsif ( $line =~ s/(\s)(.*)$// ) {
            $output .= $line;
            $line = $2;
            $output .= "\r\n" . $1 if length $line;
        } else {
            $output .= $line;
            last;
        }
    }

    return $output;
}

use constant HEAD   => '=?UTF-8?';
use constant TAIL   => '?=';
use constant SINGLE => { B => \&_encode_b, Q => \&_encode_q, B_len => \&_encode_b_len, Q_len => \&_encode_q_len };

sub _encode_line {
    my ( $o, $str ) = @_;
    my $enc  = $o->{encode};
    my $enc_len = $enc . '_len';
    my $llen = ( $o->{bpl} - length(HEAD) - 2 - length(TAIL) );

    my @result = ();
    my $chunk  = '';
    while ( length( my $chr = substr( $str, 0, 1, '' ) ) ) {
        if ( SINGLE->{$enc_len}($chunk . $chr) > $llen ) {
            push @result, SINGLE->{$enc}($chunk);
            $chunk = '';
        }
        $chunk .= $chr;
    }
    length($chunk) and push @result, SINGLE->{$enc}($chunk);
    return join(' ', @result);
}

sub _encode_b {
    HEAD . 'B?' . encode_base64( encode_utf8(shift), '' ) . TAIL;
}

sub _encode_b_len {
    my ( $chunk ) = @_;
    use bytes ();
    return bytes::length($chunk) * 4 / 3;
}

my $valid_q_chars = '0-9A-Za-z !*+\-/';

sub _encode_q {
    my ( $chunk ) = @_;
    $chunk = encode_utf8($chunk);
    $chunk =~ s{([^$valid_q_chars])}{
        join("" => map {sprintf "=%02X", $_} unpack("C*", $1))
    }egox;
    $chunk =~ s/ /_/go;
    return HEAD . 'Q?' . $chunk . TAIL;
}

sub _encode_q_len {
    my ( $chunk ) = @_;
    use bytes ();
    my $valid_count =()= $chunk =~ /[$valid_q_chars]/sgo;
    return ( bytes::length($chunk) - $valid_count ) * 3 + $valid_count;
}

1;
__END__

=head1 NAME

Encode::MIME::Header -- MIME 'B' and 'Q' encoding for unstructured header

=head1 SYNOPSIS

    use Encode qw/encode decode/;
    $utf8   = decode('MIME-Header', $header);
    $header = encode('MIME-Header', $utf8);

=head1 ABSTRACT

This module implements RFC 2047 MIME encoding for unstructured header.
It cannot be used for structured headers like From or To.  There are 3
variant encoding names; C<MIME-Header>, C<MIME-B> and C<MIME-Q>.  The
difference is described below

              decode()          encode()
  ----------------------------------------------
  MIME-Header Both B and Q      =?UTF-8?B?....?=
  MIME-B      B only; Q croaks  =?UTF-8?B?....?=
  MIME-Q      Q only; B croaks  =?UTF-8?Q?....?=

=head1 DESCRIPTION

When you decode(=?I<encoding>?I<X>?I<ENCODED WORD>?=), I<ENCODED WORD>
is extracted and decoded for I<X> encoding (B for Base64, Q for
Quoted-Printable). Then the decoded chunk is fed to
decode(I<encoding>).  So long as I<encoding> is supported by Encode,
any source encoding is fine.

When you encode, it just encodes UTF-8 string with I<X> encoding then
quoted with =?UTF-8?I<X>?....?= .  The parts that RFC 2047 forbids to
encode are left as is and long lines are folded within 76 bytes per
line.

=head1 BUGS

Before version 2.83 this module had broken both decoder and encoder.
Encoder inserted additional spaces, incorrectly encoded input data
and produced invalid MIME strings. Decoder lot of times discarded
white space characters, incorrectly interpreted data or decoded
Base64 string as Quoted-Printable.

As of version 2.83 encoder should be fully compliant of RFC 2047.
Due to bugs in previous versions of encoder, decoder is by default in
less strict compatible mode. It should be able to decode strings
encoded by pre 2.83 version of this module. But this default mode is
not correct according to RFC 2047.

In default mode decoder try to decode every substring which looks like
MIME encoded data. So it means that MIME data does not need to be
separated by white space. To enforce correct strict mode, set package
variable $Encode::MIME::Header::STRICT_DECODE to 1, e.g. by localizing:

C<require Encode::MIME::Header; local $Encode::MIME::Header::STRICT_DECODE = 1;>

It would be nice to support encoding to non-UTF8, such as =?ISO-2022-JP?
and =?ISO-8859-1?= but that makes the implementation too complicated.
These days major mail agents all support =?UTF-8? so I think it is
just good enough.

Due to popular demand, 'MIME-Header-ISO_2022_JP' was introduced by
Makamaka.  Thre are still too many MUAs especially cellular phone
handsets which does not grok UTF-8.

=head1 SEE ALSO

L<Encode>

RFC 2047, L<http://www.faqs.org/rfcs/rfc2047.html> and many other
locations.

=cut
