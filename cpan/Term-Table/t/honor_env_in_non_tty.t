# HARNESS-NO-PRELOAD
use strict;
use warnings;

BEGIN {
    if (eval { require Test2::Tools::Tiny; Test2::Tools::Tiny->VERSION(1.302097); 1 }) {
        if (!$ENV{PERL_CORE}) {
            print STDERR "# Using Test2::Tools::Tiny " . Test2::Tools::Tiny->VERSION . "\n";
        }
        else {
            print "# Using Test2::Tools::Tiny\n";
        }
        Test2::Tools::Tiny->import;
    }
    elsif (eval { require Test::More; Test::More->can('done_testing') ? 1 : 0 }) {
        print STDERR "# Using Test::More " . Test::More->VERSION . "\n";
        Test::More->import();
    }
    else {
        print "1..0 # SKIP Neither Test2::Tools::Tiny nor a sufficient Test::More is installed\n";
        exit(0);
    }

    if (eval { require Devel::Hide }) {
        Devel::Hide->import('Term::Size::Any');
        Devel::Hide->import('Term::ReadKey');
    }
    else {
        print "1..0 # SKIP Devel::Hide is not installed\n";
        exit(0);
    }
}

use Term::Table::Util qw/term_size USE_TERM_READKEY USE_TERM_SIZE_ANY/;

ok(!USE_TERM_READKEY, "Not using Term::ReadKey");
ok(!USE_TERM_SIZE_ANY, "Not using Term::Size::Any");

{
    local $ENV{TABLE_TERM_SIZE} = 1234;
    is(term_size, 1234, "Used the size in the env var");
}

{
    local $ENV{COLUMNS} = 124;
    is(term_size, 124, "Used the size in the env var");
}


done_testing;
