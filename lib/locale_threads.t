use strict;
use warnings;

# This file tests interactions with locale and threads

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require './loc_tools.pl';
    skip_all("No locales") unless locales_enabled();
    skip_all_without_config('useithreads');
    $| = 1;
}

SKIP: { # perl #127708
    my @locales = grep { $_ !~ / ^ C \b | POSIX /x } find_locales('LC_MESSAGES',
                                                        'non-problematic-only');
    skip("No valid locale to test with", 1) unless @locales;

    # reset the locale environment
    local @ENV{'LANG', (grep /^LC_/, keys %ENV)};
    local $ENV{LC_MESSAGES} = $locales[0];

    # We're going to try with all possible error numbers on this platform
    my $error_count = keys(%!) + 1;

    print fresh_perl("
        use threads;
        use strict;
        use warnings;

        my \$errnum = 1;

        my \@threads = map +threads->create(sub {
            sleep 0.1;

            for (1..5_000) {
                \$errnum = (\$errnum + 1) % $error_count;
                \$! = \$errnum;

                # no-op to trigger stringification
                next if \"\$!\" eq \"\";
            }
        }), (0..1);
        \$_->join for splice \@threads;",
    {}
    );

    pass("Didn't segfault");
}

done_testing;
