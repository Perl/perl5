package HTML::Parser;

# Copyright 1996-2001, Gisle Aas.
# Copyright 1999-2000, Michael A. Chase.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA);

$VERSION = '3.25';  # $Date: 2001/05/11 17:24:09 $

require HTML::Entities;

require DynaLoader;
@ISA=qw(DynaLoader);
HTML::Parser->bootstrap($VERSION);


sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    return $self->init(@_);
}


sub init
{
    my $self = shift;
    $self->_alloc_pstate;

    my %arg = @_;
    my $api_version = delete $arg{api_version} || (@_ ? 3 : 2);
    if ($api_version >= 4) {
	require Carp;
	Carp::croak("API version $api_version not supported " .
		    "by HTML::Parser $VERSION");
    }

    if ($api_version < 3) {
	# Set up method callbacks compatible with HTML-Parser-2.xx
	$self->handler(text    => "text",    "self,text,is_cdata");
	$self->handler(end     => "end",     "self,tagname,text");
	$self->handler(process => "process", "self,token0,text");
	$self->handler(start   => "start",
		                  "self,tagname,attr,attrseq,text");

	$self->handler(comment =>
		       sub {
			   my($self, $tokens) = @_;
			   for (@$tokens) {
			       $self->comment($_);
			   }
		       }, "self,tokens");

	$self->handler(declaration =>
		       sub {
			   my $self = shift;
			   $self->declaration(substr($_[0], 2, -1));
		       }, "self,text");
    }

    if (my $h = delete $arg{handlers}) {
	$h = {@$h} if ref($h) eq "ARRAY";
	while (my($event, $cb) = each %$h) {
	    $self->handler($event => @$cb);
	}
    }

    # In the end we try to assume plain attribute or handler
    while (my($option, $val) = each %arg) {
	if ($option =~ /^(\w+)_h$/) {
	    $self->handler($1 => @$val);
	}
        elsif ($option =~ /^(text|start|end|process|declaration|comment)$/) {
	    require Carp;
	    Carp::croak("Bad constructor option '$option'");
        }
	else {
	    $self->$option($val);
	}
    }

    return $self;
}


sub parse_file
{
    my($self, $file) = @_;
    my $opened;
    if (!ref($file) && ref(\$file) ne "GLOB") {
        # Assume $file is a filename
        local(*F);
        open(F, $file) || return undef;
	binmode(F);  # should we? good for byte counts
        $opened++;
        $file = *F;
    }
    my $chunk = '';
    while (read($file, $chunk, 512)) {
	$self->parse($chunk) || last;
    }
    close($file) if $opened;
    $self->eof;
}


sub netscape_buggy_comment  # legacy
{
    my $self = shift;
    require Carp;
    Carp::carp("netscape_buggy_comment() is deprecated.  " .
	       "Please use the strict_comment() method instead");
    my $old = !$self->strict_comment;
    $self->strict_comment(!shift) if @_;
    return $old;
}

# set up method stubs
sub text { }
*start       = \&text;
*end         = \&text;
*comment     = \&text;
*declaration = \&text;
*process     = \&text;

1;

__END__


=head1 NAME

HTML::Parser - HTML parser class

=head1 SYNOPSIS

 use HTML::Parser ();

 # Create parser object
 $p = HTML::Parser->new( api_version => 3,
                         start_h => [\&start, "tagname, attr"],
                         end_h   => [\&end,   "tagname"],
                         marked_sections => 1,
                       );

 # Parse document text chunk by chunk
 $p->parse($chunk1);
 $p->parse($chunk2);
 #...
 $p->eof;                 # signal end of document

 # Parse directly from file
 $p->parse_file("foo.html");
 # or
 open(F, "foo.html") || die;
 $p->parse_file(*F);

HTML::Parser version 2 style subclassing and method callbacks:

 {
    package MyParser;
    use base 'HTML::Parser';

    sub start {
       my($self, $tagname, $attr, $attrseq, $origtext) = @_;
       #...
    }

    sub end {
	my($self, $tagname, $origtext) = @_;
	#...
    }

    sub text {
	my($self, $origtext, $is_cdata) = @_;
	#...
    }
 }

 my $p = MyParser->new;
 $p->parse_file("foo.html");

=head1 DESCRIPTION

Objects of the C<HTML::Parser> class will recognize markup and
separate it from plain text (alias data content) in HTML
documents.  As different kinds of markup and text are recognized, the
corresponding event handlers are invoked.

C<HTML::Parser> in not a generic SGML parser.  We have tried to
make it able to deal with the HTML that is actually "out there", and
it normally parses as closely as possible to the way the popular web
browsers do it instead of strictly following one of the many HTML
specifications from W3C.  Where there is disagreement there is often
an option that you can enable to get the official behaviour.

The document to be parsed may be supplied in arbitrary chunks.  This
makes on-the-fly parsing as documents are received from the network
possible.

If event driven parsing does not feel right for your application, you
might want to use C<HTML::PullParser>.  It is a
C<HTML::Parser> subclass that allows a more conventional program
structure.


=head1 METHODS

The following method is used to construct a new C<HTML::Parser> object:

=over

=item $p = HTML::Parser->new( %options_and_handlers )

This class method creates a new C<HTML::Parser> object and
returns it.  Key/value pair arguments may be provided to assign event
handlers or initialize parser options.  The handlers and parser
options can also be set or modified later by method calls described below.

If a top level key is in the form "<event>_h" (e.g., "text_h"} then it
assigns a handler to that event, otherwise it initializes a parser
option. The event handler specification value must be an array
reference.  Multiple handlers may also be assigned with the 'handlers
=> [%handlers]' option.  See examples below.

If new() is called without any arguments, it will create a parser that
uses callback methods compatible with version 2 of C<HTML::Parser>.
See the section on "version 2 compatibility" below for details.

Special constructor option 'api_version => 2' can be used to
initialize version 2 callbacks while still setting other options and
handlers.  The 'api_version => 3' option can be used if you don't want
to set any options and don't want to fall back to v2 compatible
mode.

Examples:

 $p = HTML::Parser->new(api_version => 3,
                        text_h => [ sub {...}, "dtext" ]);

This creates a new parser object with a text event handler subroutine
that receives the original text with general entities decoded.

 $p = HTML::Parser->new(api_version => 3,
			start_h => [ 'my_start', "self,tokens" ]);

This creates a new parser object with a start event handler method
that receives the $p and the tokens array.

 $p = HTML::Parser->new(api_version => 3,
		        handlers => { text => [\@array, "event,text"],
                                      comment => [\@array, "event,text"],
                                    });

This creates a new parser object that stores the event type and the
original text in @array for text and comment events.

=back

The following methods feed the HTML document
to the C<HTML::Parser> object:

=over

=item $p->parse( $string )

Parse $string as the next chunk of the HTML document.  The return
value is normally a reference to the parser object (i.e. $p).
Handlers invoked should not attempt modify the $string in-place until
$p->parse returns.

If an invoked event handler aborts parsing by calling $p->eof, then
$p->parse() will return a FALSE value.

=item $p->parse( $code_ref )

If a code reference is passed in as the argument to parse then the
chunks to parse is obtained by invoking this function repeatedly.
Parsing continues until the function returns an empty (or undefined)
result.  When this happens $p->eof is automatically signalled.

Parsing will also abort if one of the event handlers call $p->eof.

The effect of this is the same as:

 while (1) {
    my $chunk = &$code_ref();
    if (!defined($chunk) || !length($chunk)) {
        $p->eof;
        return $p;
    }
    $p->parse($chunk) || return undef;
 }

But it is more efficient as this loop runs internally in XS code.

=item $p->parse_file( $file )

Parse text directly from a file.  The $file argument can be a
filename, an open file handle, or a reference to a an open file
handle.

If $file contains a filename and the file can't be opened, then the
method returns an undefined value and $! tells why it failed.
Otherwise the return value is a reference to the parser object.

If a file handle is passed as the $file argument, then the file will
normally be read until EOF, but not closed.

If an invoked event handler aborts parsing by calling $p->eof,
then $p->parse_file() may not have read the entire file.

On systems with multi-byte line terminators, the values passed for the
offset and length argspecs may be too low if parse_file() is called on
a file handle that is not in binary mode.

If a filename is passed in, then parse_file() will open the file in
binary mode.

=item $p->eof

Signals the end of the HTML document.  Calling the $p->eof method
outside a handler callback will flush any remaining buffered text
(which triggers the C<text> event if there is any remaining text).

Calling $p->eof inside a handler will terminate parsing at that point
and cause $p->parse to return a FALSE value.  This also terminates
parsing by $p->parse_file().

After $p->eof has been called, the parse() and parse_file() methods
can be invoked to feed new documents with the parser object.

The return value from eof() is a reference to the parser object.

=back


Most parser options are controlled by boolean attributes.
Each boolean attribute is enabled by calling the corresponding method
with a TRUE argument and disabled with a FALSE argument.  The
attribute value is left unchanged if no argument is given.  The return
value from each method is the old attribute value.

Methods that can be used to get and/or set parser options are:

=over

=item $p->strict_comment( [$bool] )

By default, comments are terminated by the first occurrence of "-->".
This is the behaviour of most popular browsers (like Netscape and
MSIE), but it is not correct according to the official HTML
standard.  Officially, you need an even number of "--" tokens before
the closing ">" is recognized and there may not be anything but
whitespace between an even and an odd "--".

The official behaviour is enabled by enabling this attribute.

=item $p->strict_names( [$bool] )

By default, almost anything is allowed in tag and attribute names.
This is the behaviour of most popular browsers and allows us to parse
some broken tags with invalid attr values like:

   <IMG SRC=newprevlstGr.gif ALT=[PREV LIST] BORDER=0>

By default, "LIST]" is parsed as a boolean attribute, not as
part of the ALT value as was clearly intended.  This is also what
Netscape sees.

The official behaviour is enabled by enabling this attribute.  If
enabled, it will cause the tag above to be reported as text
since "LIST]" is not a legal attribute name.

=item $p->boolean_attribute_value( $val )

This method sets the value reported for boolean attributes inside HTML
start tags.  By default, the name of the attribute is also used as its
value.  This affects the values reported for C<tokens> and C<attr>
argspecs.

=item $p->xml_mode( [$bool] )

Enabling this attribute changes the parser to allow some XML
constructs such as I<empty element tags> and I<XML processing
instructions>.  It disables forcing tag and attribute names to lower
case when they are reported by the C<tagname> and C<attr> argspecs,
and suppress special treatment of elements that are parsed as CDATA
for HTML.

I<Empty element tags> look like start tags, but end with the character
sequence "/>".  When recognized by C<HTML::Parser> they cause an
artificial end event in addition to the start event.  The C<text> for
the artificial end event will be empty and the C<tokenpos> array will
be undefined even though the only element in the token array will have
the correct tag name.

I<XML processing instructions> are terminated by "?>" instead of a
simple ">" as is the case for HTML.

=item $p->unbroken_text( [$bool] )

By default, blocks of text are given to the text handler as soon as
possible (but the parser makes sure to always break text at the
boundary between whitespace and non-whitespace so single words and
entities always can be decoded safely).  This might create breaks that
make it hard to do transformations on the text. When this attribute is
enabled, blocks of text are always reported in one piece.  This will
delay the text event until the following (non-text) event has been
recognized by the parser.

Note that the C<offset> argspec will give you the offset of the first
segment of text and C<length> is the combined length of the segments.
Since there might be ignored tags in between, these numbers can't be
used to directly index in the original document file.

=item $p->marked_sections( [$bool] )

By default, section markings like <![CDATA[...]]> are treated like
ordinary text.  When this attribute is enabled section markings are
honoured.

There are currently no events associated with the marked section
markup, but the text can be returned as C<skipped_text>.

=back

As markup and text is recognized, handlers are invoked.  The following
method is used to set up handlers for different events:

=over

=item $p->handler( event => \&subroutine, argspec )

=item $p->handler( event => method_name, argspec )

=item $p->handler( event => \@accum, argspec )

=item $p->handler( event => "" );

=item $p->handler( event => undef );

=item $p->handler( event );

This method assigns a subroutine, method, or array to handle an event.

Event is one of C<text>, C<start>, C<end>, C<declaration>, C<comment>,
C<process>, C<start_document>, C<end_document> or C<default>.

I<Subroutine> is a reference to a subroutine which is called to handle
the event.

I<Method_name> is the name of a method of $p which is called to handle
the event.

I<Accum> is a array that will hold the event information as
sub-arrays.

If the second argument is "", the event is ignored.
If it is undef, the default handler is invoked for the event.

I<Argspec> is a string that describes the information to be reported
for the event.  Any requested information that does not apply to a
specific event is passed as C<undef>.  If argspec is omitted, then it
is left unchanged since last update.

The return value from $p->handle is the old callback routine or a
reference to the accumulator array.

Any return values from handler callback routines/methods are always
ignored.  A handler callback can request parsing to be aborted by
invoking the $p->eof method.  A handler callback is not allowed to
invoke the $p->parse() or $p->parse_file() method.  An exception will
be raised if it tries.

Examples:

    $p->handler(start =>  "start", 'self, attr, attrseq, text' );

This causes the "start" method of object $p to be called for 'start' events.
The callback signature is $p->start(\%attr, \@attr_seq, $text).

    $p->handler(start =>  \&start, 'attr, attrseq, text' );

This causes subroutine start() to be called for 'start' events.
The callback signature is start(\%attr, \@attr_seq, $text).

    $p->handler(start =>  \@accum, '"S", attr, attrseq, text' );

This causes 'start' event information to be saved in @accum.
The array elements will be ['S', \%attr, \@attr_seq, $text].

   $p->handler(start => "");

This causes 'start' events to be ignored.  It also supresses
invokations of any default handler for start events.  It is in most
cases equivalent to $p->handler(start => sub {}), but is more
efficient.  It is different from the empty-sub-handler in that
C<skipped_text> is not reset by it.

   $p->handler(start => undef);

This causes no handler to be assosiated with start events.
If there is a default handler it will be invoked.

=back

Filters based on tags can be set up to limit the number of events
reported.  The main bottleneck during parsing is often the huge number
of callbacks made from the parser.  Applying filters can improve
performance significantly.

The following methods control filters:

=over

=item $p->ignore_tags( TAG, ... )

Any C<start> and C<end> events involving any of the tags given are
suppressed.

=item $p->report_tags( TAG, ... )

Any C<start> and C<end> events involving any of the tags I<not> given
are suppressed.

=item $p->ignore_elements( TAG, ... )

Both the C<start> and the C<end> event as well as any events that
would be reported in between are suppressed.  The ignored elements can
contain nested occurences of itself.  Example:

   $p->ignore_elements(qw(script style));

The C<script> and C<style> tags will always nest properly since their
content is parsed in CDATA mode.  For most other tags
C<ignore_elements> must be used with caution since HTML is often not
I<well formed>.

=back

=head2 Argspec

Argspec is a string containing a comma separated list that describes
the information reported by the event.  The following argspec
identifier names can be used:

=over

=item C<self>

Self causes the current object to be passed to the handler.  If the
handler is a method, this must be the first element in the argspec.

An alternative to passing self as an argspec is to register closures
that capture $self by themselves as handlers.  Unfortunately this
creates a circular references which prevents the HTML::Parser object
from being garbage collected.  Using the C<self> argspec avoids this
problem.

=item C<tokens>

Tokens causes a reference to an array of token strings to be passed.
The strings are exactly as they were found in the original text,
no decoding or case changes are applied.

For C<declaration> events, the array contains each word, comment, and
delimited string starting with the declaration type.

For C<comment> events, this contains each sub-comment.  If
$p->strict_comments is disabled, there will be only one sub-comment.

For C<start> events, this contains the original tag name followed by
the attribute name/value pairs.  The value of boolean attributes will
be either the value set by $p->boolean_attribute_value or the
attribute name if no value has been set by
$p->boolean_attribute_value.

For C<end> events, this contains the original tag name (always one token).

For C<process> events, this contains the process instructions (always one
token).

This passes C<undef> for C<text> events.

=item C<tokenpos>

Tokenpos causes a reference to an array of token positions to be
passed.  For each string that appears in C<tokens>, this array
contains two numbers.  The first number is the offset of the start of
the token in the original C<text> and the second number is the length
of the token.

Boolean attributes in a C<start> event will have (0,0) for the
attribute value offset and length.

This passes undef if there are no tokens in the event (e.g., C<text>)
and for artifical C<end> events triggered by empty element tags.

If you are using these offsets and lengths to modify C<text>, you
should either work from right to left, or be very careful to calculate
the changes to the offsets.

=item C<token0>

Token0 causes the original text of the first token string to be
passed.  This should always be the same as $tokens->[0].

For C<declaration> events, this is the declaration type.

For C<start> and C<end> events, this is the tag name.

For C<process> and non-strict C<comment> events, this is everything
inside the tag.

This passes undef if there are no tokens in the event.

=item C<tagname>

This is the element name (or I<generic identifier> in SGML jargon) for
start and end tags.  Since HTML is case insensitive this name is
forced to lower case to ease string matching.

Since XML is case sensitive, the tagname case is not
changed when C<xml_mode> is enabled.

The declaration type of declaration elements is also passed as a tagname,
even if that is a bit strange.
In fact, in the current implementation tagname is
identical to C<token0> except that the name may be forced to lower case.

=item C<tag>

Same as C<tagname>, but prefixed with "/" if it belongs to an C<end>
event and "!" for a declaration.  The C<tag> does not have any prefix
for C<start> events, and is in this case identical to C<tagname>.

=item C<attr>

Attr causes a reference to a hash of attribute name/value pairs to be
passed.

Boolean attributes' values are either the value set by
$p->boolean_attribute_value or the attribute name if no value has been
set by $p->boolean_attribute_value.

This passes undef except for C<start> events.

Unless C<xml_mode> is enabled, the attribute names are forced to
lower case.

General entities are decoded in the attribute values and
one layer of matching quotes enclosing the attribute values are removed.

=item C<attrseq>

Attrseq causes a reference to an array of attribute names to be
passed.  This can be useful if you want to walk the C<attr> hash in
the original sequence.

This passes undef except for C<start> events.

Unless C<xml_mode> is enabled, the attribute names are forced to lower
case.

=item C<@attr>

Basically same as C<attr>, but keys and values are passed as
individual arguments and the original sequence of the attributes is
kept.  The parameters passed will be the same as the @attr calculated
here:

   @attr = map { $_ => $attr->{$_} } @$attrseq;

assuming $attr and $attrseq here are the hash and array passed as the
result of C<attr> and C<attrseq> argspecs.

This pass no values for events besides C<start>.

=item C<text>

Text causes the source text (including markup element delimiters) to be
passed.

=item C<dtext>

Dtext causes the decoded text to be passed.  General entities are
automatically decoded unless the event was inside a CDATA section or
was between literal start and end tags (C<script>, C<style>, C<xmp>,
and C<plaintext>).

The Unicode character set is assumed for entity decoding.  With perl
version < 5.7.1 only the Latin1 range is supported, and entities for
characters outside the 0..255 range is left unchanged.

This passes undef except for C<text> events.

=item C<is_cdata>

Is_cdata causes a TRUE value to be passed if the event is inside a CDATA
section or is between literal start and end tags (C<script>,
C<style>, C<xmp>, and C<plaintext>).

When the flag is FALSE for a text event, then you should normally
either use C<dtext> or decode the entities yourself before the text is
processed further.

=item C<skipped_text>

Skipped_text returns the concatenated text of all the events that has
been skipped since the last time an event was reported.  Events might
be skipped because no handler is registered for them or because some
filter applies.  Skipped text also include marked section markup,
since there is no events that can catch them.

If an C<"">-handler is registered for an event, then the text for this
event is not included in C<skipped_text>.  Skipped text both before
and after the C<"">-event is included in the next reported
C<skipped_text>.

=item C<offset>

Offset causes the byte position in the HTML document of the start of
the event to be passed.  The first byte in the document is 0.

=item C<length>

Length causes the number of bytes of the source text of the event to
be passed.

=item C<offset_end>

Offset_end causes the byte position in the HTML document of the end of
the event to be passed.  This is the same as C<offset> + C<length>.

=item C<event>

Event causes the event name to be passed.

The event name is one of C<text>, C<start>, C<end>, C<declaration>,
C<comment>, C<process>, C<start_document>, C<end_document> or C<default>.

=item C<line>

Line causes the line number of the start of the event to be passed.
The first line in the document is 1.  Line counting doesn't start
until at least one handler requests this value to be reported.

=item C<column>

Column causes the column number of the start of the event to be passed.
The first column on a line is 0.

=item C<'...'>

A literal string of 0 to 255 characters enclosed
in single (') or double (") quotes is passed as entered.

=item C<undef>

Pass an undefined value.  Useful as padding where the same handler
routine is registered for multiple events.

=back

The whole argspec string can be wrapped up in C<'@{...}'> to signal
that resulting event array should be flatten.  This only makes a
difference if an array reference is used as the handler target.
Consider this example:

   $p->handler(text => [], 'text');
   $p->handler(text => [], '@{text}']);

With two text events; C<"foo">, C<"bar">; then the first one will end
up with [["foo"], ["bar"]] and the second one with ["foo", "bar"] in
the handler target array.


=head2 Events

Handlers for the following events can be registered:

=over

=item C<text>

This event is triggered when plain text (characters) is recognized.
The text may contain multiple lines.  A sequence of text may be broken
between several text events unless $p->unbroken_text is enabled.

The parser will make sure that it does not break a word or a sequence
of whitespace between two text events.

=item C<start>

This event is triggered when a start tag is recognized.

Example:

  <A HREF="http://www.perl.com/">

=item C<end>

This event is triggered when an end tag is recognized.

Example:

  </A>

=item C<declaration>

This event is triggered when a I<markup declaration> is recognized.

For typical HTML documents, the only declaration you are
likely to find is <!DOCTYPE ...>.

Example:

  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html40/strict.dtd">

DTDs inside <!DOCTYPE ...> will confuse HTML::Parser.

=item C<comment>

This event is triggered when a markup comment is recognized.

Example:

  <!-- This is a comment -- -- So is this -->

=item C<process>

This event is triggered when a processing instructions markup is
recognized.

The format and content of processing instructions is system and
application dependent.

Examples:

  <? HTML processing instructions >
  <? XML processing instructions ?>

=item C<start_document>

This event is triggered before any other events for a new document.  A
handler for it can be used to initialize stuff.  There is no document
text associated with this event.

=item C<end_document>

This event is triggered when $p->eof called and after any remaining
text is flushed.  There is no document text associated with this event.

=item C<default>

This event is triggered for events that do not have a specific
handler.  You can set up a handler for this event to catch stuff you
did not want to catch explicitly.

=back

=head1 VERSION 2 COMPATIBILITY

When an C<HTML::Parser> object is constructed with no arguments, a set
of handlers is automatically provided that is compatible with the old
HTML::Parser version 2 callback methods.

This is equivalent to the following method calls:

   $p->handler(start   => "start",   "self, tagname, attr, attrseq, text");
   $p->handler(end     => "end",     "self, tagname, text");
   $p->handler(text    => "text",    "self, text, is_cdata");
   $p->handler(process => "process", "self, token0, text");
   $p->handler(comment =>
             sub {
		 my($self, $tokens) = @_;
		 for (@$tokens) {$self->comment($_);}},
             "self, tokens");
   $p->handler(declaration =>
             sub {
		 my $self = shift;
		 $self->declaration(substr($_[0], 2, -1));},
             "self, text");

Setup of these handlers can also be requested with the "api_version =>
2" constructor option.

=head1 SUBCLASSING

The C<HTML::Parser> class is subclassable.  Parser objects are plain
hashes and C<HTML::Parser> reserves only hash keys that start with
"_hparser".  The parser state can be set up by invoking the init()
method which takes the same arguments as new().

=head1 EXAMPLES

The first simple example shows how you might strip out comments from
an HTML document.  We achieve this by setting up a comment handler that
does nothing and a default handler that will print out anything else:

  use HTML::Parser;
  HTML::Parser->new(default_h => [sub { print shift }, 'text'],
                    comment_h => [""],
                   )->parse_file(shift || die) || die $!;

An alternative implementation is:

  use HTML::Parser;
  HTML::Parser->new(end_document_h => [sub { print shift },
                                       'skipped_text'],
                    comment_h      => [""],
                   )->parse_file(shift || die) || die $!;

This will in most cases be much more efficient since only a sigle
callback will be made.

The next example prints out the text that is inside the <title>
element of an HTML document.  Here we start by setting up a start
handler.  When it sees the title start tag it enables a text handler
that prints any text found and an end handler that will terminate
parsing as soon as the title end tag is seen:

  use HTML::Parser ();

  sub start_handler
  {
    return if shift ne "title";
    my $self = shift;
    $self->handler(text => sub { print shift }, "dtext");
    $self->handler(end  => sub { shift->eof if shift eq "title"; },
		           "tagname,self");
  }

  my $p = HTML::Parser->new(api_version => 3);
  $p->handler( start => \&start_handler, "tagname,self");
  $p->parse_file(shift || die) || die $!;
  print "\n";

More examples are found in the "eg/" directory of the C<HTML-Parser>
distribution; the program C<hrefsub> shows how you can edit all links
found in a document and C<htextsub> how to edid the text only; the
program C<hstrip> shows how you can strip out certain tags/elements
and/or attributes; and the program C<htext> show how to obtain the
plain text, but not any script/style content.

=head1 BUGS

The <style> and <script> sections do not end with the first "</", but
need the complete corresponding end tag.

When the I<strict_comment> option is enabled, we still recognize
comments where there is something other than whitespace between even
and odd "--" markers.

Once $p->boolean_attribute_value has been set, there is no way to
restore the default behaviour.

There is currently no way to get both quote characters
into the same literal argspec.

Empty tags, e.g. "<>" and "</>", are not recognized.  SGML allows them
to repeat the previous start tag or close the previous start tag
respecitvely.

NET tags, e.g. "code/.../" are not recognized.  This is an SGML
shorthand for "<code>...</code>".

Unclosed start or end tags, e.g. "<tt<b>...</b</tt>" are not
recognized.

=head1 DIAGNOSTICS

The following messages may be produced by HTML::Parser.  The notation
in this listing is the same as used in L<perldiag>:

=over

=item Not a reference to a hash

(F) The object blessed into or subclassed from HTML::Parser is not a
hash as required by the HTML::Parser methods.

=item Bad signature in parser state object at %p

(F) The _hparser_xs_state element does not refer to a valid state structure.
Something must have changed the internal value
stored in this hash element, or the memory has been overwritten.

=item _hparser_xs_state element is not a reference

(F) The _hparser_xs_state element has been destroyed.

=item Can't find '_hparser_xs_state' element in HTML::Parser hash

(F) The _hparser_xs_state element is missing from the parser hash.
It was either deleted, or not created when the object was created.

=item API version %s not supported by HTML::Parser %s

(F) The constructor option 'api_version' with an argument greater than
or equal to 4 is reserved for future extentions.

=item Bad constructor option '%s'

(F) An unknown constructor option key was passed to the new() or
init() methods.

=item Parse loop not allowed

(F) A handler invoked the parse() or parse_file() method.
This is not permitted.

=item marked sections not supported

(F) The $p->marked_sections() method was invoked in a HTML::Parser
module that was compiled without support for marked sections.

=item Unknown boolean attribute (%d)

(F) Something is wrong with the internal logic that set up aliases for
boolean attributes.

=item Only code or array references allowed as handler

(F) The second argument for $p->handler must be either a subroutine
reference, then name of a subroutine or method, or a reference to an
array.

=item No handler for %s events

(F) The first argument to $p->handler must be a valid event name; i.e. one
of "start", "end", "text", "process", "declaration" or "comment".

=item Unrecognized identifier %s in argspec

(F) The identifier is not a known argspec name.
Use one of the names mentioned in the argspec section above.

=item Literal string is longer than 255 chars in argspec

(F) The current implementation limits the length of literals in
an argspec to 255 characters.  Make the literal shorter.

=item Backslash reserved for literal string in argspec

(F) The backslash character "\" is not allowed in argspec literals.
It is reserved to permit quoting inside a literal in a later version.

=item Unterminated literal string in argspec

(F) The terminating quote character for a literal was not found.

=item Bad argspec (%s)

(F) Only identifier names, literals, spaces and commas
are allowed in argspecs.

=item Missing comma separator in argspec

(F) Identifiers in an argspec must be separated with ",".

=back

=head1 SEE ALSO

L<HTML::Entities>, L<HTML::PullParser>, L<HTML::TokeParser>, L<HTML::HeadParser>,
L<HTML::LinkExtor>, L<HTML::Form>

L<HTML::TreeBuilder> (part of the I<HTML-Tree> distribution)

http://www.w3.org/TR/REC-html40

More information about marked sections and processing instructions may
be found at C<http://www.sgml.u-net.com/book/sgml-8.htm>.

=head1 COPYRIGHT

 Copyright 1996-2001 Gisle Aas. All rights reserved.
 Copyright 1999-2000 Michael A. Chase.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
