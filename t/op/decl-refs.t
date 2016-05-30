BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc('../lib');
}

plan 108;

for my $decl (qw< my CORE::state our local >) {
    for my $funny (qw< $ @ % >) {
        # Test three syntaxes with each declarator/funny char combination:
        #     my \$foo    my(\$foo)    my\($foo)

        for my $code("$decl \\${funny}x", "$decl\(\\${funny}x\)",
                     "$decl\\\(${funny}x\)") {
            eval $code;
            like
                $@,
                qr/^The experimental declared_refs feature is not enabled/,
               "$code error when feature is disabled";

            use feature 'declared_refs';

            my($w,$c);
            local $SIG{__WARN__} = sub { $c++; $w = shift };
            eval $code;
            is $c, 1, "one warning from $code";
            like $w, qr/^Declaring references is experimental at /,
                "experimental warning for $code";
        }
    }
}

use feature 'declared_refs', 'state';
no warnings 'experimental::declared_refs';

# The rest of the tests go here....
