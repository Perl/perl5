# HARNESS-NO-PRELOAD
#
BEGIN {
    if (eval { require Test2::Tools::Tiny }) {
        print "# Using Test2::Tools::Tiny\n";
        Test2::Tools::Tiny->import();
    }
    else {
        print "1..0 # SKIP Test2::Tools::Tiny is not installed\n";
        exit(0);
    }

    if (grep { -t $_ } *STDOUT, *STDERR, *STDIN) {
        print "# Found usable IO\n";
    }
    else {
        print "1..0 # SKIP No usable IO handles\n";
        exit(0);
    }

    if (eval { require Term::ReadKey; Term::ReadKey->can('GetTerminalSize') }) {
        print "# Using Term::ReadKey\n";
    }
    else {
        print "1..0 # SKIP Term::ReadKey is not installed, or too old\n";
        exit(0);
    }

    if (eval { require Devel::Hide }) {
        Devel::Hide->import('Term::Size::Any');
    }
    else {
        print "1..0 # SKIP Devel::Hide is not installed\n";
        exit(0);
    }
}

use Term::Table::Util qw/USE_TERM_READKEY USE_TERM_SIZE_ANY term_size/;

ok(USE_TERM_READKEY, "Using Term::ReadKey");
ok(!USE_TERM_SIZE_ANY, "Not using Term::Size::Any");

ok(term_size(), "Got terminal size");

done_testing;
