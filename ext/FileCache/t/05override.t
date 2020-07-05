#!./perl

use FileCache;

END { unlink("Foo_Bar") }

use Test::More tests => 1;

{# Test 5: that close is overridden properly within the caller
     cacheout local $_ = "Foo_Bar";
     no strict 'refs';
     print $_ "Hello World\n";
     close($_);
     ok(!fileno($_));
}
