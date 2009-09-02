# This library is no longer being maintained, and is included for backward
# compatibility with Perl 4 programs which may require it.
# This legacy library is deprecated and will be removed in a future
# release of perl.

warn( "The 'importenv.pl' legacy library is deprecated and will be"
      . " removed in the next major release of perl. Please use the"
      . " Env::Export module (or similar) from CPAN instead." );

;# This file, when interpreted, pulls the environment into normal variables.
;# Usage:
;#	require 'importenv.pl';
;# or
;#	#include <importenv.pl>

local($tmp,$key) = '';

foreach $key (keys(%ENV)) {
    $tmp .= "\$$key = \$ENV{'$key'};" if $key =~ /^[A-Za-z]\w*$/;
}
eval $tmp;

1;
