#!/usr/bin/perl -w

# This script cleans up an HTML document

use strict;
use HTML::Parser ();

# configure these values
my @ignore_attr =
    qw(bgcolor background color face style link alink vlink text
       onblur onchange onclick ondblclick onfocus onkeydown onkeyup onload
       onmousedown onmousemove onmouseout onmouseover onmouseup
       onreset onselect onunload
      );
my @ignore_tags = qw(font big small b i);
my @ignore_elements = qw(script style);

# make it easier to look up attributes
my %ignore_attr = map { $_ => 1} @ignore_attr;

sub tag
{
    my($pos, $text) = @_;
    if (@$pos >= 4) {
	# kill some attributes
	my($k_offset, $k_len, $v_offset, $v_len) = @{$pos}[-4 .. -1];
	my $next_attr = $v_offset ? $v_offset + $v_len : $k_offset + $k_len;
	my $edited;
	while (@$pos >= 4) {
	    ($k_offset, $k_len, $v_offset, $v_len) = splice @$pos, -4;
	    if ($ignore_attr{lc substr($text, $k_offset, $k_len)}) {
		substr($text, $k_offset, $next_attr - $k_offset) = "";
		$edited++;
	    }
	    $next_attr = $k_offset;
	}
	# if we killed all attributed, kill any extra whitespace too
	$text =~ s/^(<\w+)\s+>$/$1>/ if $edited;
    }
    print $text;
}

sub decl
{
    my $type = shift;
    print shift if $type eq "doctype";
}

sub text
{
    print shift;
}

HTML::Parser->new(api_version   => 3,
		  start_h       => [\&tag,   "tokenpos, text"],
                  process_h     => ["", ""],
		  comment_h     => ["", ""],
                  declaration_h => [\&decl,   "tagname, text"],
                  default_h     => [\&text,   "text"],

		  ignore_tags   => \@ignore_tags,
		  ignore_elements => \@ignore_elements,
                 )
    ->parse_file(shift) || die "Can't open file: $!\n";

