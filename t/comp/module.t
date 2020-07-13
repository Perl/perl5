#!./perl

print "1..4\n";

module X {
    sub t { print "ok 1\n"; }
}

X::t();

# module applies `use strict`
if( !eval 'module Fail; $x = 0; 1' ) {
    my $e = "$@";
    print "ok 2 - module applies use strict\n";

    print "not " unless $e =~ m/^Global symbol "\$x" requires explicit package name /;
    print "ok 3 - failure from module applies use strict\n";
}
else {
    print "not ok 2 - module applies use strict\n";
    print "ok 3 # skip\n";
}

# module applies `use warnings`
{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };

    eval 'module Warn; my $str = undef; $str . "more"';

    print "not " unless $warnings =~ m/^Use of uninitialized value \$str in concatenation \(\.\) or string at /;
    print "ok 4 - module applies use warnings\n";
}
