#!./perl

use FileCache;

# FileCache is documented to rely upon symbolic references, so all programs
# that use it must relax strict 'refs'
no strict 'refs';

END { unlink("Foo_Bar") }

use Test::More tests => 1;

{# Test 5: that close is overridden properly within the caller
    cacheout local $_ = "Foo_Bar";
    print $_ "Hello World\n";
    close($_);
    ok(!fileno($_));
}
