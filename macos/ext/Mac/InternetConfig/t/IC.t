Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# IC.t - Demonstrate Internet Config
#

use Mac::InternetConfig;

print <<END;
Hello, $InternetConfig{kICRealName()}

I think your e-mail address is $InternetConfig{kICEmail()}
END
