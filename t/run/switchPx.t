#!./perl

# Ensure that the -P and -x flags work together.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';

    use Config;
    if ( $^O eq 'MSWin32' or $^O eq 'MacOS' or
	 ($Config{'cppstdin'} =~ /\bcppstdin\b/) and
	 ( ! -x $Config{'binexp'} . "/cppstdin") ) {
	print "1..0 # Skip: \$Config{cppstdin} unavailable\n";
        exit; 		# Cannot test till after install, alas.
    }
}

require './test.pl';

print runperl( switches => ['-Px'], 
               nolib => 1,   # for some reason this is necessary under VMS
               progfile => 'run/switchPx.aux' );
