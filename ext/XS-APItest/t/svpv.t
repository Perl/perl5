#!perl -w

use Test::More tests => 16;

use XS::APItest;

for my $func ('SvPVbyte', 'SvPVutf8') {
 $g = *glob;
 $r = \1;
 is &$func($g), '*main::glob', "$func(\$glob_copy)";
 is ref\$g, 'GLOB', "$func(\$glob_copy) does not flatten the glob";
 is &$func($r), "$r", "$func(\$ref)";
 is ref\$r, 'REF', "$func(\$ref) does not flatten the ref";

 is &$func(*glob), '*main::glob', "$func(*glob)";
 is ref\$::{glob}, 'GLOB', "$func(*glob) does not flatten the glob";
 is &$func($^V), "$^V", "$func(\$ro_ref)";
 is ref\$^V, 'REF', "$func(\$ro_ref) does not flatten the ref";
}
