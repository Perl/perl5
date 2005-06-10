
use strict ;
local ($^W) = 1; #use warnings ;

use Compress::Zlib ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
    return $ok;
}

print "1..1\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
my $zlib_h = ZLIB_VERSION ;
my $libz   = Compress::Zlib::zlib_version;
ok(1, $zlib_h eq $libz) ||
print <<EOM;
# The version of zlib.h does not match the version of libz
# 
# You have zlib.h version $zlib_h
#      and libz   version $libz
# 
# You probably have two versions of zlib installed on your system.
# Try removing the one you don't want to use and rebuild.
EOM

