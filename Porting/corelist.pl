#!perl
# Generates info for Module::CoreList from this perl tree
# run this from the root of a clean perl tree

use 5.9.0;
use strict;
use warnings;
use File::Find;
use ExtUtils::MM_Unix;

my @lines;
find(sub {
    /(\.pm|_pm\.PL)$/ or return;
    /PPPort_pm\.PL/ and return;
    my $module = $File::Find::name;
    $module =~ /\b(demo|t)\b/ and return; # demo or test modules
    my $version = MM->parse_version($_) // 'undef';
    $version =~ /\d/ and $version = "'$version'";
    # some heuristics to figure out the module name from the file name
    $module =~ s{^(lib|ext)/}{}
	and $1 eq 'ext'
	and ( $module =~ s{^(.*)/lib/\1\b}{$1},
	      $module =~ s{(\w+)/\1\b}{$1},
	      $module =~ s{^Encode/encoding}{encoding},
	      $module =~ s{^MIME/Base64/QuotedPrint}{MIME/QuotedPrint},
	      $module =~ s{^List/Util/lib/Scalar}{Scalar},
	      $module =~ s{^(?:DynaLoader|Errno)/}{},
	    );
    $module =~ s{/}{::}g;
    $module =~ s/(\.pm|_pm\.PL)$//;
    push @lines, sprintf "\t%-24s=> $version,\n", "'$module'";
}, 'lib', 'ext');
print "    $] => {\n";
print sort @lines;
print "    },\n";
