# Convert POD data to formatted color ASCII text
#
# This is just a basic proof of concept.  It should later be modified to make
# better use of color, take options changing what colors are used for what
# text, and the like.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

##############################################################################
# Modules and declarations
##############################################################################

package Pod::Text::Color v6.1.0;

use 5.012;
use parent qw(Pod::Text);
use warnings;

use Term::ANSIColor qw(color colored colorstrip);

##############################################################################
# Overrides
##############################################################################

# Make level one headings bold.
sub cmd_head1 {
    my ($self, $attrs, $text) = @_;
    $text =~ s{ \s+ \z }{}xms;
    local $Term::ANSIColor::EACHLINE = "\n";
    $self->SUPER::cmd_head1($attrs, colored($text, 'bold'));
    return;
}

# Make level two headings bold.
sub cmd_head2 {
    my ($self, $attrs, $text) = @_;
    $text =~ s{ \s+ \z }{}xms;
    $self->SUPER::cmd_head2($attrs, colored($text, 'bold'));
    return;
}

# Fix the various formatting codes.
sub cmd_b { my (undef, undef, $text) = @_; return colored($text, 'bold') }
sub cmd_f { my (undef, undef, $text) = @_; return colored($text, 'cyan') }
sub cmd_i { my (undef, undef, $text) = @_; return colored($text, 'yellow') }

# Analyze a single line and return any formatting codes in effect at the end
# of that line.
sub end_format {
    my ($self, $line) = @_;
    my $reset = color('reset');
    my $current;
    while ($line =~ m{ ( \e\[ [\d;]+ m ) }xmsg) {
        my $code = $1;
        if ($code eq $reset) {
            undef $current;
        } else {
            $current .= $code;
        }
    }
    return $current;
}

# Output any included code in green.
sub output_code {
    my ($self, $code) = @_;
    local $Term::ANSIColor::EACHLINE = "\n";
    $code = colored($code, 'green');
    $self->output($code);
    return;
}

# Strip all of the formatting from a provided string, returning the stripped
# version.
sub strip_format {
    my ($self, $text) = @_;
    return colorstrip($text);
}

# We unfortunately have to override the wrapping code here, since the normal
# wrapping code gets really confused by all the escape sequences.
sub wrap {
    my ($self, $text) = @_;
    my $output = q{};
    my $spaces = q{ } x $self->{MARGIN};
    my $width = $self->{opt_width} - $self->{MARGIN};

    # Matches a single escape sequence.
    my $code = qr{ (?: \e\[ [\d;]+ m ) }xms;

    # Matches any number of escape sequences preceding a single character
    # other than a newline.  Prevent backtracking to optimize the final
    # regular expression matching since $code is complex.
    my $char = qr{ (?> $code* [^\n] ) }xms;

    # Matches some sequence of $char up to $width characters, ending in codes
    # followed by whitespace or the end of the string.  This detects a valid
    # break point.  The extracted text is placed in $1.
    my $shortchar = qr{
        \A
        ( ${char}{0,$width} (?> $code* ) )
        (?: [ \t\n]+ | \z )
    }xms;

    # Matches exactly $width $chars, used when we have to hard wrap in the
    # middle of an unbroken string.  The extracted text is placed in $1.
    my $longchar = qr{ \A ( ${char}{$width} ) }xms;

    # Extract one line at a time from $text and wrap it.
    while (length($text) > $width) {
        if ($text =~ s{$shortchar}{}xms || $text =~ s{$longchar}{}xms) {
            $output .= $spaces . $1 . "\n";
        } else {
            last;
        }
    }
    $output .= $spaces . $text;

    # less -R always resets terminal attributes at the end of each line, so we
    # need to clear attributes at the end of lines and then set them again at
    # the start of the next line.  This requires a second pass through the
    # wrapped string, accumulating any attributes we see, remembering them,
    # and then inserting the appropriate sequences at the newline.
    if ($output =~ m{\n}xms) {
        my @lines = split(m{\n}xms, $output);
        my $start_format;
        for my $line (@lines) {
            if ($start_format && $line =~ m{\S}xms) {
                $line =~ s{ \A (\s*) (\S) }{$1$start_format$2}xms;
            }
            $start_format = $self->end_format($line);
            if ($start_format) {
                $line .= color('reset');
            }
        }
        $output = join("\n", @lines);
    }

    # Fix up trailing whitespace and return the results.
    $output =~ s{ \s+ \z }{\n\n}xms;
    return $output;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery

=head1 NAME

Pod::Text::Color - Convert POD data to formatted color ASCII text

=head1 SYNOPSIS

    use Pod::Text::Color;
    my $parser = Pod::Text::Color->new (sentence => 0, width => 78);

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file ('file.pod', 'file.txt');

=head1 DESCRIPTION

Pod::Text::Color is a simple subclass of Pod::Text that highlights output
text using ANSI color escape sequences.  Apart from the color, it in all
ways functions like Pod::Text.  See L<Pod::Text> for details and available
options.

Term::ANSIColor is used to get colors and therefore must be installed to use
this module.

=head1 COMPATIBILITY

Pod::Text::Color 0.05 (based on L<Pod::Parser>) was the first version of this
module included with Perl, in Perl 5.6.0.

The current API based on L<Pod::Simple> was added in Pod::Text::Color 2.00.
Pod::Text::Color 2.01 was included in Perl 5.9.3, the first version of Perl to
incorporate those changes.

Several problems with wrapping and line length were fixed as recently as
Pod::Text::Color 6.0.0.

This module inherits its API and most behavior from Pod::Text, so the details
in L<Pod::Text/COMPATIBILITY> also apply.  Pod::Text and Pod::Text::Color have
had the same module version since 4.00, included in Perl 5.23.7.  (They
unfortunately diverge in confusing ways prior to that.)

=head1 CAVEATS

Line wrapping is done only at ASCII spaces and tabs, rather than using a
correct Unicode-aware line wrapping algorithm.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright 1999, 2001, 2004, 2006, 2008, 2009, 2018-2019, 2022, 2024 Russ
Allbery <rra@cpan.org>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Pod::Text>, L<Pod::Simple>

The current version of this module is always available from its web site at
L<https://www.eyrie.org/~eagle/software/podlators/>.  It is also part of the
Perl core distribution as of 5.6.0.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
