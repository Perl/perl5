# HARNESS-NO-PRELOAD
BEGIN {
    if (eval { require Test2::Tools::Tiny }) {
        print "# Using Test2::Tools::Tiny\n";
        Test2::Tools::Tiny->import();
    }
    else {
        print "1..0 # SKIP Test2::Tools::Tiny is not installed\n";
        exit(0);
    }

    if (eval { require Term::Size::Any }) {
        print "# Using Term::Size::Any\n";
    }
    else {
        print "1..0 # SKIP Term::Size::Any is not installed, or too old\n";
        exit(0);
    }

    if (eval { require Devel::Hide }) {
        Devel::Hide->import('Term::ReadKey');
    }
    else {
        print "1..0 # SKIP Devel::Hide is not installed\n";
        exit(0);
    }
}

use Term::Table::Util qw/USE_TERM_READKEY USE_TERM_SIZE_ANY term_size/;

ok(USE_TERM_SIZE_ANY, "Using Term::Size::Any");
ok(!USE_TERM_READKEY, "Not using Term::ReadKey");

ok(term_size(), "Got terminal size");

done_testing;
