;# $Header: importenv.pl,v 3.0 89/10/18 15:19:39 lwall Locked $

;# This file, when interpreted, pulls the environment into normal variables.
;# Usage:
;#	do 'importenv.pl';
;# or
;#	#include <importenv.pl>

local($tmp,$key) = '';

foreach $key (keys(ENV)) {
    $tmp .= "\$$key = \$ENV{'$key'};" if $key =~ /^[A-Za-z]\w*$/;
}
eval $tmp;

1;
