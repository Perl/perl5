package HTML::TokeParser;

# $Id: TokeParser.pm,v 2.24 2001/03/26 07:32:17 gisle Exp $

require HTML::PullParser;
@ISA=qw(HTML::PullParser);
$VERSION = sprintf("%d.%02d", q$Revision: 2.24 $ =~ /(\d+)\.(\d+)/);

use strict;
use Carp ();
use HTML::Entities qw(decode_entities);

my %ARGS =
(
 start       => "'S',tagname,attr,attrseq,text",
 end         => "'E',tagname,text",
 text        => "'T',text,is_cdata",
 process     => "'PI',token0,text",
 comment     => "'C',text",
 declaration => "'D',text",
);


sub new
{
    my $class = shift;
    my %cnf;
    if (@_ == 1) {
	my $type = (ref($_[0]) eq "SCALAR") ? "doc" : "file";
	%cnf = ($type => $_[0]);
    }
    else {
	%cnf = @_;
    }

    my $textify = delete $cnf{textify} || {img => "alt", applet => "alt"};

    my $self = $class->SUPER::new(%cnf, %ARGS) || return undef;

    $self->{textify} = $textify;
    $self;
}


sub get_tag
{
    my $self = shift;
    my $token;
    while (1) {
	$token = $self->get_token || return undef;
	my $type = shift @$token;
	next unless $type eq "S" || $type eq "E";
	substr($token->[0], 0, 0) = "/" if $type eq "E";
	return $token unless @_;
	for (@_) {
	    return $token if $token->[0] eq $_;
	}
    }
}


sub get_text
{
    my $self = shift;
    my $endat = shift;
    my @text;
    while (my $token = $self->get_token) {
	my $type = $token->[0];
	if ($type eq "T") {
	    my $text = $token->[1];
	    decode_entities($text) unless $token->[2];
	    push(@text, $text);
	} elsif ($type =~ /^[SE]$/) {
	    my $tag = $token->[1];
	    if ($type eq "S") {
		if (exists $self->{textify}{$tag}) {
		    my $alt = $self->{textify}{$tag};
		    my $text;
		    if (ref($alt)) {
			$text = &$alt(@$token);
		    } else {
			$text = $token->[2]{$alt || "alt"};
			$text = "[\U$tag]" unless defined $text;
		    }
		    push(@text, $text);
		    next;
		}
	    } else {
		$tag = "/$tag";
	    }
	    if (!defined($endat) || $endat eq $tag) {
		 $self->unget_token($token);
		 last;
	    }
	}
    }
    join("", @text);
}


sub get_trimmed_text
{
    my $self = shift;
    my $text = $self->get_text(@_);
    $text =~ s/^\s+//; $text =~ s/\s+$//; $text =~ s/\s+/ /g;
    $text;
}

1;


__END__

=head1 NAME

HTML::TokeParser - Alternative HTML::Parser interface

=head1 SYNOPSIS

 require HTML::TokeParser;
 $p = HTML::TokeParser->new("index.html") || die "Can't open: $!";
 while (my $token = $p->get_token) {
     #...
 }

=head1 DESCRIPTION

The C<HTML::TokeParser> is an alternative interface to the
C<HTML::Parser> class.  It is an C<HTML::PullParser> subclass.

The following methods are available:

=over 4

=item $p = HTML::TokeParser->new( $file_or_doc );

The object constructor argument is either a file name, a file handle
object, or the complete document to be parsed.

If the argument is a plain scalar, then it is taken as the name of a
file to be opened and parsed.  If the file can't be opened for
reading, then the constructor will return an undefined value and $!
will tell you why it failed.

If the argument is a reference to a plain scalar, then this scalar is
taken to be the literal document to parse.  The value of this
scalar should not be changed before all tokens have been extracted.

Otherwise the argument is taken to be some object that the
C<HTML::TokeParser> can read() from when it needs more data.  Typically
it will be a filehandle of some kind.  The stream will be read() until
EOF, but not closed.

=item $p->get_token

This method will return the next I<token> found in the HTML document,
or C<undef> at the end of the document.  The token is returned as an
array reference.  The first element of the array will be a (mostly)
single character string denoting the type of this token: "S" for start
tag, "E" for end tag, "T" for text, "C" for comment, "D" for
declaration, and "PI" for process instructions.  The rest of the array
is the same as the arguments passed to the corresponding HTML::Parser
v2 compatible callbacks (see L<HTML::Parser>).  In summary, returned
tokens look like this:

  ["S",  $tag, $attr, $attrseq, $text]
  ["E",  $tag, $text]
  ["T",  $text, $is_data]
  ["C",  $text]
  ["D",  $text]
  ["PI", $token0, $text]

where $attr is a hash reference, $attrseq is an array reference and
the rest is plain scalars.

=item $p->unget_token($token,...)

If you find out you have read too many tokens you can push them back,
so that they are returned the next time $p->get_token is called.

=item $p->get_tag( [$tag, ...] )

This method returns the next start or end tag (skipping any other
tokens), or C<undef> if there are no more tags in the document.  If
one or more arguments are given, then we skip tokens until one of the
specified tag types is found.  For example:

   $p->get_tag("font", "/font");

will find the next start or end tag for a font-element.

The tag information is returned as an array reference in the same form
as for $p->get_token above, but the type code (first element) is
missing. A start tag will be returned like this:

  [$tag, $attr, $attrseq, $text]

The tagname of end tags are prefixed with "/", i.e. end tag is
returned like this:

  ["/$tag", $text]

=item $p->get_text( [$endtag] )

This method returns all text found at the current position. It will
return a zero length string if the next token is not text.  The
optional $endtag argument specifies that any text occurring before the
given tag is to be returned.  Any entities will be converted to their
corresponding character.

The $p->{textify} attribute is a hash that defines how certain tags can
be treated as text.  If the name of a start tag matches a key in this
hash then this tag is converted to text.  The hash value is used to
specify which tag attribute to obtain the text from.  If this tag
attribute is missing, then the upper case name of the tag enclosed in
brackets is returned, e.g. "[IMG]".  The hash value can also be a
subroutine reference.  In this case the routine is called with the
start tag token content as its argument and the return value is treated
as the text.

The default $p->{textify} value is:

  {img => "alt", applet => "alt"}

This means that <IMG> and <APPLET> tags are treated as text, and that
the text to substitute can be found in the ALT attribute.

=item $p->get_trimmed_text( [$endtag] )

Same as $p->get_text above, but will collapse any sequences of white
space to a single space character.  Leading and trailing white space is
removed.

=back

=head1 EXAMPLES

This example extracts all links from a document.  It will print one
line for each link, containing the URL and the textual description
between the <A>...</A> tags:

  use HTML::TokeParser;
  $p = HTML::TokeParser->new(shift||"index.html");

  while (my $token = $p->get_tag("a")) {
      my $url = $token->[1]{href} || "-";
      my $text = $p->get_trimmed_text("/a");
      print "$url\t$text\n";
  }

This example extract the <TITLE> from the document:

  use HTML::TokeParser;
  $p = HTML::TokeParser->new(shift||"index.html");
  if ($p->get_tag("title")) {
      my $title = $p->get_trimmed_text;
      print "Title: $title\n";
  }

=head1 SEE ALSO

L<HTML::PullParser>, L<HTML::Parser>

=head1 COPYRIGHT

Copyright 1998-2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
