;# $Header: importenv.pl,v 2.0 88/06/05 00:16:17 root Exp $

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
