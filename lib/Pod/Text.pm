# Pod::Text -- Convert POD data to formatted ASCII text.
# $Id: Text.pm,v 0.2 1999/06/13 02:44:01 eagle Exp $
#
# Copyright 1999 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# This module may potentially be a replacement for Pod::Text, although it
# does not (at the current time) attempt to match the output of Pod::Text
# and makes several different formatting choices (mostly in the direction of
# less markup).  It uses Pod::Parser and is designed to be very easy to
# subclass.

############################################################################
# Modules and declarations
############################################################################

package Pod::Text;

require 5.004;

use Carp qw(carp);
use Pod::Parser ();

use strict;
use vars qw(@ISA %ESCAPES $VERSION);

@ISA = qw(Pod::Parser);

$VERSION = '0.01';


############################################################################
# Table of supported E<> escapes
############################################################################

# This table is taken near verbatim from Pod::PlainText in Pod::Parser,
# which got it near verbatim from Pod::Text.  It is therefore credited to
# Tom Christiansen, and I'm glad I didn't have to write it.  :)
%ESCAPES = (
    'amp'       =>    '&',      # ampersand
    'lt'        =>    '<',      # left chevron, less-than
    'gt'        =>    '>',      # right chevron, greater-than
    'quot'      =>    '"',      # double quote
                                 
    "Aacute"    =>    "\xC1",   # capital A, acute accent
    "aacute"    =>    "\xE1",   # small a, acute accent
    "Acirc"     =>    "\xC2",   # capital A, circumflex accent
    "acirc"     =>    "\xE2",   # small a, circumflex accent
    "AElig"     =>    "\xC6",   # capital AE diphthong (ligature)
    "aelig"     =>    "\xE6",   # small ae diphthong (ligature)
    "Agrave"    =>    "\xC0",   # capital A, grave accent
    "agrave"    =>    "\xE0",   # small a, grave accent
    "Aring"     =>    "\xC5",   # capital A, ring
    "aring"     =>    "\xE5",   # small a, ring
    "Atilde"    =>    "\xC3",   # capital A, tilde
    "atilde"    =>    "\xE3",   # small a, tilde
    "Auml"      =>    "\xC4",   # capital A, dieresis or umlaut mark
    "auml"      =>    "\xE4",   # small a, dieresis or umlaut mark
    "Ccedil"    =>    "\xC7",   # capital C, cedilla
    "ccedil"    =>    "\xE7",   # small c, cedilla
    "Eacute"    =>    "\xC9",   # capital E, acute accent
    "eacute"    =>    "\xE9",   # small e, acute accent
    "Ecirc"     =>    "\xCA",   # capital E, circumflex accent
    "ecirc"     =>    "\xEA",   # small e, circumflex accent
    "Egrave"    =>    "\xC8",   # capital E, grave accent
    "egrave"    =>    "\xE8",   # small e, grave accent
    "ETH"       =>    "\xD0",   # capital Eth, Icelandic
    "eth"       =>    "\xF0",   # small eth, Icelandic
    "Euml"      =>    "\xCB",   # capital E, dieresis or umlaut mark
    "euml"      =>    "\xEB",   # small e, dieresis or umlaut mark
    "Iacute"    =>    "\xCD",   # capital I, acute accent
    "iacute"    =>    "\xED",   # small i, acute accent
    "Icirc"     =>    "\xCE",   # capital I, circumflex accent
    "icirc"     =>    "\xEE",   # small i, circumflex accent
    "Igrave"    =>    "\xCD",   # capital I, grave accent
    "igrave"    =>    "\xED",   # small i, grave accent
    "Iuml"      =>    "\xCF",   # capital I, dieresis or umlaut mark
    "iuml"      =>    "\xEF",   # small i, dieresis or umlaut mark
    "Ntilde"    =>    "\xD1",   # capital N, tilde
    "ntilde"    =>    "\xF1",   # small n, tilde
    "Oacute"    =>    "\xD3",   # capital O, acute accent
    "oacute"    =>    "\xF3",   # small o, acute accent
    "Ocirc"     =>    "\xD4",   # capital O, circumflex accent
    "ocirc"     =>    "\xF4",   # small o, circumflex accent
    "Ograve"    =>    "\xD2",   # capital O, grave accent
    "ograve"    =>    "\xF2",   # small o, grave accent
    "Oslash"    =>    "\xD8",   # capital O, slash
    "oslash"    =>    "\xF8",   # small o, slash
    "Otilde"    =>    "\xD5",   # capital O, tilde
    "otilde"    =>    "\xF5",   # small o, tilde
    "Ouml"      =>    "\xD6",   # capital O, dieresis or umlaut mark
    "ouml"      =>    "\xF6",   # small o, dieresis or umlaut mark
    "szlig"     =>    "\xDF",   # small sharp s, German (sz ligature)
    "THORN"     =>    "\xDE",   # capital THORN, Icelandic
    "thorn"     =>    "\xFE",   # small thorn, Icelandic
    "Uacute"    =>    "\xDA",   # capital U, acute accent
    "uacute"    =>    "\xFA",   # small u, acute accent
    "Ucirc"     =>    "\xDB",   # capital U, circumflex accent
    "ucirc"     =>    "\xFB",   # small u, circumflex accent
    "Ugrave"    =>    "\xD9",   # capital U, grave accent
    "ugrave"    =>    "\xF9",   # small u, grave accent
    "Uuml"      =>    "\xDC",   # capital U, dieresis or umlaut mark
    "uuml"      =>    "\xFC",   # small u, dieresis or umlaut mark
    "Yacute"    =>    "\xDD",   # capital Y, acute accent
    "yacute"    =>    "\xFD",   # small y, acute accent
    "yuml"      =>    "\xFF",   # small y, dieresis or umlaut mark
                                  
    "lchevron"  =>    "\xAB",   # left chevron (double less than)
    "rchevron"  =>    "\xBB",   # right chevron (double greater than)
);


############################################################################
# Initialization
############################################################################

# Initialize the object.  Must be sure to call our parent initializer.
sub initialize {
    my $self = shift;

    $$self{alt}      = 0  unless defined $$self{alt};
    $$self{indent}   = 4  unless defined $$self{indent};
    $$self{loose}    = 0  unless defined $$self{loose};
    $$self{sentence} = 0  unless defined $$self{sentence};
    $$self{width}    = 76 unless defined $$self{width};

    $$self{BEGUN}    = [];              # Stack of =begin blocks.
    $$self{INDENTS}  = [];              # Stack of indentations.
    $$self{MARGIN}   = $$self{indent};  # Current left margin in spaces.

    $self->SUPER::initialize;
}


############################################################################
# Core overrides
############################################################################

# Called for each command paragraph.  Gets the command, the associated
# paragraph, the line number, and a Pod::Paragraph object.  Just dispatches
# the command to a method named the same as the command.  =cut is handled
# internally by Pod::Parser.
sub command {
    my $self = shift;
    my $command = shift;
    return if $command eq 'pod';
    return if ($$self{EXCLUDE} && $command ne 'end');
    $self->item ("\n") if defined $$self{ITEM};
    $command = 'cmd_' . $command;
    $self->$command (@_);
}

# Called for a verbatim paragraph.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Just output it verbatim, but with tabs converted
# to spaces.
sub verbatim {
    my $self = shift;
    return if $$self{EXCLUDE};
    $self->item if defined $$self{ITEM};
    local $_ = shift;
    return if /^\s*$/;
    s/^(\s*\S+)/(' ' x $$self{MARGIN}) . $1/gme;
    $self->output ($_);
}

# Called for a regular text block.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Perform interpolation and output the results.
sub textblock {
    my ($self, $text, $line) = @_;
    return if $$self{EXCLUDE};
    local $_ = $text;

    # Perform a little magic to collapse multiple L<> references.  This is
    # here mostly for backwards-compatibility with Pod::Text.  We'll just
    # rewrite the whole thing into actual text at this part, bypassing the
    # whole internal sequence parsing thing.
    s{
        (
          L<                    # A link of the form L</something>.
              /
              (
                  [:\w]+        # The item has to be a simple word...
                  (\(\))?       # ...or simple function.
              )
          >
          (
              ,?\s+(and\s+)?    # Allow lots of them, conjuncted.
              L<  
                  /
                  (
                      [:\w]+
                      (\(\))?
                  )
              >
          )+
        )
    } {
        local $_ = $1;
        s%L</([^>]+)>%$1%g;
        my @items = split /(?:,?\s+(?:and\s+)?)/;
        my $string = "the ";
        my $i;
        for ($i = 0; $i < @items; $i++) {
            $string .= $items[$i];
            $string .= ", " if @items > 2 && $i != $#items;
            $string .= " and " if ($i == $#items - 1);
        }
        $string .= " entries elsewhere in this document";
        $string;
    }gex;

    # Now actually interpolate and output the paragraph.
    $_ = $self->interpolate ($_, $line);
    s/\s+$/\n/;
    if (defined $$self{ITEM}) {
        $self->item ($_ . "\n");
    } else {
        $self->output ($self->reformat ($_ . "\n"));
    }
}

# Called for an interior sequence.  Gets the command, argument, and a
# Pod::InteriorSequence object and is expected to return the resulting text.
# Calls code, bold, italic, file, and link to handle those types of
# sequences, and handles S<>, E<>, X<>, and Z<> directly.
sub interior_sequence {
    my $self = shift;
    my $command = shift;
    local $_ = shift;
    return '' if ($command eq 'X' || $command eq 'Z');

    # Expand escapes into the actual character now, carping if invalid.
    if ($command eq 'E') {
        return $ESCAPES{$_} if defined $ESCAPES{$_};
        carp "Unknown escape: E<$_>";
        return "E<$_>";
    }

    # For all the other sequences, empty content produces no output.
    return unless $_;

    # For S<>, compress all internal whitespace and then map spaces to \01.
    # When we output the text, we'll map this back.
    if ($command eq 'S') {
        s/\s{2,}/ /g;
        tr/ /\01/;
        return $_;
    }

    # Anything else needs to get dispatched to another method.
    if    ($command eq 'B') { return $self->seq_b ($_) }
    elsif ($command eq 'C') { return $self->seq_c ($_) }
    elsif ($command eq 'F') { return $self->seq_f ($_) }
    elsif ($command eq 'I') { return $self->seq_i ($_) }
    elsif ($command eq 'L') { return $self->seq_l ($_) }
    else { carp "Unknown sequence $command<$_>" }
}

# Called for each paragraph that's actually part of the POD.  We take
# advantage of this opportunity to untabify the input.
sub preprocess_paragraph {
    my $self = shift;
    local $_ = shift;
    1 while s/^(.*?)(\t+)/$1 . ' ' x (length ($2) * 8 - length ($1) % 8)/me;
    $_;
}


############################################################################
# Command paragraphs
############################################################################

# All command paragraphs take the paragraph and the line number.

# First level heading.
sub cmd_head1 {
    my $self = shift;
    local $_ = shift;
    s/\s+$//;
    if ($$self{alt}) {
        $self->output ("\n==== $_ ====\n\n");
    } else {
        $_ .= "\n" if $$self{loose};
        $self->output ($_ . "\n");
    }
}

# Second level heading.
sub cmd_head2 {
    my $self = shift;
    local $_ = shift;
    s/\s+$//;
    if ($$self{alt}) {
        $self->output ("\n==   $_   ==\n\n");
    } else {
        $self->output (' ' x ($$self{indent} / 2) . $_ . "\n\n");
    }
}

# Start a list.
sub cmd_over {
    my $self = shift;
    local $_ = shift;
    unless (/^[-+]?\d+\s+$/) { $_ = $$self{indent} }
    push (@{ $$self{INDENTS} }, $$self{MARGIN});
    $$self{MARGIN} += ($_ + 0);
}

# End a list.
sub cmd_back {
    my $self = shift;
    $$self{MARGIN} = pop @{ $$self{INDENTS} };
    unless (defined $$self{MARGIN}) {
        carp "Unmatched =back";
        $$self{MARGIN} = $$self{indent};
    }
}

# An individual list item.
sub cmd_item {
    my $self = shift;
    if (defined $$self{ITEM}) { $self->item }
    local $_ = shift;
    s/\s+$//;
    $$self{ITEM} = $self->interpolate ($_);
}

# Begin a block for a particular translator.  To allow for weird nested
# =begin blocks, keep track of how many blocks we were excluded from and
# only unwind one level with each =end.
sub cmd_begin {
    my $self = shift;
    local $_ = shift;
    my ($kind) = /^(\S+)/ or return;
    push (@{ $$self{BEGUN} }, $kind);
    $$self{EXCLUDE}++ unless $kind eq 'text';
}

# End a block for a particular translator.  We assume that all =begin/=end
# pairs are properly nested and just pop the previous one.
sub cmd_end {
    my $self = shift;
    my $kind = pop @{ $$self{BEGUN} };
    $$self{EXCLUDE}-- if $$self{EXCLUDE};
}    

# One paragraph for a particular translator.  Ignore it unless it's intended
# for text, in which case we treat it as either a normal text block or a
# verbatim text block, depending on whether it's indented.
sub cmd_for {
    my $self = shift;
    local $_ = shift;
    my $line = shift;
    return unless s/^text\b[ \t]*//;
    if (/^\n\s+/) {
        $self->verbatim ($_, $line);
    } else {
        $self->textblock ($_, $line);
    }
}


############################################################################
# Interior sequences
############################################################################

# The simple formatting ones.  These are here mostly so that subclasses can
# override them and do more complicated things.
sub seq_b { my $self = shift; return $$self{alt} ? "``$_[0]''" : $_[0] }
sub seq_c { my $self = shift; return $$self{alt} ? "``$_[0]''" : "`$_[0]'" }
sub seq_f { my $self = shift; return $$self{alt} ? "\"$_[0]\"" : $_[0] }
sub seq_i { return '*' . $_[1] . '*' }

# The complicated one.  Handle links.  Since this is plain text, we can't
# actually make any real links, so this is all to figure out what text we
# print out.
sub seq_l {
    my $self = shift;
    local $_ = shift;

    # Smash whitespace in case we were split across multiple lines.
    s/\s+/ /g;

    # If we were given any explicit text, just output it.
    if (/^([^|]+)\|/) { return $1 }

    # Okay, leading and trailing whitespace isn't important; get rid of it.
    s/^\s+//;
    s/\s+$//;
    chomp;

    # Default to using the whole content of the link entry as a section
    # name.  Note that L<manpage/> forces a manpage interpretation, as does
    # something looking like L<manpage(section)>.  The latter is an
    # enhancement over the original Pod::Text.
    my ($manpage, $section) = ('', $_);
    if (/^"\s*(.*?)\s*"$/) {
        $section = '"' . $1 . '"';
    } elsif (m/^[-:.\w]+(?:\(\S+\))?$/) {
        ($manpage, $section) = ($_, '');
    } elsif (m%/%) {
        ($manpage, $section) = split (/\s*\/\s*/, $_, 2);
    }

    # Now build the actual output text.
    my $text = '';
    if (!length $section) {
        $text = "the $manpage manpage" if length $manpage;
    } elsif ($section =~ /^[:\w]+(?:\(\))?/) {
        $text .= 'the ' . $section . ' entry';
        $text .= (length $manpage) ? " in the $manpage manpage"
                                   : " elsewhere in this document";
    } else {
        $section =~ s/^\"\s*//;
        $section =~ s/\s*\"$//;
        $text .= 'the section on "' . $section . '"';
        $text .= " in the $manpage manpage" if length $manpage;
    }
    $text;
}


############################################################################
# List handling
############################################################################

# This method is called whenever an =item command is complete (in other
# words, we've seen its associated paragraph or know for certain that it
# doesn't have one).  It gets the paragraph associated with the item as an
# argument.  If that argument is empty, just output the item tag; if it
# contains a newline, output the item tag followed by the newline.
# Otherwise, see if there's enough room for us to output the item tag in the
# margin of the text or if we have to put it on a separate line.
sub item {
    my $self = shift;
    local $_ = shift;
    my $tag = $$self{ITEM};
    unless (defined $tag) {
        carp "item called without tag";
        return;
    }
    undef $$self{ITEM};
    my $indent = $$self{INDENTS}[-1];
    unless (defined $indent) { $indent = $$self{indent} }
    my $space = ' ' x $indent;
    $space =~ s/^ /:/ if $$self{alt};
    if (!$_ || /^\s+$/ || ($$self{MARGIN} - $indent < length ($tag) + 1)) {
        $self->output ($space . $tag . "\n");
        $self->output ($self->reformat ($_)) if /\S/;
    } else {
        $_ = $self->reformat ($_);
        s/^ /:/ if ($$self{alt} && $indent > 0);
        my $tagspace = ' ' x length $tag;
        s/^($space)$tagspace/$1$tag/ or warn "Bizarre space in item";
        $self->output ($_);
    }
}


############################################################################
# Output formatting
############################################################################

# Wrap a line, indenting by the current left margin.  We can't use
# Text::Wrap because it plays games with tabs.  We can't use formline, even
# though we'd really like to, because it screws up non-printing characters.
# So we have to do the wrapping ourselves.
sub wrap {
    my $self = shift;
    local $_ = shift;
    my $output = '';
    my $spaces = ' ' x $$self{MARGIN};
    my $width = $$self{width} - $$self{MARGIN};
    while (length > $width) {
        if (s/^([^\n]{0,$width})\s+// || s/^([^\n]{$width})//) {
            $output .= $spaces . $1 . "\n";
        } else {
            last;
        }
    }
    $output .= $spaces . $_;
    $output =~ s/\s+$/\n\n/;
    $output;
}

# Reformat a paragraph of text for the current margin.  Takes the text to
# reformat and returns the formatted text.
sub reformat {
    my $self = shift;
    local $_ = shift;

    # If we're trying to preserve two spaces after sentences, do some
    # munging to support that.  Otherwise, smash all repeated whitespace.
    if ($$self{sentence}) {
        s/ +$//mg;
        s/\.\n/. \n/g;
        s/\n/ /g;
        s/   +/  /g;
    } else {
        s/\s+/ /g;
    }
    $self->wrap ($_);
}

# Output text to the output device.
sub output { $_[1] =~ tr/\01/ /; print { $_[0]->output_handle } $_[1] }


############################################################################
# Module return value and documentation
############################################################################

1;
__END__

=head1 NAME

Pod::Text - Convert POD data to formatted ASCII text

=head1 SYNOPSIS

    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file ('file.pod', 'file.txt');

=head1 DESCRIPTION

Pod::Text is a module that can convert documentation in the POD format
(such as can be found throughout the Perl distribution) into formatted
ASCII.  It uses no special formatting controls or codes whatsoever, and its
output is therefore suitable for nearly any device.

As a derived class from Pod::Parser, Pod::Text supports the same
methods and interfaces.  See L<Pod::Parser> for all the details; briefly,
one creates a new parser with C<Pod::Text-E<gt>new()> and then calls
either C<parse_from_filehandle()> or C<parse_from_file()>.

C<new()> can take options, in the form of key/value pairs, that control the
behavior of the parser.  The currently recognized options are:

=over 4

=item alt

If set to a true value, selects an alternate output format that, among other
things, uses a different heading style and marks C<=item> entries with a
colon in the left margin.  Defaults to false.

=item indent

The number of spaces to indent regular text, and the default indentation for
C<=over> blocks.  Defaults to 4.

=item loose

If set to a true value, a blank line is printed after a C<=head1> heading.
If set to false (the default), no blank line is printed after C<=head1>,
although one is still printed after C<=head2>.  This is the default because
it's the expected formatting for manual pages; if you're formatting
arbitrary text documents, setting this to true may result in more pleasing
output.

=item sentence

If set to a true value, Pod::Text will assume that each sentence ends
in two spaces, and will try to preserve that spacing.  If set to false, all
consecutive whitespace in non-verbatim paragraphs is compressed into a
single space.  Defaults to true.

=item width

The column at which to wrap text on the right-hand side.  Defaults to 76.

=back

The standard Pod::Parser method C<parse_from_filehandle()> takes up to two
arguments, the first being the file handle to read POD from and the second
being the file handle to write the formatted output to.  The first defaults
to STDIN if not given, and the second defaults to STDOUT.  The method
C<parse_from_file()> is almost identical, except that its two arguments are
the input and output disk files instead.  See L<Pod::Parser> for the
specific details.

=head1 DIAGNOSTICS

=over 4

=item Unknown escape: %s

The POD source contained an C<EE<lt>E<gt>> escape that Pod::Text
didn't know about.

=item Unknown sequence: %s

The POD source contained a non-standard internal sequence (something of the
form C<XE<lt>E<gt>>) that Pod::Text didn't know about.

=item Unmatched =back

Pod::Text encountered a C<=back> command that didn't correspond to an
C<=over> command.

=back

=head1 NOTES

I'm hoping this module will eventually replace Pod::Text in Perl core once
Pod::Parser has been added to Perl core.  Accordingly, don't be surprised if
the name of this module changes to Pod::Text down the road.

The original Pod::Text contained code to do formatting via termcap
sequences, although it wasn't turned on by default and it was problematic to
get it to work at all.  This module doesn't even try to do that, but a
subclass of it does.  Look for Pod::Text::Termcap.

=head1 SEE ALSO

L<Pod::Parser|Pod::Parser>, L<Pod::Text::Termcap|Pod::Text::Termcap>

=head1 AUTHOR

Russ Allbery E<lt>rra@stanford.eduE<gt>, based I<very> heavily on the
original Pod::Text by Tom Christiansen E<lt>tchrist@mox.perl.comE<gt> and
its conversion to Pod::Parser by Brad Appleton
E<lt>bradapp@enteract.comE<gt>.

=cut
