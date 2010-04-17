warn "Legacy library @{[(caller(0))[6]]} will be removed from the Perl core distribution in the next major release. Please install it from the CPAN distribution Perl4::CoreLibs. It is being used at @{[(caller)[1]]}, line @{[(caller)[2]]}.\n";

;# This legacy library is deprecated and will be removed in a future
;# release of perl.
;#
;# shellwords.pl
;#
;# Usage:
;#	require 'shellwords.pl';
;#	@words = shellwords($line);
;#	or
;#	@words = shellwords(@lines);
;#	or
;#	@words = shellwords();		# defaults to $_ (and clobbers it)

require Text::ParseWords;
*shellwords = \&Text::ParseWords::old_shellwords;

1;
