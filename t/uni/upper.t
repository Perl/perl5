BEGIN {
    chdir 't' if -d 't';
    require "uni/case.pl";
}

use feature 'unicode_strings';

is(uc("\x{3B1}\x{345}\x{301}"), "\x{391}\x{301}\x{399}",
                                                   'Verify moves YPOGEGRAMMENI');

casetest( 1,	# extra tests already run
	"Uppercase_Mapping",
	 uc                        => sub { uc $_[0] },
	 uc_with_appended_null_arg => sub { my $a = ""; uc ($_[0] . $a) }
        );
