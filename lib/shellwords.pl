;# shellwords.pl
;#
;# Usage:
;#	require 'shellwords.pl';
;#	@words = shellwords($line);
;#	or
;#	@words = shellwords(@lines);
;#	or
;#	@words = shellwords();		# defaults to $_ (and clobbers it)

sub shellwords {
    local *_ = \join('', @_) if @_;
    my (@words, $snippet);

    s/\A\s+//;
    while ($_ ne '') {
	my $field = substr($_, 0, 0);	# leave results tainted
	for (;;) {
	    if (s/\A"(([^"\\]|\\.)*)"//s) {
		($snippet = $1) =~ s#\\(.)#$1#sg;
	    }
	    elsif (/\A"/) {
		die "Unmatched double quote: $_\n";
	    }
	    elsif (s/\A'(([^'\\]|\\.)*)'//s) {
		($snippet = $1) =~ s#\\(.)#$1#sg;
	    }
	    elsif (/\A'/) {
		die "Unmatched single quote: $_\n";
	    }
	    elsif (s/\A\\(.)//s) {
		$snippet = $1;
	    }
	    elsif (s/\A([^\s\\'"]+)//) {
		$snippet = $1;
	    }
	    else {
		s/\A\s+//;
		last;
	    }
	    $field .= $snippet;
	}
	push(@words, $field);
    }
    return @words;
}
1;
