#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

my $module = shift;

# 'require open' confuses Perl, so we use instead.
eval "use $module ();";
if( $@ ) {
    print "not ";
    warn "require failed with '$@'\n";
}
print "ok - $module\n";


